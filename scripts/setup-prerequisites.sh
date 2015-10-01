#!/bin/sh

# Copy ptrace.h for the Tor build process
SDK_PATH_SIM=$(xcrun -sdk macosx --show-sdk-path)
SYS_DIR="${ARCH_BUILT_HEADERS_DIR}/sys/"

if [ ! -d "${SYS_DIR}" ]; then
  mkdir -p "${SYS_DIR}"
  cp "${SDK_PATH_SIM}/usr/include/sys/ptrace.h" "${SYS_DIR}"
fi
