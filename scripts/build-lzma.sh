#!/bin/bash
set -e

ARCHIVE_NAME="xz-${LZMA_VERSION}"

if [ ! -e "${ARCHIVE_NAME}.tar.gz" ]; then
	curl -LO "https://tukaani.org/xz/${ARCHIVE_NAME}.tar.gz"  --retry 5
fi

# Extract source
rm -rf "${ARCHIVE_NAME}"
tar zxf "${ARCHIVE_NAME}.tar.gz"

pushd "${ARCHIVE_NAME}"

   CC="${CLANG}"
   
   LDFLAGS="-L${ARCH_BUILT_DIR} -fPIE ${PLATFORM_VERSION_MIN}"
   CFLAGS=" -arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} ${PLATFORM_VERSION_MIN}"
   CPPFLAGS=" -arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} ${PLATFORM_VERSION_MIN}"

   if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ];
   	then
      EXTRA_CONFIG="--host=${ARCH}-apple-darwin"
	else
		EXTRA_CONFIG="--host=arm-apple-darwin"
	fi

   ./configure --disable-shared --enable-static --disable-doc --disable-scripts \
    --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-lzma-links ${EXTRA_CONFIG} \
   --prefix="${ROOTDIR}" \
   CC="${CLANG} " \
   LDFLAGS="${LDFLAGS}" \
   CFLAGS="${CFLAGS}" \
   CPPLAGS="${CPPFLAGS}" \
   cross_compiling="yes" ac_cv_func_clock_gettime="no"

   make -j $(sysctl -n hw.ncpu)
   make install

   # Copy the build results        
   cp "${ROOTDIR}/lib/liblzma.a" "${ARCH_BUILT_DIR}"
   cp -R ${ROOTDIR}/include/* "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "${ARCHIVE_NAME}"
