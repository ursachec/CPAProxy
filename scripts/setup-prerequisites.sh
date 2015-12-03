#!/bin/sh

# Copy required libz for Tor
#cp "${SDK_PATH}/usr/lib/libz.dylib" "${ARCH_BUILT_DIR}/libz.a"
#cp "${SDK_PATH}/usr/include/zlib.h" "${ARCH_BUILT_HEADERS_DIR}/zlib.h"

# Copy ptrace.h for the Tor build process
SDK_PATH_SIM=$(xcrun -sdk macosx --show-sdk-path)
SYS_DIR="${ARCH_BUILT_HEADERS_DIR}/sys/"

if [ ! -d "${SYS_DIR}" ]; then
  mkdir -p "${SYS_DIR}"
  cp "${SDK_PATH_SIM}/usr/include/sys/ptrace.h" "${SYS_DIR}"
fi
