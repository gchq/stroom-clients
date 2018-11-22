#!/usr/bin/env bash
#
# A script to send log files to stroom

# Arguments managed using argbash. To re-generate install argbash and run:
# 'argbash send_to_stroom_args.m4 -o send_to_stroom_args.sh'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/send_to_stroom_args.sh

# Create references to the args
readonly LOG_DIR=${_arg_log_dir}
readonly FEED=${_arg_feed}
readonly SYSTEM=${_arg_system}
readonly ENVIRONMENT=${_arg_environment}
readonly STROOM_URL=${_arg_stroom_url}
readonly SECURE=${_arg_secure}
readonly CERT=${_arg_cert}
readonly CERT_TYPE=${_arg_cert_type}
readonly KEY=${_arg_key}
readonly KEY_TYPE=${_arg_key_type}
readonly CACERT=${_arg_cacert}
readonly MAX_SLEEP=${_arg_max_sleep}
readonly DELETE_AFTER_SENDING=${_arg_delete_after_sending}
readonly PRETTY=${_arg_pretty}
readonly FILE_REGEX=${_arg_file_regex:-.*/.*\.log}

# Configure other constants
readonly LOCK_FILE=${LOG_DIR}/$(basename "$0").lck
readonly SLEEP=$((RANDOM % (MAX_SLEEP+1)))
readonly THIS_PID=$$


echo_info() {
    echo -e "${INFO_PREFIX}${1}"
}

echo_warn() {
    echo -e "${WARN_PREFIX}${1}"
}

echo_error() {
    echo -e "${ERROR_PREFIX}${1}"
}

# Shell colour constants for use in 'echo -e'
setup_echo_colours() {
    # Exit the script on any error
    set -e
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
        RED='\e[0;31m'
        BOLD_RED='\e[1;31m'
        GREEN='\e[0;32m'
        YELLOW='\e[0;33m'
        BLUE='\e[0;34m'
        MAGENTA='\e[0;35m'
        CYAN='\e[0;36m'
        NC='\033[0m' # No Color
    fi
}

configure_curl() {
    CURL_OPTS=""
    if [ "${SECURE}" = "off" ]; then
        CURL_OPTS="${CURL_OPTS} -k"
        echo_info "Running in insecure mode where we do not check SSL certificates."
    fi
    
    if [ ! "x${CERT}" = "x" ]; then
        CURL_OPTS="${CURL_OPTS} --cert ${CERT}"

    fi

    if [ ! "x${KEY}" = "x" ]; then
        CURL_OPTS="${CURL_OPTS} --key ${KEY}"

        if [ ! "x${KEY_TYPE}" = "x" ]; then
            CURL_OPTS="${CURL_OPTS} --key-type ${KEY_TYPE}"
        fi
    fi

    if [ ! "x${CACERT}" = "x" ]; then
        CURL_OPTS="${CURL_OPTS} --cacert ${CACERT}"
    fi

    if [ ! "x${CERT}" = "x" ] || [ ! "x${CACERT}" = "x" ] ; then
        if [ ! "x${CERT_TYPE}" = "x" ]; then
            CURL_OPTS="${CURL_OPTS} --cert-type ${CERT_TYPE}"
        fi
    fi

    if [ ! "x${CURL_OPTS}" = "x" ]; then
        CURL_OPTS="${CURL_OPTS} "
    fi
}

validate_log_dir() {
    if [ ! -d "${LOG_DIR}" ]; then
        echo_warn "The supplied log-dir argument [${BLUE}${LOG_DIR}${NC}] does not exist, therefore there is nothing to send. Exiting."
        exit 0
    fi
}

get_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        LOCK_FILE_PID=$(head -n 1 "${LOCK_FILE}")
        if ps -p "$LOCK_FILE_PID" > /dev/null; then
            echo_warn "This script is already running is already running as ${CYAN}${LOCK_FILE_PID}${NC}! Exiting."
            exit 0
        else 
            echo_warn "Found old lock file! Did a previous run of this script fail? I will delete it and create a new one."
            echo_info "Creating a lock file for ${CYAN}${THIS_PID}${NC}"
            echo "$$" > "${LOCK_FILE}"
        fi
    else
        echo_info "Creating a lock file for ${CYAN}${THIS_PID}${NC}"
        echo "$$" > "${LOCK_FILE}"
    fi
}

send_files() {
    if [ ${MAX_SLEEP} -ne 0 ]; then
        echo_info "Will sleep for ${SLEEP}s to help balance network traffic"
        sleep ${SLEEP}
    fi

    # These lines are handy for debugging in the container
    #echo "FILE_REGEX: [${FILE_REGEX}]"
    #echo "Matched files:"
    #find "${LOG_DIR}" -regex "${FILE_REGEX}"
    #echo "All files:"
    #find "${LOG_DIR}"

    echo_info "Sending files to [${BLUE}${STROOM_URL}${NC}], headers [Feed:${BLUE}${FEED}${NC}, System:${BLUE}${SYSTEM}${NC}, Environment:${BLUE}${ENVIRONMENT}${NC}], curl options [${BLUE}${CURL_OPTS}${NC}]"

    # Loop over all files in the lock directory
    for file in ${LOG_DIR}/*; do
        #echo "file: ${file}"

        # Ignore the lock file and check the file matches the pattern and is a regular file
        if [[ ! "x${file}" = "x${LOCK_FILE}" ]] && [[ -f ${file} ]] && [[ "${file}" =~ ${FILE_REGEX} ]]; then
            #echo "matched file: ${file}"
            send_file "${file}" 
        fi
    done

    rm "${LOCK_FILE}"
}

send_file() {
    local -r file=$1
    echo_info "Sending file ${BLUE}${file}${NC}"

    RESPONSE_HTTP=$(curl \
        ${CURL_OPTS} \
        --silent \
        --show-error \
        --write-out "RESPONSE_CODE=%{http_code}" \
        --data-binary @${file} ${STROOM_URL} \
        -H "Feed:${FEED}" \
        -H "System:${SYSTEM}" \
        -H "Environment:${ENVIRONMENT}" \
        2>&1 || true)

    #echo -e "RESPONSE_HTTP: [${RESPONSE_HTTP}]"

    RESPONSE_CODE="$(echo "${RESPONSE_HTTP}" | grep -o -e "RESPONSE_CODE=.*$" | cut -f2 -d '=')"
    RESPONSE_MSG="$(echo "${RESPONSE_HTTP}" |  grep -v "RESPONSE_CODE=" || true)"

    #echo "RESPONSE_LINE: [${RESPONSE_LINE}]"
    #echo "RESPONSE_CODE: [${RESPONSE_CODE}]"

    if [ "${RESPONSE_CODE}" != "200" ]
    then
        echo_error "Unable to send file ${BLUE}${file}${NC}, response code was: ${BLUE}${RESPONSE_CODE}${NC}, error was :\n${RESPONSE_MSG}"
    else
        echo_info "Sent file ${BLUE}${file}${NC}, response code was ${BLUE}${RESPONSE_CODE}${NC}"

        if [ "${DELETE_AFTER_SENDING}" = "on" ]; then
            echo_info "Deleting successfully sent file ${BLUE}${file}${NC}"
            rm "${file}"
        fi
    fi
}

main() {
    setup_echo_colours

    # Define echo prefixes for consistent log messages
    # INFO=blue, WARN=RED, ERROR=BOLD_RED is consistent with logback colour highlighting
    readonly BASE_PREFIX="[$(date +'%Y-%m-%dT%H:%M:%S.%3NZ')] [${YELLOW}${FEED}${NC}] [${CYAN}${THIS_PID}${NC}] "
    readonly INFO_PREFIX="${BLUE}INFO${NC}   ${BASE_PREFIX}"
    readonly WARN_PREFIX="${RED}WARN${NC}   ${BASE_PREFIX}"
    readonly ERROR_PREFIX="${BOLD_RED}ERROR${NC}  ${BASE_PREFIX}"

    # For debugging all log levels
    #echo_info "This is an info test"
    #echo_warn "This is an warn test"
    #echo_error "This is an error test"

    validate_log_dir
    configure_curl
    get_lock
    send_files
}

main "$@"
