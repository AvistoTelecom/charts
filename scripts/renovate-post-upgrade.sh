#!/usr/bin/env bash
# Renovate post-upgrade task for one chart: bump the chart patch version (once per PR)
# and regenerate README/schema exactly like the pre-commit readme-generator hook.
# Usage: scripts/renovate-post-upgrade.sh charts/<name>

set -o errexit
set -o nounset
set -o pipefail

chart="$1"
chart_yaml="$chart/Chart.yaml"

chart_version() { grep -E '^version:' | head -n1 | awk '{print $2}' | tr -d '"'\'; }

current=$(chart_version <"$chart_yaml")
# Only bump if still at main's version, so re-running on an existing branch doesn't bump twice.
base=$(git show "origin/main:$chart_yaml" 2>/dev/null | chart_version) || base="$current"
if [[ "$current" == "$base" ]]; then
  IFS=. read -r major minor patch <<<"$current"
  sed -i "s/^version: .*/version: $major.$minor.$((patch + 1))/" "$chart_yaml"
fi

args=(--readme="$chart/README.md" --values="$chart/values.yaml")
[[ -f "$chart/values.schema.json" ]] && args+=(--schema="$chart/values.schema.json")
npx -y @bitnami/readme-generator-for-helm@2.7.0 "${args[@]}"
