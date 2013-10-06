#!/bin/bash
set -e

SDK=$1
if [ "${SDK}" == "" ]
then
  AVAIL_SDKS=`xcodebuild -showsdks | grep "iphoneos"`
  FIRST_SDK=`echo "$AVAIL_SDKS" | head -n1`
  if [ "$AVAIL_SDKS" == "$FIRST_SDK" ]; then
    SDK=`echo "$FIRST_SDK" | cut -d\  -f2`
    echo "No iOS SDK specified. Using the only one available: $SDK"
  else
    echo "Please specify an iOS SDK version number from the following possibilities:"
    echo "$AVAIL_SDKS"
    exit 1
  fi
fi

# Platforms to build for (changing this may break the build)
PLATFORMS="iPhoneSimulator iPhoneOS-V7 iPhoneOS-V7s iPhoneOS-V64"

export OPENSSL_VERSION="1.0.0c"

export LIBEVENT_VERSION="2.0.21-stable"

export TOR_VERSION="0.2.3.25"

FINAL_BUILT_DIR="CPAProxyDependencies"
BUILT_ARCHS=()
DEVELOPER=`xcode-select --print-path`
TOPDIR=`pwd`

BUILT_DIR="${TOPDIR}/built"
if [ ! -d "${BUILT_DIR}" ]; then
  mkdir -p "${BUILT_DIR}"
fi

for PLATFORM in ${PLATFORMS}
do
  ROOTDIR="${TOPDIR}/${PLATFORM}-${SDK}"
  if [ "${PLATFORM}" == "iPhoneOS-V64" ]
  then
    PLATFORM="iphoneos"
    ARCH="arm64"
  elif [ "${PLATFORM}" == "iPhoneOS-V7s" ]
  then
    PLATFORM="iphoneos"
    ARCH="armv7s"
  elif [ "${PLATFORM}" == "iPhoneOS-V7" ]
  then
    PLATFORM="iphoneos"
    ARCH="armv7"
  else
  	PLATFORM="macosx"
    ARCH="i386"
  fi
  rm -rf "${ROOTDIR}"
  mkdir -p "${ROOTDIR}"

  BUILT_ARCHS+=("${ARCH}")

  ARCH_BUILT_DIR="${BUILT_DIR}/${ARCH}"
  if [ ! -d "${ARCH_BUILT_DIR}" ]; then
    mkdir -p "${ARCH_BUILT_DIR}"
  fi

  ARCH_BUILT_HEADERS_DIR="${ARCH_BUILT_DIR}/include"
  if [ ! -d "${ARCH_BUILT_HEADERS_DIR}" ]; then
    mkdir "${ARCH_BUILT_HEADERS_DIR}"
  fi

  export TOPDIR="${TOPDIR}"
  export ARCH_BUILT_HEADERS_DIR="${ARCH_BUILT_HEADERS_DIR}"
  export ARCH_BUILT_DIR="${ARCH_BUILT_DIR}"
  export DEVELOPER="${DEVELOPER}"
  export ROOTDIR="${ROOTDIR}"
  export PLATFORM="${PLATFORM}"
  export SDK="${SDK}"
  export ARCH="${ARCH}"
  export SDK_PATH=$(xcrun -sdk ${PLATFORM} --show-sdk-path)
  export GCC=$(xcrun -sdk ${PLATFORM} -find gcc)

  # Build the platform dependencies
  ./setup-prerequisites.sh > "${ROOTDIR}-setup-prerequisites.log"

  # # Build OpenSSL
  ./build-openssl.sh > "${ROOTDIR}-openssl.log"

  # # Build libevent
  ./build-libevent.sh > "${ROOTDIR}-libevent.log"

  # # Build tor
  ./build-tor.sh > "${ROOTDIR}-tor.log"
  
  # Remove junk
  rm -rf "${ROOTDIR}"
done

# Combine build results of different archs into one
if [ ! -d "${FINAL_BUILT_DIR}" ]; then
  mkdir -p "${FINAL_BUILT_DIR}"
fi

# Combine binaries of different architectures results
BINS=(libcrypto.a libssl.a)
BINS+=(libevent_core.a libevent_pthreads.a libevent_extra.a libevent_openssl.a libevent.a)
BINS+=(libor-crypto.a libtor.a libor-event.a libor.a)

for BIN in ${BINS[@]}; do
  FILE_ARCH_PATHS=( "${BUILT_ARCHS[@]/#/${BUILT_DIR}/}" )
  FILE_ARCH_PATHS=( "${FILE_ARCH_PATHS[@]/%//${BIN}}" )

  xcrun -sdk iphoneos lipo ${FILE_ARCH_PATHS[@]} -create -output "${FINAL_BUILT_DIR}/${BIN}"
done

# Copy torrc and geoip to the final directory
cp "torrc" "${FINAL_BUILT_DIR}/"
cp "geoip" "${FINAL_BUILT_DIR}/"

# Setup tor_cpaproxy.h
cp "tor_cpaproxy.h" "${FINAL_BUILT_DIR}/"
TOR_REVISION=$(find "${BUILT_DIR}/${BUILT_ARCHS[0]}/" -name "micro-revision.i" -exec cat {} \;)
sed -i '' "s/@TOR_GIT_REVISION@/${TOR_REVISION}/" "${FINAL_BUILT_DIR}/tor_cpaproxy.h"

# Final cleanups
rm -f *.diff
rm -f *.log
rm -rf "${BUILT_DIR}"
