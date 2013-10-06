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

./Configure BSD-generic32 --openssldir=${ROOTDIR}

make CC="${GCC} -arch ${ARCH}" CFLAG="-isysroot ${SDK_PATH}"
make install

cp "${ROOTDIR}/lib/libcrypto.a" "${ARCH_BUILT_DIR}"
cp "${ROOTDIR}/lib/libssl.a" "${ARCH_BUILT_DIR}"
cp -R "${ROOTDIR}/include/openssl" "${ARCH_BUILT_HEADERS_DIR}"

popd

# Clean up
rm -rf "openssl-${OPENSSL_VERSION}"