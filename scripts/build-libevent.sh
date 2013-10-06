#!/bin/bash

echo "build libevent"

if [ ! -e "libevent-${LIBEVENT_VERSION}.tar.gz" ]; then
	curl -LO "https://github.com/downloads/libevent/libevent/libevent-${LIBEVENT_VERSION}.tar.gz"
fi

# Extract source
rm -rf "libevent-${LIBEVENT_VERSION}"
tar zxvf "libevent-${LIBEVENT_VERSION}.tar.gz"

pushd "libevent-${LIBEVENT_VERSION}"

	if [ "${ARCH}" == "i386" ];
   	then
		HOST_FLAG=""
	else
		HOST_FLAG="--host=arm-apple-darwin11"
	fi

   ./configure --disable-shared --enable-static --disable-debug-mode ${HOST_FLAG} \
   --prefix="${ROOTDIR}" \
   CC="${GCC} " \
   LDFLAGS="-L${ARCH_BUILT_DIR}" \
   CFLAGS=" -arch ${ARCH} -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR}" \
   CPPLAGS=" -arch ${ARCH} -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} "

   make -j2
   make install

   # Copy the build results        
   cp "${ROOTDIR}/lib/libevent.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_core.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_extra.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_openssl.a" "${ARCH_BUILT_DIR}"
   cp "${ROOTDIR}/lib/libevent_pthreads.a" "${ARCH_BUILT_DIR}"
   cp -R "${ROOTDIR}/include/*" "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "libevent-${LIBEVENT_VERSION}"