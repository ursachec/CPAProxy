#!/bin/bash

# User variables
# VARIABLE : valid options
# ARCHS : x86_64 x86_64-simulator x86_64-maccatalyst arm64
# LIBRARIES: openssl libevent lzma tor
# USE_BUILD_LOG: true false
# PLATFORM_TARGET: iOS macOS

set -e

if [  "${PLATFORM_TARGET}" == "" ]; then
  echo "No platform target set, using iOS."
  export PLATFORM_TARGET="iOS"
fi
echo "Using platform target: $PLATFORM_TARGET."

SDK=$1
if [ "${SDK}" == "" ]
then
  SDK_PREFIX="iphoneos"
  if [ "$PLATFORM_TARGET" == "iOS" ]; then
    SDK_PREFIX="iphoneos"
  else
    SDK_PREFIX="macosx10.15"
  fi
  AVAIL_SDKS=`xcodebuild -showsdks | grep "$SDK_PREFIX"`
  FIRST_SDK=`echo "$AVAIL_SDKS" | head -n1`
  if [ "$AVAIL_SDKS" == "$FIRST_SDK" ]; then
    SDK=`echo "$FIRST_SDK" | cut -d\  -f2`
    echo "No SDK specified. Using the only one available: $PLATFORM_TARGET $SDK"
  else
    echo "Please specify an $PLATFORM_TARGET SDK version number from the following possibilities:"
    echo "$AVAIL_SDKS"
    exit 1
  fi
fi

if [ -n "${ARCHS}" ]; then
  echo "Building user-defined architectures: ${ARCHS}"
else
  if [ "$PLATFORM_TARGET" == "iOS" ]; then
    ARCHS="x86_64-simulator x86_64-maccatalyst arm64"
  else
    ARCHS="x86_64"
  fi
  echo "Building architectures: ${ARCHS}"
fi


if [ -n "${LIBRARIES}" ]; then
  echo "Building user-defined libraries: ${LIBRARIES}"
else
  LIBRARIES="openssl libevent lzma tor"
  echo "Building libraries: ${LIBRARIES}"
fi

# Versions
export MIN_IOS_VERSION="8.0"
export MIN_OSX_VERSION="10.10"
export OPENSSL_VERSION="1.1.1c"
export LZMA_VERSION="5.2.4"
export LIBEVENT_VERSION="2.1.10-stable"
export TOR_VERSION="0.4.0.5"

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
export FINAL_BUILT_DIR="${TOPDIR}/../CPAProxyDependencies/"
mkdir -p "${FINAL_BUILT_DIR}"
export LIBCPAPROXY_XCFRAMEWORK="${FINAL_BUILT_DIR}/libcpaproxy.xcframework"

if [ -d "${LIBCPAPROXY_XCFRAMEWORK}" ]; then
  echo "Final libcpaproxy.xcframework found, skipping build..."
  exit 0
fi

cd ${BUILD_DIR}

for ARCH in ${ARCHS}
do
  for LIBRARY in ${LIBRARIES}
  do
    if [ "$PLATFORM_TARGET" == "iOS" ]; then
      if [ "${ARCH}" == "x86_64-simulator" ]; then
          PLATFORM="iPhoneSimulator"
          PLATFORM_SDK="iphonesimulator${SDK}"
      else
          PLATFORM="iPhoneOS"
          PLATFORM_SDK="iphoneos${SDK}"
      fi

      REAL_SDK="${SDK}"
      if [ "${ARCH}" == "x86_64-maccatalyst" ]; then
        MIN_IOS_VERSION="13.0"
        PLATFORM="MacOSX"
        SDK="10.15"
        PLATFORM_SDK="macosx${SDK}"
        export PLATFORM_VERSION_MIN="-target x86_64-apple-ios-macabi -miphoneos-version-min=${MIN_IOS_VERSION}"
      else
        MIN_IOS_VERSION="8.0"
        export PLATFORM_VERSION_MIN="-miphoneos-version-min=${MIN_IOS_VERSION}"
      fi
    else
      PLATFORM="MacOSX"
      PLATFORM_SDK="macosx${SDK}"
      export PLATFORM_VERSION_MIN="-mmacosx-version-min=${MIN_OSX_VERSION}"
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

    ARCH_BUILT_LIBS_DIR="${ARCH_BUILT_DIR}/lib"
    if [ ! -d "${ARCH_BUILT_LIBS_DIR}" ]; then
      mkdir "${ARCH_BUILT_LIBS_DIR}"
    fi

    ARCH_BUILT_BIN_DIR="${ARCH_BUILT_DIR}/bin"
    if [ ! -d "${ARCH_BUILT_BIN_DIR}" ]; then
      mkdir "${ARCH_BUILT_BIN_DIR}"
    fi

    REAL_ARCH="${ARCH}"
    if [ "${ARCH}" == "x86_64-maccatalyst" ] || [ "${ARCH}" == "x86_64-simulator" ] ; then
      ARCH="x86_64"
    else
      ARCH="${ARCH}"
    fi

    export TOPDIR="${TOPDIR}"
    export ARCH_BUILT_HEADERS_DIR="${ARCH_BUILT_HEADERS_DIR}"
    export ARCH_BUILT_LIBS_DIR="${ARCH_BUILT_LIBS_DIR}"
    export ARCH_BUILT_BIN_DIR="${ARCH_BUILT_BIN_DIR}"
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

    ARCH="${REAL_ARCH}"
    SDK="${REAL_SDK}"
  done
  BUILT_ARCHS+=("${ARCH}")
done

cd ../

# Combine binaries of different architectures results

# OpenSSL
BINS=(libcrypto.a libssl.a)
# libevent
BINS+=(libevent_core.a libevent_pthreads.a libevent_extra.a libevent_openssl.a libevent.a)
# Tor
BINS+=(libed25519_ref10.a libed25519_donna.a libkeccak-tiny.a libtor-err.a libtor-ctime.a libtor-compress.a)
BINS+=(libtor-container.a libtor-crypt-ops.a libtor-encoding.a libtor-evloop.a libtor-fdio.a libtor-fs.a libcurve25519_donna.a)
BINS+=(libtor-intmath.a libtor-lock.a libtor-log.a libtor-math.a libtor-memarea.a libtor-meminfo.a libtor-malloc.a libtor-net.a)
BINS+=(libtor-osinfo.a libtor-process.a libtor-sandbox.a libtor-string.a libtor-smartlist-core.a libtor-term.a libtor-thread.a)
BINS+=(libtor-time.a libtor-tls.a libtor-trace.a libtor-wallclock.a libor-trunnel.a libtor-app.a libtor-geoip.a libtor-buf.a libtor-version.a)
# LZMA
BINS+=(liblzma.a)

NUMBER_OF_BUILT_ARCHS=${#BUILT_ARCHS[@]}


# Copy torrc to the final directory
cp "torrc" "${FINAL_BUILT_DIR}/"

# Setup tor_cpaproxy.h
cp "tor_cpaproxy.h" "${FINAL_BUILT_DIR}/"
TOR_REVISION=$(find "${BUILT_DIR}/${BUILT_ARCHS[0]}/" -name "micro-revision.i" -exec cat {} \;)
sed -i '' "s/@TOR_GIT_REVISION@/${TOR_REVISION}/" "${FINAL_BUILT_DIR}/tor_cpaproxy.h"

# Final cleanups
rm -rf "${BUILD_DIR}"

echo "Success! Finished building ${LIBRARIES} for ${ARCHS}."
