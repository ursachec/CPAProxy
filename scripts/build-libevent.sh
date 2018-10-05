#!/bin/bash
set -e

ARCHIVE_NAME="libevent-${LIBEVENT_VERSION}"

if [ ! -e "${ARCHIVE_NAME}.tar.gz" ]; then
	curl -LO "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/${ARCHIVE_NAME}.tar.gz"  --retry 5
fi

# Extract source
rm -rf "${ARCHIVE_NAME}"
tar zxf "${ARCHIVE_NAME}.tar.gz"

pushd "${ARCHIVE_NAME}"

#   patch -p3 < "${TOPDIR}/patches/libevent-configure.diff" configure

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

   ./configure --disable-shared --enable-static --disable-debug-mode ${EXTRA_CONFIG} \
   --prefix="${ROOTDIR}" \
   CC="${CLANG} " \
   LDFLAGS="${LDFLAGS}" \
   CFLAGS="${CFLAGS}" \
   CPPLAGS="${CPPFLAGS}"

   make
   make install

   # Copy the build results        
   cp "${ROOTDIR}/lib/libevent.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_core.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_extra.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_openssl.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_pthreads.a" "${ARCH_BUILT_DIR}"
   cp -R ${ROOTDIR}/include/* "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "${ARCHIVE_NAME}"
