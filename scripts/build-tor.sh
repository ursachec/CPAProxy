#!/bin/bash
set -e

# Download source
if [ ! -e "tor-${TOR_VERSION}.tar.gz" ]; then
  curl -O "https://archive.torproject.org/tor-package-archive/tor-${TOR_VERSION}.tar.gz" --retry 5
fi

# Extract source
rm -rf "tor-${TOR_VERSION}"
tar zxf "tor-${TOR_VERSION}.tar.gz"

pushd "tor-${TOR_VERSION}"

	LDFLAGS="-L${ARCH_BUILT_DIR} -fPIE ${PLATFORM_VERSION_MIN}"
	CFLAGS="-arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} ${PLATFORM_VERSION_MIN}"
	CPPFLAGS="-arch ${ARCH} -fPIE -isysroot ${SDK_PATH} -I${ARCH_BUILT_HEADERS_DIR} ${PLATFORM_VERSION_MIN}"

	if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
		EXTRA_CONFIG="--host=${ARCH}-apple-darwin"
    else
        EXTRA_CONFIG="--host=arm-apple-darwin"
    fi

	./configure \
	--prefix="${ROOTDIR}" \
	--with-openssl-dir="${ARCH_BUILT_DIR}" \
	--with-libevent-dir="${ARCH_BUILT_DIR}" \
	--enable-restart-debugging --enable-silent-rules --enable-pic --disable-module-dirauth \
	--disable-tool-name-check --disable-unittests --enable-static-openssl --enable-static-libevent \
	--disable-asciidoc --disable-system-torrc --disable-linker-hardening --disable-dependency-tracking \
	--enable-lzma --disable-zstd ${EXTRA_CONFIG} \
	CC="${CLANG}" \
	LDFLAGS="${LDFLAGS}" \
	CFLAGS="${CFLAGS}" \
	CPPFLAGS="${CPPFLAGS}" \
	cross_compiling="yes" ac_cv_func__NSGetEnviron="no" ac_cv_func_clock_gettime="no" ac_cv_func_getentropy="no"

	make -j $(sysctl -n hw.ncpu)

	# Copy the build results
	for LIBRARY in src/lib/*.a src/core/*.a src/ext/ed25519/donna/*.a src/ext/ed25519/ref10/*.a src/trunnel/*.a src/ext/keccak-tiny/*.a;
    do
        cp $LIBRARY "${ARCH_BUILT_DIR}"
    done

	# Copy the micro-revision.i file that defines the Tor version
	cp "micro-revision.i" "${ARCH_BUILT_HEADERS_DIR}/"

	# Copy the geoip files
	cp "src/config/geoip" "${FINAL_BUILT_DIR}/"
	cp "src/config/geoip6" "${FINAL_BUILT_DIR}/"
popd

# Clean up
rm -rf "tor-${TOR_VERSION}"
