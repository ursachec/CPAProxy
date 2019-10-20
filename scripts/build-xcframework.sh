#!/bin/bash

# User variables
# VARIABLE : valid options
# ARCHS : x86_64 x86_64-simulator x86_64-maccatalyst arm64

set -e

cd "`dirname \"$0\"`"
TOPDIR=$(pwd)

# Combine build results of different archs into one
export FINAL_BUILT_DIR="${TOPDIR}/../CPAProxyDependencies/"
mkdir -p "${FINAL_BUILT_DIR}"
export LIBCPAPROXY_XCFRAMEWORK="${FINAL_BUILT_DIR}/libcpaproxy.xcframework"

if [ -d "${LIBCPAPROXY_XCFRAMEWORK}" ]; then
  echo "Final libcpaproxy.xcframework found, skipping build..."
  exit 0
fi

BUILT_DIR="${TOPDIR}/built"
if [ ! -d "${BUILT_DIR}" ]; then
  mkdir -p "${BUILT_DIR}"
fi

if [ -n "${ARCHS}" ]; then
  echo "Linking user-defined architectures: ${ARCHS}"
else
  ARCHS="x86_64 x86_64-simulator x86_64-maccatalyst arm64"
  echo "Linking architectures: ${ARCHS}"
fi

NUMBER_OF_BUILT_ARCHS=${#ARCHS[@]}

XCFRAMEWORK_INPUTS=""


for ARCH in ${ARCHS}; do
  ARCH_DIR="${BUILT_DIR}/${ARCH}"
  LIB_DIR="${ARCH_DIR}/lib"
  LIBCPAPROXY="${ARCH_DIR}/libcpaproxy.a"
  xcrun libtool -static -o "${LIBCPAPROXY}" ${LIB_DIR}/*
  XCFRAMEWORK_INPUTS+="-library ${LIBCPAPROXY} -headers ${ARCH_DIR}/include "
done

xcrun xcodebuild -create-xcframework ${XCFRAMEWORK_INPUTS} -output "${LIBCPAPROXY_XCFRAMEWORK}"

echo "Success! Finished building xcframework."