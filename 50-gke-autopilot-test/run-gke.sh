#!/bin/bash

# Generic test wrapper for Standard -> Autopilot target switching.
# No customer-specific image, program ID, project, or storage path is stored here.

function print_usage() {
  echo "Usage: $0 <FROM_YYYYMMDD> <TO_YYYYMMDD> <CURR_YYYYMMDD> <CURR_HHMISS> <GPU> <CPU> <MEM_GB> <WORKING_DIRECTORY> <PROGRAM_PATH> [PROGRAM_PARAM ...]"
}

if [[ $# -lt 9 ]]; then
  print_usage
  exit 1
fi

export FROM_BASE_YMD="$1"; shift
export TO_BASE_YMD="$1"; shift
export CURR_YMD="$1"; shift
export CURR_TIME="$1"; shift
export VM_GPU="${1:-0}"; shift
export VM_CPU="${1:-1}"; shift
export VM_MEM="${1:-2}"; shift
export WORKING_DIRECTORY="$1"; shift
export PROGRAM_PATH="$1"; shift
export PROGRAM_PARAM="$*"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_COMMON="${CLIENT_COMMON:-/ssw/dlk/client_common}"
CLIENT_GKE="${CLIENT_GKE:-/ssw/dlk/client_gke}"
PROGRAM_ID="${PROGRAM_ID:-AUTOPILOT_TEST_001}"
DOCKER_IMAGE="${DOCKER_IMAGE:-}"

if [[ -z "$DOCKER_IMAGE" ]]; then
  echo "DOCKER_IMAGE is required. Export a test image URI at runtime." >&2
  exit 2
fi

if [[ ! -r "$CLIENT_COMMON" ]]; then
  echo "CLIENT_COMMON not readable: $CLIENT_COMMON" >&2
  echo "For repository-only test: export CLIENT_COMMON=$SCRIPT_DIR/client_common.test" >&2
  exit 2
fi

if [[ ! -x "$CLIENT_GKE" ]]; then
  echo "CLIENT_GKE not executable: $CLIENT_GKE" >&2
  echo "For repository-only test: chmod +x $SCRIPT_DIR/client_gke; export CLIENT_GKE=$SCRIPT_DIR/client_gke" >&2
  exit 2
fi

# shellcheck disable=SC1090
. "$CLIENT_COMMON"

LOG_TARGET_START="$FROM_BASE_YMD"
LOG_TARGET_END="$TO_BASE_YMD"

log_init "$PROGRAM_ID" "GKE" "$PROGRAM_ID"
log_act_init 1 1 "gke"

"$CLIENT_GKE" \
  --program-id "$PROGRAM_ID" \
  --docker-image "$DOCKER_IMAGE" \
  --gpu "$VM_GPU" \
  --cpu "$VM_CPU" \
  --mem-gb "$VM_MEM" \
  --shell-command "cd ${WORKING_DIRECTORY} && ${PROGRAM_PATH} ${PROGRAM_PARAM}"

RC=$?
chk_ret "$RC"
RET_VAL=$RC
log_success
exit "$RET_VAL"
