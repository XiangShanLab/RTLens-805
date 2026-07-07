#!/usr/bin/env bash
# Source this file from the RTLens repository root or any other directory:
#   source /path/to/RTLens/env.sh

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "env.sh must be sourced, not executed. Use: source ./env.sh" >&2
  exit 1
fi

_rtlens_env_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

export RTLENS_REPO_ROOT="$_rtlens_env_dir"
export VIRTUAL_ENV="${RTLENS_VENV_DIR:-$_rtlens_env_dir/.venv}"
export SVVIEW_SLANG_ROOT="${SVVIEW_SLANG_ROOT:-$_rtlens_env_dir/.deps/slang}"
export RTLENS_SLANG_ROOT="$SVVIEW_SLANG_ROOT"

case ":$PATH:" in
  *":$VIRTUAL_ENV/bin:"*) ;;
  *) export PATH="$VIRTUAL_ENV/bin:$PATH" ;;
esac

case ":$PATH:" in
  *":$RTLENS_REPO_ROOT/rtlens/bin:"*) ;;
  *) export PATH="$RTLENS_REPO_ROOT/rtlens/bin:$PATH" ;;
esac

case ":${PYTHONPATH:-}:" in
  *":$RTLENS_REPO_ROOT/rtlens:"*) ;;
  *)
    if [[ -n "${PYTHONPATH:-}" ]]; then
      export PYTHONPATH="$RTLENS_REPO_ROOT/rtlens:$PYTHONPATH"
    else
      export PYTHONPATH="$RTLENS_REPO_ROOT/rtlens"
    fi
    ;;
esac

unset _rtlens_env_dir
