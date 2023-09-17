#!/usr/bin/env bash
##
# Lint scripts.
#

set -e
[ -n "${DREVOPS_DEBUG}" ] && set -x

CUR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

targets=()
while IFS= read -r -d $'\0'; do
  targets+=("$REPLY")
done < <(
  find \
    "${CUR_DIR}"/src \
    "${CUR_DIR}"/tests \
    "${CUR_DIR}"/lint.sh \
    -type f \
    \( -name "*.sh" -or -name "*.bash" -or -name "*.bats" \) \
    -print0
)
targets+=("${CUR_DIR}/install")

for file in "${targets[@]}"; do
  if [ -f "${file}" ]; then
    echo "Checking file ${file}"
    if ! LC_ALL=C.UTF-8 shellcheck -e SC2223 "${file}"; then
      exit 1
    fi

    if ! LC_ALL=C.UTF-8 shfmt -i 2 -ci -s -d "${file}"; then
      exit 1
    fi
  fi
done
