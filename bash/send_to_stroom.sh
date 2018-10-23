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
readonly MAX_SLEEP=${_arg_max_sleep}
readonly DELETE_AFTER_SENDING=${_arg_delete_after_sending}
readonly PRETTY=${_arg_pretty}
readonly FILE_REGEX=${_arg_file_regex}

## Configure other constants
readonly LOCK_FILE=${LOG_DIR}/$(basename "$0").lck
readonly SLEEP=$((RANDOM % (MAX_SLEEP+1)))
readonly THIS_PID=$$

# Shell colour constants for use in 'echo -e'
setup_echo_colours() {
    # Exit the script on any error
    set -e
    if [ "${PRETTY}" = "off" ]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        LGREY=''
        DGREY=''
        NC='' # No Color
    else
        RED='\033[1;31m'
        GREEN='\033[1;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[1;34m'
        LGREY='\e[37m'
        DGREY='\e[90m'
        NC='\033[0m' # No Color
    fi
}

configure_curl() {
    if [ "${SECURE}" = "false" ]; then
        CURL_OPTS="-k "
        echo -e "${YELLOW}Warn:${NC} Running in insecure mode where we do not check SSL certificates. CURL_OPTS=${CURL_OPTS}"
    else
        CURL_OPTS=""
    fi
}

get_lock() {
    if [ -f "${LOCK_FILE}" ]; then
        LOCK_FILE_PID=$(head -n 1 "${LOCK_FILE}")
        if ps -p "$LOCK_FILE_PID" > /dev/null
        then
            echo -e "${RED}Error:${NC} This script is already running is already running as ${LOCK_FILE_PID}! Exiting."
            exit 0
        else 
            echo -e "${YELLOW}Warn:${NC} Found old lock file! Did a previous run of this script fail? I will delete it and create a new one."
            echo -e "${GREEN}Info:${NC} Creating a lock file for ${THIS_PID}"
            echo "$$" > "${LOCK_FILE}"
        fi
    else
        echo -e "${GREEN}Info:${NC} Creating a lock file for ${THIS_PID}"
        echo "$$" > "${LOCK_FILE}"
    fi
}

send_files() {
    echo -e "${GREEN}Info:${NC} Will sleep for ${SLEEP}s to help balance network traffic"
    sleep ${SLEEP}

    echo "${FILE_REGEX}"

    # These lines are handy for debugging in the container
    #echo "Matched files:"
    #find "${LOG_DIR}" -regextype posix-egrep -regex "${FILE_REGEX}"
    #echo "All files:"
    #find "${LOG_DIR}"

    while IFS= read -r -d '' file
    do
        send_file "$file"
    done <   <(find "${LOG_DIR}" -regextype posix-egrep -regex "${FILE_REGEX}" -print0)

    rm "${LOCK_FILE}"
}

send_file() {
    local -r file=$1
    echo -e "\n${GREEN}Info:${NC} Processing ${file}"
    RESPONSE_HTTP=$(curl ${CURL_OPTS} --write-out "RESPONSE_CODE=%{http_code}" --data-binary @${file} ${STROOM_URL} -H "Feed:${FEED}" -H "System:${SYSTEM}" -H "Environment:${ENVIRONMENT}" 2>&1)
    RESPONSE_LINE=$(echo "${RESPONSE_HTTP}" | head -1)
    RESPONSE_MSG=$(echo "${RESPONSE_HTTP}" | grep -o -e "RESPONSE_CODE=.*$")
    RESPONSE_CODE=$(echo "${RESPONSE_MSG}" | cut -f2 -d '=')
    if [ "${RESPONSE_CODE}" != "200" ]
    then
        echo -e "${RED}Error:${NC} Unable to send file ${file}, error was: \n${RESPONSE_HTTP}"
    else
        echo -e "${GREEN}Info:${NC} Sent file ${file}, response code was ${RESPONSE_CODE}"

        if [ "${DELETE_AFTER_SENDING}" = "on" ]; then
            echo -e "${YELLOW}Warn:${NC} Deleting successfully sent file ${file}"
            rm "${file}"
        fi
    fi
}

main() {
    setup_echo_colours
    echo -e "\n${GREEN}Welcome to the send_to_stroom.sh script${NC}"
    echo -e "This script sends log files to Stroom.\n"

    configure_curl
    get_lock
    send_files
}

main "$@"
