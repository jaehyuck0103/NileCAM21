#include "csi-2.h"
#include "sxpf.h"

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <inttypes.h>
#include <iostream>
#include <libgen.h>
#include <math.h>
#include <setjmp.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <fmt/chrono.h>
#include <fmt/core.h>

#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

#include <filesystem>
namespace fs = std::filesystem;

namespace chrono = std::chrono;
using std::chrono::system_clock;
using std::chrono::time_point;
using namespace std::chrono_literals;

std::string getFormattedTime(const time_point<system_clock> &tp) {

    std::string date = fmt::format("{:%y%m%d_%H%M%S}", tp);

    const auto tse = tp.time_since_epoch();
    const auto ms = chrono::duration_cast<chrono::milliseconds>(tse) -
                    chrono::duration_cast<chrono::seconds>(tse);
    const auto us = chrono::duration_cast<chrono::microseconds>(tse) -
                    chrono::duration_cast<chrono::milliseconds>(tse);

    return fmt::format("{:%y%m%d_%H%M%S}_{:03d}_{:03d}", tp, ms.count(), us.count());
}

/** Input channel state */
typedef struct input_channel_s {
    sxpf_hdl fg = 0;
    HWAITSXPF devfd = 0;
    int endpoint_id = 0;
    int num_pbos = 0; /**< no.\ of available buffers */
    /// no.\ of used pbos: 0: none; 1: front buffer only; 2: front & back buffer
    int used_pbos = 0;
    int front_pbo = 0; // img uploaded to back_pbo = 1 - front_pbo
    int old_frame_slot = 0;
    double fps = 0;
    int frame = 0; // frame counter from FPGA
    uint32_t x_size = 0;
    uint32_t y_size = 0;
    uint32_t frame_info = 0;

} input_channel_t;

typedef struct opts_s {
    int endpoint_id;
    int channel_id = 0;

    /* flag: select RAW CSI-2 decoder datatype */
    int decode_csi2_datatype = -1; // csi2 datatype for raw decoding

    /** number of bits (8, 16) used per color component */
    int bits_per_component = 16; // default=16 for 10/12 bit per channel

    /** number of color components per pixel.
     *  - 1 means RAW
     *  - 2 means YUV422 (YUYV or UYVY)
     */
    int components_per_pixel = 2;

    /** number of bits to shift color components to the left so they become
     *  properly aligned according to OpenGL's needs.
     */
    int left_shift = 6; // for 10 bit per component (10+6=16)

    /** select field from interleavced input: 0=even, 1=odd, 2=all lines */
    uint32_t field_sel = 0; // select LEF field by default

} opts_t;

static opts_t g_opts;

enum Opt {
    // ensure long-options-only parameters have a code unequal to any character
    _ = 256,
    optCard,
    optChannel,
};

static struct option long_options[] = {
    {"card", required_argument, 0, optCard},
    {"channel", required_argument, 0, optChannel},
    {0, 0, 0, 0}};

uint32_t total_err_cnt = 0;

void usage(char *pname);
void options(int argc, char **argv, opts_t *opts);

static int UpdateTexture(input_channel_t *ch, int frame_info);

void init_channel(input_channel_t *ch, int endpoint_id, int channel_id);
void close_channel(input_channel_t *ch);

void release_buffer(sxpf_hdl fg, int slot) {
#if 0 /* activated only for debugging low-level image transmission */
    // clear buffer before the grabber hardware writes new data to it
    sxpf_card_props_t   props;

    if (!sxpf_get_card_properties(fg, &props))
    {
        void   *pbuf = sxpf_get_frame_ptr(fg, slot);

        if (pbuf)
            memset(pbuf, 0, props.buffer_size);
    }
#endif

    sxpf_release_frame(fg, slot, 0);
}

void close_channel(input_channel_t *ch) {
    if (ch->fg) {
        if (ch->old_frame_slot >= 0) {
            release_buffer(ch->fg, ch->old_frame_slot);
        }
        sxpf_close(ch->fg);
    }
}

void init_channel(input_channel_t *ch, int endpoint_id, int channel_id) {
    *ch = input_channel_t{};

    ch->fg = sxpf_open(endpoint_id);
    if (ch->fg) {
        ch->endpoint_id = endpoint_id;
        ch->old_frame_slot = -1;

        if (sxpf_start_record(ch->fg, SXPF_STREAM_VIDEO0 << (channel_id & 0xf))) {
            fprintf(stderr, "failed to start stream\n");
        }

        sxpf_get_device_fd(ch->fg, &ch->devfd);

        // fcntl(ch->devfd, F_SETFL, 0); // reset O_NONBLOCK flag
        fcntl(ch->devfd, F_SETFL, O_NONBLOCK); // set O_NONBLOCK flag
    } else {
        exit(1);
    }
}

int UpdateTexture(input_channel_t *ch, int frame_info) {
    sxpf_image_header_t *img_hdr;
    uint8_t *img_ptr;
    int ret = 1;
    int frame_slot = frame_info / (1 << 24);
    uint32_t *tmp = NULL;
    uint32_t frame_size;
    int isNewFrame = (frame_info & 0x00ffffff) > 0;
    uint32_t x_size, y_size;

    static uint64_t ots = 0;
    uint64_t ts;
    uint64_t ts_end;
    double frame_rate;

    uint32_t sum = 0;
    char msg[1024];
    int msglen = 0;

    // variables for raw csi2 decoding
    static uint32_t align = 0;
    uint16_t *pdst = NULL;
    uint32_t decoded_pix;
    uint8_t *pixels;
    uint32_t bits_per_pixel;
    uint32_t pixel_group_size;
    uint16_t *tmp2 = NULL;

    time_t rawtime;
    char *time_str;

    if (frame_slot != ch->old_frame_slot) {
        if (ch->old_frame_slot >= 0) {
            release_buffer(ch->fg, ch->old_frame_slot);
        }
        ch->old_frame_slot = frame_slot;
        ret = 0; // we have a new frame
    }

    img_hdr = (sxpf_image_header_t *)sxpf_get_frame_ptr(ch->fg, frame_slot);
    if (!img_hdr) {
        return -1;
    }

    x_size = img_hdr->columns;
    y_size = img_hdr->rows;

    frame_size = x_size * y_size * img_hdr->bpp / 8;
    ts = img_hdr->ts_start_hi * 0x100000000ull + img_hdr->ts_start_lo;
    ts_end = img_hdr->ts_end_hi * 0x100000000ull + img_hdr->ts_end_lo;
    frame_rate = 40e6 / (ts - ots);
    ots = ts;

    img_ptr = (uint8_t *)img_hdr + img_hdr->payload_offset;

    sxpf_card_props_t props;
    sxpf_get_card_properties(ch->fg, &props);

    if (img_hdr->frame_size > props.buffer_size) {
        printf(
            "Error: Received frame is larger than buffer (%u > %u).\n"
            "Please increase the kernel module's framesize parameter.\n",
            img_hdr->frame_size,
            props.buffer_size);
        exit(1);
    }

    if (isNewFrame) {
        ++ch->frame;
    }

    if (g_opts.decode_csi2_datatype >= 0) {

        if (isNewFrame) {
            align = (img_hdr->bpp == 64) ? 7 : 3;
        }
        // set size and framesize to undefined values if datatype is not found
        x_size = 0;
        y_size = 0;
        frame_size = 0;

        uint32_t packet_offset = 0;
        for (uint32_t pkt_count = 0; pkt_count < img_hdr->rows; pkt_count++) {
            uint8_t vc_dt;
            uint32_t word_count;
            pixels = csi2_parse_dphy_ph(img_ptr + packet_offset, &vc_dt, &word_count);
            if (!pixels) {
                printf("invalid frame data\n");
                return -1;
            }

            // Advance packet_offset to start of next packet:
            if ((vc_dt & 0x3f) <= 0x0f) {
                // short packet
                // - 8 bytes at the start make up the short packet data, incl. preamble
                packet_offset += (8 + align) & ~align;
            } else {
                // - 8 bytes at the start make up the packet header, incl. preamble
                // - word_count payload data bytes follow
                // - Payload data is followed by a 2-byte checksum.
                // The following packet then starts at the next address that is an
                // integer multiple of 4 (if bpp <= 32) or 8 (if bpp == 64).
                packet_offset += (8 + word_count + 2 + align) & ~align;
            }

            if (vc_dt == g_opts.decode_csi2_datatype) {
                uint8_t dt = vc_dt & 0x3f;

                if (csi2_decode_datatype(dt, &bits_per_pixel, &pixel_group_size)) {
                    printf("unsupported image type\n");
                    return -1;
                }

                if (dt >= 0x18 && dt <= 0x1f) {
                    g_opts.bits_per_component = 0;
                    bits_per_pixel /= 2; // bits_per_pixel value for yuv is not correct here
                }

                if (tmp2 == NULL) {
                    x_size = word_count * 8 / bits_per_pixel;
                    // alloc memory for all rows but only lines with matching datatype will be used
                    tmp2 = (uint16_t *)malloc(sizeof(uint16_t) * x_size * img_hdr->rows);
                    pdst = tmp2;
                }

                decoded_pix = csi2_decode_raw16(
                    pdst,
                    word_count * 8 / bits_per_pixel,
                    pixels,
                    bits_per_pixel);
                pdst += decoded_pix;
                y_size += 1;
            }
        }
        img_ptr = (uint8_t *)tmp2;
        img_hdr->bpp = 16;
        frame_size = x_size * y_size * sizeof(uint16_t);
    }

    if (g_opts.bits_per_component == 8) {
        // packed UYVY: two components in one 16bit
        x_size = x_size * img_hdr->bpp / 8 / g_opts.components_per_pixel;
    } else if (g_opts.bits_per_component == 12 || g_opts.bits_per_component == 16) {
        // truncate only if sdl is used
        x_size = (x_size * img_hdr->bpp / g_opts.bits_per_component) & (~0);
        frame_size = x_size * y_size * sizeof(uint16_t);
    } else if (g_opts.bits_per_component == 10 || g_opts.bits_per_component == 14) {
        x_size = (x_size * img_hdr->bpp / g_opts.bits_per_component) & ~3;
        frame_size = x_size * y_size * sizeof(uint16_t);
    } else {
        x_size /= g_opts.components_per_pixel;
    }

    if (g_opts.left_shift != 0) {
        // pre-process image data
        tmp = (uint32_t *)malloc(frame_size);
        if (tmp) {
            uint32_t *src = (uint32_t *)img_ptr;
            uint32_t mask = 0x0000ffff;

            // remove bits that get "shifted out"
            mask = mask >> g_opts.left_shift;
            mask = mask | (mask << 16); // mask two component values in one go

            for (uint32_t i = 0; i < frame_size / sizeof(uint32_t); i++) {
                sum |= src[i]; // find out which data bits are active

                // shift 2 pixels in one go
                tmp[i] = (src[i] & mask) << g_opts.left_shift;
            }

            img_ptr = (uint8_t *)tmp;

            msglen = sprintf(msg, "sum = 0x%08x", sum);
        }
    }

    if (isNewFrame) {
        if (x_size != ch->x_size || y_size != ch->y_size ||
            (ch->frame_info & 0x00ffffff) != (frame_info & 0x00ffffff) ||
            (ch->frame > 2 && round(frame_rate * 100) != round(ch->fps * 100))) {
            // print on new line so we can track resolution changes
            fprintf(stderr, "\n");
        }

        ch->x_size = x_size;
        ch->y_size = y_size;
        ch->fps = frame_rate;
        ch->frame_info = frame_info;

        rawtime = time(NULL);
        time_str = ctime(&rawtime);
        time_str[strlen(time_str) - 1] = '\0';

        fprintf(
            stderr,
            "\r%s #%u: card=%d ch=%d  vs=%u, %dx%d, %.2ffps, "
            "start=0x%016" PRIx64 ", end=0x%016" PRIx64,
            time_str,
            ch->frame,
            img_hdr->card_id,
            img_hdr->cam_id,
            frame_info & 0x00ffffff,
            x_size,
            y_size,
            frame_rate,
            ts,
            ts_end);
        if (msglen > 0) {
            fprintf(stderr, ", %.*s", msglen, msg);
        }

        fs::path save_dir{"imgs"};
        fs::create_directories(save_dir);
        const fs::path jpg_path =
            save_dir / fmt::format("{}.jpg", getFormattedTime(system_clock::now()));

        cv::Mat aaa{(int)y_size, (int)x_size, CV_16UC2, img_ptr};
        aaa.convertTo(aaa, CV_8UC2, 1.0 / 256.0);
        cv::Mat bgrFrame{(int)y_size, (int)x_size, CV_8UC3};
        cv::cvtColor(aaa, bgrFrame, cv::COLOR_YUV2BGR_UYVY, 0);
        cv::imwrite(jpg_path, bgrFrame);
    }

    if (tmp)
        free(tmp);
    if (tmp2)
        free(tmp2);

    return ret;
}

void usage(char *pname) {
    printf(
        "The sxpfapp sample application allows capturing image frames from "
        "the grabber card.\n"
        "The commandline output shows the received frame size and frame "
        "rate.\n"
        "\n"
        "Usage: %s [options]\n"
        "\n"
        "Options:\n"
        "\t-d dt     CSI-2 datatype/virtual channel to parse RAW CSI-2 data format\n"
        "\t          Bit 7:6 = virtual channel\n"
        "\t          Bit 5:0 = datatype\n"
        "\t          Do not use together with -C parameter\n"
        "\t-h        Show this help screen\n"
        "\t-l num    Shift input pixels left by this amount (default: 6)\n"
        "\t--card    Select card to capture (0...cards-1)\n"
        "\t--channel Select channel to capture (0...7)\n",
        basename(pname));
}

void options(int argc, char **argv, opts_t *opts) {
    int c;
    int v;
    int option_index;

    while (1) {
        option_index = 0;

        c = getopt_long(
            argc,
            argv,
            "a:A:bc:C:d:D:fg:G:hil:n:op:qrR:s:tw:vV8",
            long_options,
            &option_index);

        if (c == -1)
            break;

        switch (c) {
        case optCard:
            if (long_options[option_index].flag != 0)
                break;
            if (optarg)
                g_opts.endpoint_id = atoi(optarg);
            break;

        case optChannel:
            if (long_options[option_index].flag != 0)
                break;
            if (optarg)
                g_opts.channel_id = atoi(optarg);
            break;

        case 'd': // CSI-2 data type selection
            g_opts.decode_csi2_datatype = strtol(optarg, NULL, 16);
            break;

        case 'h':
            usage(argv[0]);
            exit(0);

        case 'l': // left shift value
            v = atoi(optarg);
            if (v >= 0 && v <= 16)
                g_opts.left_shift = v;
            break;

        default:
            fprintf(stderr, "Invalid switch: -%c\n", c);
            usage(argv[0]);
            exit(1);
        }
    }

    if (opts->endpoint_id < 0) {
        if (optind < argc) {
            opts->endpoint_id = atoi(argv[optind]) / 4;
            opts->channel_id = atoi(argv[optind]) % 4;
            optind++;
        } else {
            opts->endpoint_id = 0;
            opts->channel_id = 0;
        }
    }
}

int main(int argc, char **argv) {
    int endpoint_id = 0;
    int channel_id = 0;
    int is_pause = 0;
    input_channel_t ch; // for now: use only one channel
    int ret = 0;

    g_opts.endpoint_id = -1;
    options(argc, argv, &g_opts);
    endpoint_id = g_opts.endpoint_id;
    channel_id = g_opts.channel_id;

    // open endpoint/grabber device 0
    init_channel(&ch, endpoint_id, channel_id);

    while (true) {
        int frame_info = ch.old_frame_slot * (1 << 24);

        // wait for new frame
        if (ch.devfd > 0) {
            sxpf_event_t events[20];
            sxpf_event_t *evt = events;
            ssize_t len;

#if 0
            uint32_t        latest_frame;
            if (!sxpf_get_latest_frame_id(ch->fg, &latest_frame))
            {
                // shorten select timeout, if we are lagging behind in
                // processing, probably after a short pause period (of less
                // than 32 frames)
                if ((int)(latest_frame - ch->frame) > 1 && !is_pause)
                    timeout.tv_usec = 100;
            }
#endif

            len = sxpf_wait_events(1, &ch.devfd, 50 /* ms */);

            if (len > 0) {
                len = sxpf_read_event(ch.fg, events, std::ssize(events));
            }

            int new_frame_info = -1; // nothing received, yet

            while (len > 0) {
                switch (evt->type) {
                case SXPF_EVENT_FRAME_RECEIVED:
                    if (is_pause) {
                        // even if we ignore the received image, we need to
                        // release its resources!
                        release_buffer(ch.fg, evt->data / (1 << 24));
                    } else {
                        if (new_frame_info != -1) {
                            // we have already received a frame in this loop
                            // --> release it back to the hardware, since we
                            //     won't use it
                            sxpf_release_frame(ch.fg, new_frame_info / (1 << 24), 0);

                            fprintf(stderr, "\nImage processing too slow. Dropping frame.\n");
                        }
                        new_frame_info = evt->data;
                    }
                    break;

                case SXPF_EVENT_I2C_MSG_RECEIVED:
                    // ignore i2c messages for now
                    release_buffer(ch.fg, evt->data / (1 << 24));
                    break;

                case SXPF_EVENT_SW_TEST:
                    fprintf(stderr, "\nTest Interrupt received!\n");
                    break;

                case SXPF_EVENT_TRIGGER:
                    // fprintf(stderr, "\nTrigger Interrupt received (timestamp "
                    //         "= 0x%016llx)!\n", evt->extra.timestamp);
                    break;

                case SXPF_EVENT_CAPTURE_ERROR:
                    fprintf(stderr, "\ncapture error: 0x%08x\n", evt->data);
                    break;

                case SXPF_EVENT_IO_STATE:
                    if (evt->data != SXPF_IO_NORMAL) {
                        fprintf(stderr, "\nPCIe error (%d) - aborting\n", evt->data);
                        exit(evt->data & 255);
                    }
                    break;
                }

                len--;
                ++evt;
            }

            if (new_frame_info != -1) {
                frame_info = new_frame_info;
            }

            if (len != 0 && errno != EAGAIN) {
                perror("error reading sxpf");
                break;
            }
        }

        if (!is_pause) {
            UpdateTexture(&ch, frame_info);
        }
    }

    sxpf_stop(ch.fg, SXPF_STREAM_ALL);

    fprintf(stderr, "\nTotal frames with bit errors: %d\n", total_err_cnt);

    close_channel(&ch);

    return ret;
}
