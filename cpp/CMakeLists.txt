cmake_minimum_required(VERSION 3.17)

set(CMAKE_C_COMPILER "gcc-11")
set(CMAKE_CXX_COMPILER "g++-11")

project(sxpf-nilecam21)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_BUILD_TYPE Release)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_VERBOSE_MAKEFILE true)

include(FetchContent)
# Fetch fmt
FetchContent_Declare(
  fmt
  GIT_REPOSITORY https://github.com/fmtlib/fmt.git
  GIT_TAG 8.1.1)
FetchContent_MakeAvailable(fmt)

# Find Packages
find_package(OpenCV REQUIRED)

# Add sxpf library
set(SXPF_LIB_DIR "~/video-app/src/libs")
add_library(
  sxpf
  ${SXPF_LIB_DIR}/sxpf_ll/sxpf.cpp ${SXPF_LIB_DIR}/sxpf_ll/lin64/os_dep.cpp
  ${SXPF_LIB_DIR}/csi-2/img_decode.cpp)
target_include_directories(
  sxpf PUBLIC ${SXPF_LIB_DIR}/sxpf_ll ${SXPF_LIB_DIR}/support
              ${SXPF_LIB_DIR}/sxpf_ll/lin64 ${SXPF_LIB_DIR}/csi-2)

# Add executable
add_executable(exec_rec sxpf-app.cpp)
target_link_libraries(exec_rec PRIVATE sxpf ${OpenCV_LIBS} fmt::fmt)
