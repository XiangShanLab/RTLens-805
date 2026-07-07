#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$SCRIPT_DIR"

PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_DIR="${VENV_DIR:-.venv}"
SLANG_REF="${SLANG_REF:-v10.0}"
SLANG_PREFIX="${SLANG_PREFIX:-.deps/slang}"
SLANG_SOURCE="${SLANG_SOURCE:-../slang}"
TARGET_OS="${TARGET_OS:-auto}"
JOBS="${JOBS:-}"

DO_NPM=1
DO_SLANG=1
DO_VERIFY=1
CLEAN_SLANG=0

usage() {
  cat <<'EOF'
Usage: ./init_env.sh [options]

Initialize the RTLens local development/runtime environment.

Options:
  --skip-npm       Skip third_party/elk npm install.
  --skip-slang     Skip standalone slang prefix setup.
  --skip-verify    Skip verify_install.py at the end.
  --clean-slang    Reconfigure/rebuild the slang CMake build directory.
  -h, --help       Show this help.

Environment overrides:
  PYTHON_BIN       Python executable used to create the venv (default: python3)
  VENV_DIR         Virtualenv directory (default: .venv)
  SLANG_REF        slang git ref used by setup script (default: v10.0)
  SLANG_PREFIX     slang install prefix (default: .deps/slang)
  SLANG_SOURCE     slang source checkout path (default: ../slang)
  TARGET_OS        verify target OS: auto/linux/windows/mac (default: auto)
  JOBS             Parallel build jobs for slang.

Examples:
  ./init_env.sh
  ./init_env.sh --skip-slang
  JOBS=8 ./init_env.sh --clean-slang
EOF
}

log() {
  printf '\n[init_env] %s\n' "$*"
}

die() {
  printf '\n[init_env][ERROR] %s\n' "$*" >&2
  exit 1
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-npm)
      DO_NPM=0
      ;;
    --skip-slang)
      DO_SLANG=0
      ;;
    --skip-verify)
      DO_VERIFY=0
      ;;
    --clean-slang)
      CLEAN_SLANG=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

case "$TARGET_OS" in
  auto|linux|windows|mac) ;;
  *) die "TARGET_OS must be one of: auto, linux, windows, mac" ;;
esac

[[ -f pyproject.toml ]] || die "run this script from the RTLens repository root"

if ! have_cmd "$PYTHON_BIN"; then
  die "Python executable not found: $PYTHON_BIN"
fi

PY_VERSION="$("$PYTHON_BIN" - <<'PY'
import sys
print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
)" || die "Python 3.10+ is required; $PYTHON_BIN reports ${PY_VERSION:-unknown}"
log "Using Python $PY_VERSION via $PYTHON_BIN"

if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  log "Creating virtualenv at $VENV_DIR"
  "$PYTHON_BIN" -m venv "$VENV_DIR"
else
  log "Reusing virtualenv at $VENV_DIR"
fi

VENV_PY="$VENV_DIR/bin/python"

log "Installing Python package and development dependencies"
"$VENV_PY" -m pip install --upgrade pip setuptools wheel
"$VENV_PY" -m pip install -e ".[dev]"

if [[ "$DO_NPM" -eq 1 ]]; then
  have_cmd npm || die "npm is required for third_party/elk; install node/npm or rerun with --skip-npm"
  log "Installing ELK JavaScript dependencies"
  npm --prefix third_party/elk ci
else
  log "Skipping npm install"
fi

if [[ "$DO_SLANG" -eq 1 ]]; then
  have_cmd cmake || die "cmake is required for slang setup"
  have_cmd git || die "git is required for slang setup"
  have_cmd g++ || die "g++ is required for slang setup"

  log "Preparing standalone slang prefix at $SLANG_PREFIX (ref: $SLANG_REF)"
  slang_args=(
    "rtlens/tools/setup_slang_prefix.py"
    "--clone-if-missing"
    "--slang-ref" "$SLANG_REF"
    "--checkout-ref"
    "--prefix" "$SLANG_PREFIX"
    "--slang-source" "$SLANG_SOURCE"
  )
  if [[ "$CLEAN_SLANG" -eq 1 ]]; then
    slang_args+=("--clean")
  fi
  if [[ -n "$JOBS" ]]; then
    slang_args+=("--jobs" "$JOBS")
  fi
  "$VENV_PY" "${slang_args[@]}"
else
  log "Skipping slang setup"
fi

if [[ "$SLANG_PREFIX" = /* ]]; then
  export SVVIEW_SLANG_ROOT="$SLANG_PREFIX"
else
  export SVVIEW_SLANG_ROOT="$SCRIPT_DIR/$SLANG_PREFIX"
fi

if [[ "$DO_VERIFY" -eq 1 ]]; then
  log "Verifying installation"
  "$VENV_PY" rtlens/tools/verify_install.py --target-os "$TARGET_OS" --strict
else
  log "Skipping verification"
fi

log "Environment initialization complete"
printf '[init_env] Load environment with: source ./env.sh\n'
printf '[init_env] Launch sample: python -m rtlens --filelist RTL/verification/mid_case/vlist --top vm_mid_top\n'
