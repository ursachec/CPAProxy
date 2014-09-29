#!/bin/bash
set -e

if [ ! -e "libevent-${LIBEVENT_VERSION}.tar.gz" ]; then
	curl -LO "https://github.com/downloads/libevent/libevent/libevent-${LIBEVENT_VERSION}.tar.gz"  --retry 5
fi

# Extract source
rm -rf "libevent-${LIBEVENT_VERSION}"
tar zxf "libevent-${LIBEVENT_VERSION}.tar.gz"

pushd "libevent-${LIBEVENT_VERSION}"

   CC="${CLANG}"
   LDFLAGS="-L${ARCH_BUILT_DIR} -fPIE -miphoneos-version-min=${MIN_IOS_VERSION}"
   CFLAGS=" -arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"
   CPPFLAGS=" -arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"

   if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ];
   	then
		EXTRA_CONFIG=""
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
rm -rf "libevent-${LIBEVENT_VERSION}"