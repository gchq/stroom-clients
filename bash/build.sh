#!/usr/bin/env bash
set -eo pipefail
IFS=$'\n\t'

#!/usr/bin/env bash

set -e

setup_echo_colours() {
  # Exit the script on any error
  set -e

  # shellcheck disable=SC2034
  if [ "${MONOCHROME}" = true ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BLUE2=''
    DGREY=''
    NC='' # No Colour
  else 
    RED='\033[1;31m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    BLUE2='\033[1;34m'
    DGREY='\e[90m'
    NC='\033[0m' # No Colour
  fi
}

debug_value() {
  local name="$1"; shift
  local value="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${name}: ${value}${NC}"
  fi
}

debug() {
  local str="$1"; shift
  
  if [ "${IS_DEBUG}" = true ]; then
    echo -e "${DGREY}DEBUG ${str}${NC}"
  fi
}

main() {
  script_version="$1"
  IS_DEBUG=false
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

  setup_echo_colours

  script_file="send_to_stroom.sh"
  template_file="send_to_stroom_args.m4"
  output_file="send_to_stroom_args.sh"

  # Use the args template to generate a script that send_to_stroom.sh
  # will source for arg parsing.
  "${SCRIPT_DIR}/runInDocker.sh" \
    "/builder/argbash/bin/argbash ${template_file} -o ${output_file}"

  echo -e "${GREEN}Generated file ${BLUE}${SCRIPT_DIR}/${output_file}${NC}"

  echo -e "${GREEN}Running shellcheck against ${BLUE}${SCRIPT_DIR}/${script_file}${NC}"

  # Run shellcheck to spot any bash mistakes
  "${SCRIPT_DIR}/runInDocker.sh" \
    "shellcheck ${script_file} ${output_file}"

  if [[ -n "${script_version}" ]]; then
    echo -e "${GREEN}Setting version to ${YELLOW}${script_version}${GREEN} in" \
      "${BLUE}${SCRIPT_DIR}/${output_file}${NC}"

    # This is a bit hacky but whatever value is set in the .m4 file is
    # baked into the _args.sh file in a few places. If you use a substitution
    # variable in the .m4 file then that is evaluated at run time, not build
    # time.
    sed \
      -i'' \
      "s/SNAPSHOT_VERSION/${script_version}/" \
      "${SCRIPT_DIR}/${output_file}"
  fi
}

main "$@"

