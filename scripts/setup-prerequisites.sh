#!/bin/sh

# Copy required libz for Tor
cp "${SDK_PATH}/usr/lib/libz.dylib" "${ARCH_BUILT_DIR}/libz.a"
cp "${SDK_PATH}/usr/include/zlib.h" "${ARCH_BUILT_HEADERS_DIR}/zlib.h"

# Copy ptrace.h for the Tor build process
SDK_PATH_SIM=$(xcrun -sdk macosx --show-sdk-path)
mkdir "${ARCH_BUILT_HEADERS_DIR}/sys/"
cp "${SDK_PATH_SIM}/usr/include/sys/ptrace.h" "${ARCH_BUILT_HEADERS_DIR}/sys/"

# Download build patches for Tor

if [ ! -f "patch-tor-nsenviron.diff" ]; then
curl -LO "https://raw.github.com/Raphaelios/raphaelios-scripts/master/tor/patch-tor-nsenviron.diff"
fi

if [ ! -f "patch-tor-ptrace.diff" ]; then
curl -LO "https://raw.github.com/Raphaelios/raphaelios-scripts/master/tor/patch-tor-ptrace.diff"
fi
