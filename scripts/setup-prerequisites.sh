#!/bin/sh


SYS_DIR="${ARCH_BUILT_HEADERS_DIR}/sys/"

# Tor: Disable PT_DENY_ATTACH because it is private API
if [ ! -d "${SYS_DIR}" ]; then
  mkdir -p "${SYS_DIR}"
  touch "${SYS_DIR}/ptrace.h"
fi
