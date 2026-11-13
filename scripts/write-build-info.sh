#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_TREE="$ROOT/kernel_platform/xiaomi/sm8450"
INFO="$ROOT/build-info.txt"

revision() {
  local path="$1"
  if git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '%s' "$(git -C "$path" rev-parse HEAD)"
  else
    printf '%s' "unavailable"
  fi
}

{
  echo "Build metadata"
  echo "=============="
  echo "Target: marble"
  echo "Build type: ${BUILD_TYPE:-unknown}"
  echo "Workflow: ${GITHUB_WORKFLOW:-local}"
  echo "Run ID: ${GITHUB_RUN_ID:-local}"
  echo "Run attempt: ${GITHUB_RUN_ATTEMPT:-local}"
  echo "Commit: ${GITHUB_SHA:-unknown}"
  echo "Runner: ${RUNNER_OS:-unknown}"
  echo "Build UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "Clang: ${CLANG_DIR:-unknown}"
  echo "KernelSU variant: ${KSU_VARIANT:-unknown}"
  echo "KernelSU repository: ${KSU_REPO:-unknown}"
  echo "KernelSU ref: ${KSU_REF:-unknown}"
  echo "NoMount repository: ${NOMOUNT_REPO:-maxsteeel/nomount}"
  echo "NoMount ref: ${NOMOUNT_REF:-unknown}"
  echo
  echo "Manifest repository: $(revision "$ROOT/.repo/manifests")"
  echo
  echo "Synced source revisions"
  echo "-----------------------"
  echo "Kernel: $(revision "$KERNEL_TREE")"
  echo "Build tools: $(revision "$ROOT/kernel_platform/build")"
  echo "Device trees: $(revision "$ROOT/kernel_platform/xiaomi/sm8450-devicetrees")"
  echo "Vendor modules: $(revision "$ROOT/kernel_platform/xiaomi/sm8450-modules")"
  echo
  echo "Kernel configuration"
  echo "--------------------"
  if [ -f "$KERNEL_TREE/out/.config" ]; then
    grep -E '^(CONFIG_KSU|CONFIG_NOMOUNT|CONFIG_LTO_CLANG_FULL|CONFIG_LTO_NONE)=' "$KERNEL_TREE/out/.config" || true
  else
    echo "out/.config not found"
  fi
} > "$INFO"

if command -v repo >/dev/null 2>&1 && [ -d "$ROOT/.repo" ]; then
  (cd "$ROOT" && repo manifest -r -o "$ROOT/resolved-manifest.xml")
  echo "Wrote $ROOT/resolved-manifest.xml"
fi

echo "Wrote $INFO"
cat "$INFO"
