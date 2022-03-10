import subprocess
from functools import reduce
from pathlib import Path
from time import sleep

from controls import controls

MCU_ADDR = 0x84  # 0x84 0x86 0x88


def to_str_list(*args) -> list[str]:
    args = list(args)
    args = [list(x) if isinstance(x, (list, bytes)) else [x] for x in args]
    args = reduce(lambda x, y: x + y, args)
    return [str(x) for x in args]


def run_command(*args, sleep_after=0.1):
    subprocess.run(to_str_list(*args), check=False)
    # print([hex(int(x)) for x in to_str_list(*args)[2:]])
    sleep(sleep_after)


def get_checksum(payload: list[int]):
    if len(payload):
        return reduce(lambda x, y: x ^ y, payload)
    else:
        return []


def show_sxpfinfo():
    subprocess.run([sxpfinfo], check=False)


def send_status_command(ch: int):
    header = [sxpfi2c, "-f0", 0, ch, MCU_ADDR]

    run_command(header, 0, 0x43, 0x05, 0x00, 0x01, 0x01)
    run_command(header, 0, 0x43, 0x05, 0xFF)
    run_command(header, 7)


def send_configure_command(ch: int, command_id: int, payload: list[int]):
    assert command_id in (0x04, 0x06, 0x07, 0x08, 0x09, 0x11), command_id
    header = [sxpfi2c, "-f0", 0, ch, MCU_ADDR]
    payload_len = len(payload).to_bytes(length=2, byteorder="big")

    run_command(header, 0, 0x43, command_id, payload_len, get_checksum(payload_len))
    run_command(header, 0, 0x43, command_id, payload, get_checksum(payload))
    sleep(5)
    send_status_command(ch)


def init_camera(ch: int):
    send_configure_command(ch, 0x04, [])


def deinit_camera(ch: int):
    send_configure_command(ch, 0x06, [])


def stream_on(ch: int):
    send_configure_command(ch, 0x07, [])


def stream_off(ch: int):
    send_configure_command(ch, 0x08, [])


def set_control_value(ch: int, control_name: str, val: int):
    send_configure_command(ch, 0x11, controls[control_name].get_payload(val))


def get_firmware_ver(ch: int):

    header = [sxpfi2c, "-f0", 0, ch, MCU_ADDR]

    run_command(header, 0, 0x43, 0x00, 0x00, 0x00, 0x00)
    run_command(header, 0, 0x43, 0x00)
    run_command(header, 6)
    run_command(header, 36)


def get_control_value(ch: int, control_name: str):

    header = [sxpfi2c, "-f0", 0, ch, MCU_ADDR]
    payload = controls[control_name].control_index
    checksum = get_checksum(payload)

    run_command(header, 0, 0x43, 0x10, 0x00, 0x02, 0x02)
    run_command(header, 0, 0x43, 0x10, payload, checksum)
    run_command(header, 6)
    run_command(header, 13)


def main():
    ch = 0
    # show_sxpfinfo()
    # get_firmware_ver(ch)

    """
    print("\nframe_sync")
    get_control_value(ch, "frame_sync")
    set_control_value(ch, "frame_sync", 1)
    get_control_value(ch, "frame_sync")
    """

    """
    print("\nauto_exposure off")
    get_control_value(ch, "auto_exposure")
    set_control_value(ch, "auto_exposure", 1)
    get_control_value(ch, "auto_exposure")
    """

    """
    print("\nexposure_time")
    get_control_value(ch, "exposure_time")
    set_control_value(ch, "exposure_time", 200)
    get_control_value(ch, "exposure_time")
    """

    print("\nHDR on")
    get_control_value(ch, "hdr")
    set_control_value(ch, "hdr", 1)
    get_control_value(ch, "hdr")

    # deinit_camera(ch)
    # init_camera(ch)


if __name__ == "__main__":
    sxpf_release = Path.home() / "video-app" / "src" / "release"
    sxpfinfo = sxpf_release / "sxpfinfo"
    sxpfi2c = sxpf_release / "sxpfi2c"
    main()
