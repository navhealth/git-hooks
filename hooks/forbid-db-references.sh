#!/usr/bin/env bash
set -eu

# Forbid database references matching pattern: (?:dev|int|prod_[^.]+)\.[^.]+\.[^.]+
# This catches fully qualified database.schema.table names with dev/int/prod databases

readonly pattern='(dev[^.]*|int[^.]*|prod_[^.]+)\.[^.]+\.[^.]+'
found_violations=0

if [ $# -gt 0 ]; then
  for filename in "${@}"; do
    if grep -E "${pattern}" "${filename}" > /dev/null 2>&1; then
      echo "[ERROR] ${filename} contains forbidden database references:"
      grep -E -n "${pattern}" "${filename}" || true
      found_violations=1
    fi
  done
fi

if [ $found_violations -eq 1 ]; then
  echo ""
  echo "Found database.schema.table references with dev/int/prod databases."
  echo "Please use parameterized database names or environment variables instead."
  exit 1
fi
