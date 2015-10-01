#!/bin/bash
set -e

ZLIB_VERSION="1.2.8"
ARCHIVE_NAME="zlib-${ZLIB_VERSION}"

if [ ! -e "${ARCHIVE_NAME}.tar.gz" ]; then
    curl -L -o ${ARCHIVE_NAME}.tar.gz "https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz" --retry 5
fi

# Extract source
rm -rf "${ARCHIVE_NAME}"
tar zxf "${ARCHIVE_NAME}.tar.gz"

pushd "${ARCHIVE_NAME}"

    CC="${CLANG}"
    LDFLAGS="-L${ARCH_BUILT_DIR} -fPIE -miphoneos-version-min=${MIN_IOS_VERSION}"
    CFLAGS=" -arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"
    CPPFLAGS=" -arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"

    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ];
        then
           CFLAGS="${CFLAGS} -O3 -mios-simulator-version-min=${MIN_IOS_VERSION} -Wno-error-implicit-function-declaration"
        else
           CFLAGS="${CFLAGS} -O3  -mios-version-min=${MIN_IOS_VERSION}"
        fi

    export CC="${CLANG}"
    export LDFLAGS="${LDFLAGS}"
    export CFLAGS="${CFLAGS}"
    export CPPLAGS="${CPPFLAGS}"
   
    ./configure --prefix="${ROOTDIR}"


   make
   make install

   # Copy the build results        
   cp "${ROOTDIR}/lib/libz.a" "${ARCH_BUILT_DIR}"
   cp -R ${ROOTDIR}/include/* "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "${ARCHIVE_NAME}"
