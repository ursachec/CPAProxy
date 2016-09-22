#!/bin/bash
set -e

# Download source
if [ ! -e "tor-${TOR_VERSION}.tar.gz" ]; then
  curl -O "https://dist.torproject.org/tor-${TOR_VERSION}.tar.gz" --retry 5
fi

# Extract source
rm -rf "tor-${TOR_VERSION}"
tar zxf "tor-${TOR_VERSION}.tar.gz"

pushd "tor-${TOR_VERSION}"

	# Apply patches
	patch -p3 < "${TOPDIR}/patches/tor-nsenviron.diff"
	patch -p3 < "${TOPDIR}/patches/tor-ptrace.diff"
	patch -p3 < "${TOPDIR}/patches/tor-configure.diff" configure

	LDFLAGS="-L${ARCH_BUILT_DIR} -fPIE -miphoneos-version-min=${MIN_IOS_VERSION}"
	CFLAGS="-arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"
	CPPFLAGS="-arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} -miphoneos-version-min=${MIN_IOS_VERSION}"

	if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
		EXTRA_CONFIG="--host=${ARCH}-apple-darwin"
    else
        EXTRA_CONFIG="--host=arm-apple-darwin"
    fi

	./configure --enable-static-openssl --enable-static-libevent ${EXTRA_CONFIG} \
	--prefix="${ROOTDIR}" \
	--with-openssl-dir="${ARCH_BUILT_DIR}" \
	--with-libevent-dir="${ARCH_BUILT_DIR}" \
	--disable-asciidoc --disable-transparent --disable-tool-name-check \
	CC="${CLANG}" \
	LDFLAGS="${LDFLAGS}" \
	CFLAGS="${CFLAGS}" \
	CPPFLAGS="${CPPFLAGS}"

	make

	# Copy the build results
	cp "src/common/libor-crypto.a" "${ARCH_BUILT_DIR}"
	cp "src/common/libor-event.a" "${ARCH_BUILT_DIR}"
	cp "src/common/libor.a" "${ARCH_BUILT_DIR}"
	cp "src/common/libcurve25519_donna.a" "${ARCH_BUILT_DIR}"
	cp "src/or/libtor.a" "${ARCH_BUILT_DIR}"
	cp "src/trunnel/libor-trunnel.a" "${ARCH_BUILT_DIR}"
	cp "src/ext/ed25519/donna/libed25519_donna.a" "${ARCH_BUILT_DIR}"
	cp "src/ext/ed25519/ref10/libed25519_ref10.a" "${ARCH_BUILT_DIR}"
	cp "src/ext/keccak-tiny/libkeccak-tiny.a" "${ARCH_BUILT_DIR}"

	# Copy the micro-revision.i file that defines the Tor version
	cp "micro-revision.i" "${ARCH_BUILT_HEADERS_DIR}/"

	# Copy the geoip files
	cp "src/config/geoip" "${FINAL_BUILT_DIR}/"
	cp "src/config/geoip6" "${FINAL_BUILT_DIR}/"
popd

# Clean up
rm -rf "tor-${TOR_VERSION}"