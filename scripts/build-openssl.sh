#!/bin/bash
set -e

# Download source
if [ ! -e "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
  curl -O "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"  --retry 5
fi

# Extract source
rm -rf "openssl-${OPENSSL_VERSION}"
tar zxf "openssl-${OPENSSL_VERSION}.tar.gz"

# Build
pushd "openssl-${OPENSSL_VERSION}"

	if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
		if [ "${ARCH}" == "x86_64" ]; then
			EXTRA_CONFIG="darwin64-x86_64-cc enable-ec_nistp_64_gcc_128"
		else
			EXTRA_CONFIG="darwin-i386-cc"
		fi
	else
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		sed -ie "s!\"engine\", !!" "Configurations/15-ios.conf"

		if [ "${ARCH}" == "arm64" ]; then
			EXTRA_CONFIG="iphoneos-cross enable-ec_nistp_64_gcc_128"
		else
			EXTRA_CONFIG="iphoneos-cross"
		fi
	fi

	export CC="${CLANG} -arch ${ARCH} -fPIE ${PLATFORM_VERSION_MIN}"
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${SDK}.sdk"

	# Fix build when cross-compiling for iOS simulator
	if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
		export CFLAGS="-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"
	fi

	./Configure ${EXTRA_CONFIG} no-shared --prefix=${ROOTDIR}

	make depend
	make -j $(sysctl -n hw.ncpu)
	make install_sw

	cp "${ROOTDIR}/lib/libcrypto.a" "${ARCH_BUILT_DIR}"
	cp "${ROOTDIR}/lib/libssl.a" "${ARCH_BUILT_DIR}"
	cp -R "${ROOTDIR}/include/openssl" "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "openssl-${OPENSSL_VERSION}"
