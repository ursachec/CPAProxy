#!/bin/bash

# Download source
if [ ! -e "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
  curl -O "http://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
fi

# Extract source
rm -rf "openssl-${OPENSSL_VERSION}"
tar zxvf "openssl-${OPENSSL_VERSION}.tar.gz"

# Build
pushd "openssl-${OPENSSL_VERSION}"

	./Configure BSD-generic32 no-asm --openssldir=${ROOTDIR}

	CC="${GCC} -arch ${ARCH} -miphoneos-version-min=${MIN_IOS_VERSION}"
	LDFLAGS=""
	CFLAGS="-isysroot ${SDK_PATH} -miphoneos-version-min=${MIN_IOS_VERSION}"

	make CC="${CC}" CFLAG="${CFLAGS}" SHARED_LDFLAGS="${LDFLAGS}"
	make install

	cp "${ROOTDIR}/lib/libcrypto.a" "${ARCH_BUILT_DIR}"
	cp "${ROOTDIR}/lib/libssl.a" "${ARCH_BUILT_DIR}"
	cp -R "${ROOTDIR}/include/openssl" "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "openssl-${OPENSSL_VERSION}"