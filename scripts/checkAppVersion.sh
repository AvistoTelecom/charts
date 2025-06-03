#!/usr/bin/env bash

set -o errexit
set -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

LIGHT_GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

print_green() {
  echo -e "${LIGHT_GREEN}$1${RESET}"
}

print_red() {
  echo -e "${RED}$1${RESET}"
}

check_app_versions() {
  local failed=0
  for chart_dir in "$SCRIPT_ROOT"/charts/*/; do
    if [[ -f "${chart_dir}Chart.yaml" && -f "${chart_dir}values.yaml" ]]; then
      local app_version
      local tag_version

      # Extract appVersion from Chart.yaml
      app_version=$(grep -E '^appVersion:' "${chart_dir}Chart.yaml" | head -n1 | awk -F': ' '{print $2}' | tr -d '"'\'' ')

      # Extract first tag value from values.yaml (any nesting)
      tag_version=$(grep -E '^[[:space:]]*tag:' "${chart_dir}values.yaml" | head -n1 | awk -F': ' '{print $2}' | tr -d '"'\'' ')

      if [[ -z "$app_version" ]]; then
        print_red "[$(basename "$chart_dir")] Error: appVersion not found in Chart.yaml"
        failed=1
        continue
      fi

      if [[ -z "$tag_version" ]]; then
        print_red "[$(basename "$chart_dir")] Error: tag not found in values.yaml"
        failed=1
        continue
      fi

      if [[ "$app_version" != "$tag_version" ]]; then
        print_red "[$(basename "$chart_dir")] MISMATCH: appVersion ($app_version) != tag ($tag_version)"
        failed=1
      else
        print_green "[$(basename "$chart_dir")] OK: appVersion matches tag ($app_version)"
      fi
    fi
  done

  if [[ $failed -ne 0 ]]; then
    print_red "One or more charts have mismatched appVersion and tag."
    exit 1
  fi
}

check_app_versions
