#!/usr/bin/env bash

##########################################################################
# Copyright 2020 Crown Copyright
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

# A script to send log files to stroom

# Arguments managed using argbash. To re-generate install argbash and run:
# 'argbash send_to_stroom_args.m4 -o send_to_stroom_args.sh'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source "${DIR}/send_to_stroom_args.sh"

# shellcheck disable=SC2154
{
  # Create references to the args
  readonly LOG_DIR=${_arg_log_dir}
  readonly FEED=${_arg_feed}
  readonly STROOM_URL=${_arg_stroom_url}
  # Each -H arg is added into an array
  readonly HEADERS_ARR=( "${_arg_header[@]}" )
  readonly SYSTEM=${_arg_system}
  readonly ENVIRONMENT=${_arg_environment}
  readonly SECURE=${_arg_secure}
  readonly CERT=${_arg_cert}
  readonly CERT_TYPE=${_arg_cert_type}
  readonly KEY=${_arg_key}
  readonly KEY_TYPE=${_arg_key_type}
  readonly CACERT=${_arg_cacert}
  readonly MAX_SLEEP=${_arg_max_sleep}
  readonly DELETE_AFTER_SENDING=${_arg_delete_after_sending}
  readonly PRETTY=${_arg_pretty}
  readonly COMPRESS=${_arg_compress}
  readonly DEBUG=${_arg_debug}
  readonly FILE_REGEX=${_arg_file_regex:-.*/.*\.log}
  readonly EXTRA_HEADERS_FILE=${_arg_headers}
  readonly TOKEN_ENDPOINT=${_arg_token_endpoint}
  readonly TOKEN_CLIENT_APP_ID=${_arg_token_client_app_id}
  readonly TOKEN_STROOM_APP_ID=${_arg_token_stroom_app_id}
  readonly TOKEN_CLIENT_SECRET_FILENAME=${_arg_token_client_secret_filename}
}

# Configure other constants
readonly LOCK_FILE=${LOG_DIR}/$(basename "$0").lck
readonly SLEEP=$((RANDOM % (MAX_SLEEP+1)))
readonly THIS_PID=$$

# Stroom reserved header tokens
# see https://gchq.github.io/stroom-docs/user-guide/sending-data/header-arguments.html
readonly HEADER_TOKEN_FEED="Feed"
readonly HEADER_TOKEN_SYSTEM="System"
readonly HEADER_TOKEN_ENVIRONMENT="Environment"
readonly HEADER_TOKEN_COMPRESSION="Compression"

# Valid values for the Compression header token
readonly COMPRESSION_HEADER_TYPE_GZIP="GZIP"
readonly COMPRESSION_HEADER_TYPE_ZIP="ZIP"

# HTTP standard reserved header tokens
# Content-Encoding conflicts with our Compression header token. If both are
# set then both stroom and the underlying web server will try to un-compress
# the data, leading to stroom trying to un-compress already un-compressed data.
# Therefore if this token is found in the headers file it will be ignored.
readonly HEADER_TOKEN_CONTENT_ENCODING="Content-Encoding"

is_compression_required=false
is_supported_compressed_file=false

echo_debug() {
  if [ "${DEBUG}" = "on" ]; then
    echo -e "${DEBUG_PREFIX}" "$@"
  fi
}

echo_info() {
  echo -e "${INFO_PREFIX}" "$@"
}

echo_warn() {
  echo -e "${WARN_PREFIX}" "$@"
}

echo_error() {
  echo -e "${ERROR_PREFIX}" "$@"
}

# Shell colour constants for use in 'echo -e'
setup_echo_colours() {
  # Exit the script on any error
  set -e
  # shellcheck disable=SC2034
  if [ "${PRETTY}" = "off" ]; then
    RED=''
    BOLD_RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    NC='' # No Color
  else
    RED='\033[0;31m'
    BOLD_RED='\033[1;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
  fi
}

# Returns 0 if the key portion of header $1 is a key in the array of 
# elements passed as subsequent args
# e.g. 
# arr=( "key1:val1" "key2:val1" "key3:val1" )
# header_in "key2" "${arr[@]}" # returns 0
header_in () {
  local header 
  local header_key
  # Get the first arg, the match, then remove it from the arg list
  local match="$1"
  # extract the key from key:value
  local match_key="${match%:*}"
  shift
  # implicitly iterate over the arg list
  for header; do 
    # extract the key from key:value
    header_key="${header%:*}"
    [[ "${header_key}" == "${match_key}" ]] && return 0
  done
  return 1
}

configure_curl_security() {
  curl_opts=()
  if [ "${SECURE}" = "off" ]; then
    curl_opts+=(-k)
    echo_info "Running in insecure mode where we do not check SSL certificates."
  fi

  if [ ! "x${CERT}" = "x" ]; then
    curl_opts+=(--cert "${CERT}")

  fi

  if [ ! "x${KEY}" = "x" ]; then
    curl_opts+=(--key "${KEY}")

    if [ ! "x${KEY_TYPE}" = "x" ]; then
      curl_opts+=(--key-type "${KEY_TYPE}")
    fi
  fi

  if [ ! "x${CACERT}" = "x" ]; then
    curl_opts+=(--cacert "${CACERT}")
  fi

  if [ ! "x${CERT}" = "x" ] || [ ! "x${CACERT}" = "x" ] ; then
    if [ ! "x${CERT_TYPE}" = "x" ]; then
      curl_opts+=(--cert-type "${CERT_TYPE}")
    fi
  fi
}

add_curl_header_arg() {
  local header_line=

  if [ "$#" -eq 2 ]; then
    local header_token="$1"
    local header_value="$2"
    header_line="${header_token}:${header_value}"
  else
    header_line="$1"
  fi

  echo_debug "Adding header [${YELLOW}${header_line}${NC}]"
  curl_headers+=(-H "${header_line}")
}

add_file_specific_curl_header_arg() {
  local header_line=

  if [ "$#" -eq 2 ]; then
    local header_token="$1"
    local header_value="$2"
    header_line="${header_token}:${header_value}"
  else
    header_line="$1"
  fi

  echo_debug "Adding header [${header_line}]"
  file_specific_curl_headers+=(-H "${header_line}")
}

configure_curl_headers() {
  curl_headers=()

  # These ones are special as we always need them and they will trump
  # any of the same name in the file
  add_curl_header_arg "${HEADER_TOKEN_FEED}" "${FEED}"

  # Turn --system arg into a curl header arg
  if [[ -n "${SYSTEM}" ]]; then
    if header_in "${HEADER_TOKEN_SYSTEM}:${SYSTEM}" "${HEADERS_ARR[@]}"; then
      echo_error "The ${YELLOW}--system${NC} argument has been set in addition to the" \
        "${YELLOW}-H/--header ${HEADER_TOKEN_SYSTEM}:...${NC} argument. Use one or the other."
      exit 1
    fi
    add_curl_header_arg "${HEADER_TOKEN_SYSTEM}" "${SYSTEM}"
  fi

  # Turn --environment arg into a curl header arg
  if [[ -n "${ENVIRONMENT}" ]]; then
    if header_in "${HEADER_TOKEN_ENVIRONMENT}:${ENVIRONMENT}" "${HEADERS_ARR[@]}"; then
      echo_error "The ${YELLOW}--environment${NC} argument has been set in addition to the" \
        "${YELLOW}-H/--header ${HEADER_TOKEN_SYSTEM}:...${NC} argument. Use one or the other."
      exit 1
    fi
    add_curl_header_arg "${HEADER_TOKEN_ENVIRONMENT}" "${ENVIRONMENT}"
  fi

  # If using OIDC token authentication, create the token
  if check_oidc_token_args_present; then
    get_oidc_token_from_idp
  fi

  for header in "${HEADERS_ARR[@]}"; do
    add_curl_header_arg "${header}"
  done

  if [ ! "x${EXTRA_HEADERS_FILE}" = "x" ]; then
    while read line; do
      if [[ "${line}" =~ ^(${HEADER_TOKEN_FEED}|${HEADER_TOKEN_COMPRESSION}|${HEADER_TOKEN_CONTENT_ENCODING}):.* ]]; then
        echo_warn "Additional header [${YELLOW}${line}${NC}] in the" \
          "file ${BLUE}${EXTRA_HEADERS_FILE}${NC} uses a reserved" \
          "token so will be ignored"
      elif header_in "${line}" "${HEADERS_ARR[@]}"; then
        echo_warn "Additional header [${YELLOW}${line}${NC}] in the" \
          "file ${BLUE}${EXTRA_HEADERS_FILE}${NC} is trumped by an additional" \
          "header argument so will be ignored"
      elif [[ "${line}" =~ ^${HEADER_TOKEN_SYSTEM}:.* ]] \
        && [[ -n "${SYSTEM}" ]] ; then

        echo_warn "Additional ${HEADER_TOKEN_SYSTEM} header" \
          "[${YELLOW}${line}${NC}] in the" \
          "file ${BLUE}${EXTRA_HEADERS_FILE}${NC} is trumped by the ${YELLOW}--system${NC}" \
          "argument so will be ignored"
      elif [[ "${line}" =~ ^${HEADER_TOKEN_ENVIRONMENT}:.* ]] \
        && [[ -n "${ENVIRONMENT}" ]] ; then

        echo_warn "Additional ${HEADER_TOKEN_ENVIRONMENT} header" \
          "[${YELLOW}${line}${NC}] in the" \
          "file ${BLUE}${EXTRA_HEADERS_FILE}${NC} is trumped by the ${YELLOW}--environment${NC}" \
          "argument so will be ignored"
      else
        add_curl_header_arg "${line}"
      fi
    done < "${EXTRA_HEADERS_FILE}"
  fi
}

validate_log_dir() {
  if [ ! -d "${LOG_DIR}" ]; then
    echo_warn "The supplied directory for the '${YELLOW}log-dir${NC}'" \
      "argument [${BLUE}${LOG_DIR}${NC}] does not exist, therefore there" \
      "is nothing to send. Exiting."
    exit 0
  fi
}

validate_extra_headers_file() {
  if [ ! "x${EXTRA_HEADERS_FILE}" = "x" ]; then
    if [ ! -f "${EXTRA_HEADERS_FILE}" ]; then
      echo_error "The supplied file for the '${YELLOW}-h/--headers${NC}'" \
        "argument [${BLUE}${EXTRA_HEADERS_FILE}${NC}] does not exist. Exiting."
      exit 1
    fi
  fi
}

get_lock() {
  if [ -f "${LOCK_FILE}" ]; then
    LOCK_FILE_PID=$(head -n 1 "${LOCK_FILE}")
    if ps -p "$LOCK_FILE_PID" > /dev/null; then
      echo_warn "This script is already running is already running" \
        "as ${CYAN}${LOCK_FILE_PID}${NC}! Exiting."
      exit 0
    else 
      echo_warn "Found old lock file! Did a previous run of this script" \
        "fail? I will delete it and create a new one."
      echo_info "Creating a lock file for ${CYAN}${THIS_PID}${NC}"
      echo "$$" > "${LOCK_FILE}"
    fi
  else
    echo_info "Creating a lock file for ${CYAN}${THIS_PID}${NC}"
    echo "$$" > "${LOCK_FILE}"
  fi
}

is_file_not_empty() {
  local -r file="$1"

  local -r filename="$(basename -- "${file}")"
  local -r extension="$( \
    [[ "$filename" = *.* ]] && echo ".${filename##*.}" || echo '')"

  echo_debug "Checking if file is empty for file:" \
    "[${file}], filename: [${filename}], extension: [${extension}]"

  local is_not_empty=true

  header_value="${COMPRESSION_HEADER_TYPE_GZIP}"
  if [[ "${extension}" =~ \.(gz|GZ)$ ]] ; then
    # Gunzup to stdout, get first one bytes then get lenght of that
    # in bytes
    if [[ $(gunzip -c "${file}" | head -c1 | wc -c) == "0" ]]; then
        is_not_empty=false
    fi
  elif [[ "${extension}" =~ \.(zip|ZIP)$ ]]; then
    # And empty zip archive is always exactly 22 bytes so test for this
    if [[ $(wc -c < "${file}") = "22" ]]; then
        is_not_empty=false
    fi
  else
    # Not a compressed file so just see if it is non-empty
    if [[ ! -s "${file}" ]]; then
        is_not_empty=false
    fi
  fi

  if [[ "${is_not_empty}" = true ]]; then
    echo_debug "Non-empty file: ${file}"
    return 0
  else
    echo_debug "Empty file: ${file}"
    return 1
  fi
}

send_files() {
  if [ "${MAX_SLEEP}" -ne 0 ]; then
    echo_info "Will sleep for ${SLEEP}s to help balance network traffic"
    sleep ${SLEEP}
  fi

    # Build a string of the headers array
    local headers_text=""
    for elm in "${curl_headers[@]}"; do
      if [[ ! "${elm}" = "-H" ]]; then
        # Capture the two parts of the header line
        # Remove from colon onwards
        header_token="${elm%:*}"
        # Remove up to and including colon
        header_value="${elm#*:}"

        # Concat this header with the others, adding some colour
        headers_text="${headers_text}, ${header_token}:${YELLOW}${header_value}${NC}"
      fi
    done
    # Remove any leading comma followed by a space
    headers_text="${headers_text#, }"
    #headers_text="$(echo "${headers_text}" | sed 's/^, //')"

    local curl_opts_text=""
    for elm in "${curl_opts[@]}"; do
      if [[ ! "${elm}" = "-H" ]]; then
        #local decorated_header=$(echo "${elm}" | sed -e "s/:\(.*\)/:${YELLOW}\1${NC}/")
        # Capture the two parts
        curl_opts_text="${curl_opts_text} ${elm}"
      fi
    done
    # Remove any leading space
    curl_opts_text="${curl_opts_text# }"

    echo_info "Sending matching files to [${BLUE}${STROOM_URL}${NC}]"
    echo_info "Sending headers [${headers_text}]"
    echo_info "Using curl options [${BLUE}${curl_opts_text}${NC}]"

    echo_debug "FILE_REGEX: [${YELLOW}${FILE_REGEX}${NC}]"

    local file_match_count=0

    # Loop over all files in the log directory
    for file in ${LOG_DIR}/*; do
      # Ignore the lock file and check the file matches the pattern and is a
      # regular file
      if [[ ! "x${file}" = "x${LOCK_FILE}" ]] \
        && [[ -f ${file} ]] \
        && [[ "${file}" =~ ${FILE_REGEX} ]]; then

        if is_file_not_empty "${file}"; then
          #echo "matched file: ${file}"
          file_match_count=$((file_match_count + 1))
          send_file "${file}" 
        else
          echo_info "Ignoring empty file ${BLUE}${file}${NC}"
          delete_file_if_enabled "${file}"
        fi
      else
        echo_debug "Ignoring file ${BLUE}${file}${NC}"
      fi
    done

    echo_info "File path regex [${YELLOW}${FILE_REGEX}${NC}] matched" \
      "${file_match_count} file(s) in ${BLUE}${LOG_DIR}${NC}"

    echo_info "Deleting lock file for ${CYAN}${THIS_PID}${NC}"
    rm "${LOCK_FILE}" \
      || (echo_error "Unable to delete lock file ${BLUE}${LOCK_FILE}${NC}" && exit 1)
  }

add_compression_header_if_required() {
  local -r file=$1
  local -r filename="$(basename -- "${file}")"
  local -r extension="$( \
    [[ "$filename" = *.* ]] && echo ".${filename##*.}" || echo '')"
  echo_debug "Establishing compression header for file:" \
    "[${file}], filename: [${filename}], extension: [${extension}]"

  local header_value=""

  if [[ "${extension}" =~ \.(gz|GZ)$ ]] ; then
    header_value="${COMPRESSION_HEADER_TYPE_GZIP}"
    is_compression_required=false
    is_supported_compressed_file=true
  elif [[ "${extension}" =~ \.(zip|ZIP)$ ]]; then
    header_value="${COMPRESSION_HEADER_TYPE_ZIP}"
    is_compression_required=false
    is_supported_compressed_file=true
  elif [ "${COMPRESS}" = "on" ]; then
    # Not a compressed file but compression is on so we will compress with gzip
    header_value="${COMPRESSION_HEADER_TYPE_GZIP}"
    is_compression_required=true
    is_supported_compressed_file=false
  fi

  echo_debug "is_compression_required: ${is_compression_required}"
  echo_debug "is_supported_compressed_file: ${is_supported_compressed_file}"

  if [ ! "x${header_value}" = "x" ]; then
    add_file_specific_curl_header_arg \
      "${HEADER_TOKEN_COMPRESSION}" \
      "${header_value}"
  fi
}

dump_header_args_in_debug() {
  if [ "${DEBUG}" = "on" ]; then
    echo_debug "Dumping curl HTTP header args: [${YELLOW}" \
      "${curl_headers[@]}" \
      "${file_specific_curl_headers[@]}" \
      "${NC}]"
  fi
}

get_oidc_token_from_idp() {

  #Secret is retained in a file as command-line args are public
  if [[ -f ${TOKEN_CLIENT_SECRET_FILENAME} ]]; then
    echo_debug "Reading client secret from ${TOKEN_CLIENT_SECRET_FILENAME}."
  else
    echo_error "FATAL: Client secret file ${TOKEN_CLIENT_SECRET_FILENAME} not found or not a regular file."
    exit 1
  fi

  TOKEN_CLIENT_SECRET=$(cat ${TOKEN_CLIENT_SECRET_FILENAME} | tr '\n' '¬' | sed 's/¬//g' )
  echo_debug "Using client secret ${TOKEN_CLIENT_SECRET}"

  OIDC_OUTPUT=$(curl -q ${TOKEN_ENDPOINT} -H "Content-Type: application/x-www-form-urlencoded" \
    --data "grant_type=client_credentials&client_id=${TOKEN_CLIENT_APP_ID}&\
    client_secret=${TOKEN_CLIENT_SECRET}&\
    resource=${TOKEN_STROOM_APP_ID}" )

  echo_debug "OIDC result: ${OIDC_OUTPUT}"
}

check_oidc_token_args_present() {
  if [ "x${TOKEN_ENDPOINT}${TOKEN_CLIENT_APP_ID}${TOKEN_STROOM_APP_ID}${TOKEN_CLIENT_SECRET_FILENAME}" = "x" ]; then
    false
  elif [ "x${TOKEN_ENDPOINT}" = "x" ]; then
    echo_error "FATAL: Unable to use OIDC authentation unless all 4 token_* parameters are set."
    exit 1
  elif [ "x${TOKEN_CLIENT_APP_ID}" = "x" ]; then
    echo_error "FATAL: Unable to use OIDC authentation unless all 4 token_* parameters are set."
    exit 1
  elif [ "x${TOKEN_STROOM_APP_ID}" = "x" ]; then
    echo_error "FATAL: Unable to use OIDC authentation unless all 4 token_* parameters are set."
    exit 1
  elif [ "x${TOKEN_CLIENT_SECRET_FILENAME}" = "x" ]; then
    echo_error "FATAL: Unable to use OIDC authentation unless all 4 token_* parameters are set."
    exit 1
  else
    echo_debug "OIDC token authentication parameters provided."
    true
  fi
}

delete_file_if_enabled() {
  local -r file="$1"
  if [ "${DELETE_AFTER_SENDING}" = "on" ]; then
    echo_info "Deleting file ${BLUE}${file}${NC}"
    rm "${file}" \
      || (echo_error "Unable to delete file ${BLUE}${file}${NC}" && exit 1)
  fi
}

send_file() {
  local -r file="$1"

  # clear out any values from a previous file
  local file_specific_curl_headers=()

  add_compression_header_if_required "${file}"

  # Construct the curl command. We have to use bash arrays for curl_opts and
  # curl_headers to deal with quotes and spaces correctly. Curl 7.55.0 can
  # take a single headers file as an arg to save all the messing about
  # parsing the file, but at the time of writing, I only had 7.47.0.
  if [ "${is_compression_required}" = true ]; then
    echo_info "Sending file ${BLUE}${file}${NC} using gzip compression"
    dump_header_args_in_debug

    RESPONSE_HTTP=$( \
      # We are compressing so pipe output of gzip to curl and get curl to read from stdin
      # gzip's '--stdout' arg is not supported on alpine so use '-c' instead
      gzip -c "${file}" | \
        curl \
        "${curl_opts[@]}" \
        --silent \
        --show-error \
        --write-out "RESPONSE_CODE=%{http_code}" \
        --data-binary @- \
        "${curl_headers[@]}" \
        "${file_specific_curl_headers[@]}" \
        "${STROOM_URL}" \
        2>&1 || true)
  else
    echo_info "Sending" \
      "$([ "${is_supported_compressed_file}" = true ] && echo "compressed ")" \
      "file ${BLUE}${file}${NC}"
    dump_header_args_in_debug

    RESPONSE_HTTP=$( \
    # no compression required so curl the file as is
      curl \
        "${curl_opts[@]}" \
        --silent \
        --show-error \
        --write-out "RESPONSE_CODE=%{http_code}" \
        --data-binary @"${file}" \
        "${curl_headers[@]}" \
        "${file_specific_curl_headers[@]}" \
        "${STROOM_URL}" \
        2>&1 || true)
  fi

  echo_debug "RESPONSE_HTTP: [${RESPONSE_HTTP}]"

  RESPONSE_CODE="$( \
    echo "${RESPONSE_HTTP}" \
      | grep -o -e "RESPONSE_CODE=.*$" \
      | cut -f2 -d '=')"
  RESPONSE_MSG="$( \
    echo "${RESPONSE_HTTP}" \
    | grep -v "RESPONSE_CODE=" \
    || true)"

  echo_debug "RESPONSE_LINE: [${RESPONSE_LINE}]"
  echo_debug "RESPONSE_CODE: [${RESPONSE_CODE}]"

  if [ "${RESPONSE_CODE}" != "200" ]
  then
    echo_error "Unable to send file ${BLUE}${file}${NC}, response code" \
      "was: ${RED}${RESPONSE_CODE}${NC}, error was :\n${RESPONSE_MSG}"
  else
    echo_info "Sent file ${BLUE}${file}${NC}, response code" \
      "was ${GREEN}${RESPONSE_CODE}${NC}"

    delete_file_if_enabled "${file}"
  fi
}

main() {
  setup_echo_colours

  # Define echo prefixes for consistent log messages
  # INFO=blue, WARN=RED, ERROR=BOLD_RED is consistent with logback colour highlighting
  # however they use defaul colour for other levels, here we use DEBUG=MAGENTA
  # Padding after INFO/WARN/ERROR consistent with our logback log format

  readonly DATE_PART="[$(date +'%Y-%m-%dT%H:%M:%S.%3NZ')]"
  readonly FEED_PART="[${YELLOW}${FEED}${NC}]"
  readonly PID_PART="[${CYAN}${THIS_PID}${NC}]"
  readonly BASE_PREFIX="${DATE_PART} ${FEED_PART} ${PID_PART}"
  readonly DEBUG_PREFIX="${MAGENTA}DEBUG${NC}  ${BASE_PREFIX}"
  readonly INFO_PREFIX="${BLUE}INFO${NC}   ${BASE_PREFIX}"
  readonly WARN_PREFIX="${RED}WARN${NC}   ${BASE_PREFIX}"
  readonly ERROR_PREFIX="${BOLD_RED}ERROR${NC}  ${BASE_PREFIX}"

  if [ "${DEBUG}" = "on" ]; then
    # For debugging all log levels
    echo_debug "This is a debug test"
    echo_info "This is an info test"
    echo_warn "This is a warn test"
    echo_error "This is an error test"
  fi

  validate_log_dir
  validate_extra_headers_file
  configure_curl_security
  configure_curl_headers
  get_lock
  send_files
}

main "$@"
# vim: set tabstop=2 shiftwidth=2 expandtab:
