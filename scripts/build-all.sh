#!/bin/bash

# User variables
# VARIABLE : valid options
# ARCHS : i386 x86_64 armv7 arm64
# LIBRARIES: openssl libevent tor
# USE_BUILD_LOG: true false


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

if [ -n "${ARCHS}" ]; then
  echo "Building user-defined architectures: ${ARCHS}"
else
  ARCHS="i386 x86_64 armv7 arm64"
  echo "Building architectures: ${ARCHS}"
fi

if [ -n "${LIBRARIES}" ]; then
  echo "Building user-defined libraries: ${LIBRARIES}"
else
  LIBRARIES="openssl libevent tor"
  echo "Building libraries: ${LIBRARIES}"
fi

# Versions
export MIN_IOS_VERSION="8.0"
export OPENSSL_VERSION="1.0.2j"
export LIBEVENT_VERSION="2.0.22-stable"
export TOR_VERSION="0.2.8.9"

BUILT_ARCHS=()
DEVELOPER=`xcode-select --print-path`
cd "`dirname \"$0\"`"
TOPDIR=$(pwd)

BUILT_DIR="${TOPDIR}/built"
if [ ! -d "${BUILT_DIR}" ]; then
  mkdir -p "${BUILT_DIR}"
fi

BUILD_DIR="${TOPDIR}/build"
if [ ! -d "${BUILD_DIR}" ]; then
  mkdir -p "${BUILD_DIR}"
fi

# Combine build results of different archs into one
export FINAL_BUILT_DIR="${TOPDIR}/../CPAProxyDependencies"
if [ ! -d "${FINAL_BUILT_DIR}" ]; then
  mkdir -p "${FINAL_BUILT_DIR}"
else
  echo "Final product directory CPAProxyDependencies found, skipping build..."
  exit 0
fi

cd ${BUILD_DIR}

for ARCH in ${ARCHS}
do
  for LIBRARY in ${LIBRARIES}
  do
    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
        PLATFORM="iPhoneSimulator"
        PLATFORM_SDK="iphonesimulator${SDK}"
    else
        PLATFORM="iPhoneOS"
        PLATFORM_SDK="iphoneos${SDK}"
    fi
    ROOTDIR="${BUILD_DIR}/${PLATFORM}-${SDK}-${ARCH}"
    rm -rf "${ROOTDIR}"
    mkdir -p "${ROOTDIR}"

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
    export SDK_PATH=$(xcrun -sdk ${PLATFORM_SDK} --show-sdk-path)
    export CLANG=$(xcrun -sdk ${PLATFORM_SDK} -find clang)

    # Build the platform dependencies
    if [ "${USE_BUILD_LOG}" == "true" ]; then
      ../setup-prerequisites.sh > "${ROOTDIR}-setup-prerequisites.log"
    else
      ../setup-prerequisites.sh
    fi

    echo "Building ${LIBRARY} for ${ARCH}..."
    if [ "${USE_BUILD_LOG}" == "true" ]; then
      ../build-${LIBRARY}.sh > "${ROOTDIR}-${LIBRARY}.log"
    else
      ../build-${LIBRARY}.sh
    fi
    
    # Remove junk
    rm -rf "${ROOTDIR}"
  done
  BUILT_ARCHS+=("${ARCH}")
done

cd ../

# Combine binaries of different architectures results
BINS=(libcrypto.a libssl.a)
BINS+=(libevent_core.a libevent_pthreads.a libevent_extra.a libevent_openssl.a libevent.a)
BINS+=(libcurve25519_donna.a libor-crypto.a libtor.a libor-event.a libor.a libor-trunnel.a libed25519_donna.a libed25519_ref10.a libkeccak-tiny.a)

NUMBER_OF_BUILT_ARCHS=${#BUILT_ARCHS[@]}


for BIN in ${BINS[@]}; do
  FILE_ARCH_PATHS=( "${BUILT_ARCHS[@]/#/${BUILT_DIR}/}" )
  FILE_ARCH_PATHS=( "${FILE_ARCH_PATHS[@]/%//${BIN}}" )
  if [ "${NUMBER_OF_BUILT_ARCHS}" == "1" ]; then
    for FILE_ARCH_PATH in ${FILE_ARCH_PATHS[@]}; do
      echo "${BIN} only built for (${BUILT_ARCHS}), skipping lipo and copying to ${FINAL_BUILT_DIR}/${BIN}"
      cp "${FILE_ARCH_PATH}" "${FINAL_BUILT_DIR}/${BIN}"
    done
  else
    xcrun -sdk iphoneos lipo ${FILE_ARCH_PATHS[@]} -create -output "${FINAL_BUILT_DIR}/${BIN}"
  fi
done

# Copy torrc to the final directory
cp "torrc" "${FINAL_BUILT_DIR}/"

# Setup tor_cpaproxy.h
cp "tor_cpaproxy.h" "${FINAL_BUILT_DIR}/"
TOR_REVISION=$(find "${BUILT_DIR}/${BUILT_ARCHS[0]}/" -name "micro-revision.i" -exec cat {} \;)
sed -i '' "s/@TOR_GIT_REVISION@/${TOR_REVISION}/" "${FINAL_BUILT_DIR}/tor_cpaproxy.h"

# Final cleanups
rm -rf "${BUILT_DIR}"
rm -rf "${BUILD_DIR}"

echo "Success! Finished building ${LIBRARIES} for ${ARCHS}."
