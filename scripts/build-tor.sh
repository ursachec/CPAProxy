#!/bin/bash

# Download source
if [ ! -e "tor-${TOR_VERSION}.tar.gz" ]; then
  curl -O "https://www.torproject.org/dist/tor-${TOR_VERSION}.tar.gz"
fi

# Extract source
rm -rf "tor-${TOR_VERSION}"
tar zxvf "tor-${TOR_VERSION}.tar.gz"

pushd "tor-${TOR_VERSION}"

	# Apply patches
	patch -p3 < "${TOPDIR}/patch-tor-nsenviron.diff"
	patch -p3 < "${TOPDIR}/patch-tor-ptrace.diff"

	LDFLAGS="-L${ARCH_BUILT_DIR}"
	CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"
	CPPFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"

	if [ "${ARCH}" == "i386" ];
	then
	  HOST_FLAG=""
	else
	  HOST_FLAG="--host=arm-apple-darwin11 --target=arm-apple-darwin11 --disable-gcc-hardening --disable-linker-hardening"
	fi

	./configure --enable-static-openssl --enable-static-libevent --enable-static-zlib ${HOST_FLAG} \
	--prefix="${ROOTDIR}" \
	--with-openssl-dir="${ARCH_BUILT_DIR}" \
	--with-libevent-dir="${ARCH_BUILT_DIR}" \
	--with-zlib-dir="${ARCH_BUILT_DIR}" \
	--disable-asciidoc \
	CC="${GCC}" \
	LDFLAGS="${LDFLAGS}" \
	CFLAGS="${CFLAGS}" \
	CPPFLAGS="${CPPFLAGS}"

	make -j2

	# Copy the build results
	cp "src/common/libor-crypto.a" "${ARCH_BUILT_DIR}"
	cp "src/common/libor-event.a" "${ARCH_BUILT_DIR}"
	cp "src/common/libor.a" "${ARCH_BUILT_DIR}"
	cp "src/or/libtor.a" "${ARCH_BUILT_DIR}"

	# Copy the micro-revision.i file that defines the Tor version
	cp "src/or/micro-revision.i" "${ARCH_BUILT_HEADERS_DIR}/"

popd

# Clean up
rm -rf "tor-${TOR_VERSION}"