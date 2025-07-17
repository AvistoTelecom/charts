#!/usr/bin/env bash
# This script assert that `appVersion` in `Chart.yaml` is always consistent with the images in the chart's `values.yaml`

set -o errexit
set -o pipefail

# Check for yq dependency
if ! command -v yq >/dev/null 2>&1; then
  echo -e "\033[1;31mERROR: 'yq' is required but not installed. Please install yq and try again.\033[0m"
  exit 1
fi

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

# Declare dictionary: chart_folder => (yaml_path1 yaml_path2 ...)
declare -A CHART_PATHS
CHART_PATHS["kubebrowser"]="server.image.tag"
CHART_PATHS["raw"]=""
CHART_PATHS["wazuh-agent"]="agent.image.tag"
CHART_PATHS["cloudbeaver"]="image.tag"
# Add more as needed, space-separated for multiple paths

failed=0

# Collect all chart directories
for chart_dir in "$SCRIPT_ROOT"/charts/*/; do
  chart_name=$(basename "$chart_dir")
  chart_yaml="${chart_dir}Chart.yaml"
  values_yaml="${chart_dir}values.yaml"

  # Check if chart is in the dictionary
  if [[ -z "${CHART_PATHS[$chart_name]+_}" ]]; then
    print_red "[$chart_name] ERROR: Chart not referenced in dictionary."
    failed=1
    continue
  fi

  # Skip if no paths to check
  if [[ -z "${CHART_PATHS[$chart_name]}" ]]; then
    print_green "[$chart_name] SKIP: No paths to check."
    continue
  fi

  # Extract appVersion
  if [[ ! -f "$chart_yaml" ]]; then
    print_red "[$chart_name] ERROR: Chart.yaml not found."
    failed=1
    continue
  fi
  app_version=$(grep -E '^appVersion:' "$chart_yaml" | head -n1 | awk -F': ' '{print $2}' | tr -d '"'\'' ')
  if [[ -z "$app_version" ]]; then
    print_red "[$chart_name] ERROR: appVersion not found in Chart.yaml"
    failed=1
    continue
  fi

  # Check each path
  for path in ${CHART_PATHS[$chart_name]}; do
    if ! value=$(yq -r ".${path}" "$values_yaml" 2>/dev/null); then
      print_red "[$chart_name] ERROR: Failed to parse $path in values.yaml"
      failed=1
      continue
    fi
    if [[ -z "$value" ]]; then
      print_red "[$chart_name] ERROR: Path '$path' not found in values.yaml"
      failed=1
      continue
    fi
    if [[ "$value" != "$app_version" ]]; then
      print_red "[$chart_name] MISMATCH: appVersion ($app_version) != $path ($value)"
      failed=1
    else
      print_green "[$chart_name] OK: appVersion matches $path ($app_version)"
    fi
  done
done

if [[ $failed -ne 0 ]]; then
  print_red "One or more charts have errors or mismatches."
  exit 1
fi
