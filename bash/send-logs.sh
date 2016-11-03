	#!/bin/bash
	
	# YOU MUST SET the following (6) variables:
	
	# 1) Directory to look for log files
	LOG_DIR=testlogs
	# 2) Your feed name given to you.
	FEED="EXAMPLE_FEED"
	# 3) Your system name, i.e. what your project/service or capability is known as.
	SYSTEM="EXAMPLE_SYSTEM"
	# 4) Your environment name. Usually SITE_DEPLOYMENT. 
	ENVIRONMENT="EXAMPLE_ENVIRONMENT"
	# 5) The URL you are sending data to (N.B. This should be the HTTPS URL)
	STROOM_URL="https://<Stroom_HOST>/stroom/datafeed"
	
	
	# Script Constants
	
	# If running over HTTPS ensure that certificates are valid (possibly false for testing)
	SECURE=true
	# Max time allowed to sleep (e.g. to avoid all cron's in the estate sending log files at the same time)
	MAX_SLEEP=0
	
	# Script Constants
	LCK_FILE=${LOG_DIR}/`basename $0`.lck
	RANDOM=`echo $RANDOM`
	MOD=`expr $MAX_SLEEP + 1`
	SLEEP=`expr $RANDOM % $MOD`
	THIS_PID=`echo $$`
	
	
	if [ "${SECURE}" = "false" ]; then
	        CURL_OPTS="-k "
	        echo "Warn: Running in insecure mode where we do not check SSL certificates. CURL_OPTS=${CURL_OPTS}"
	else
	        CURL_OPTS=""
	fi
	
	
	if [ -f "${LCK_FILE}" ]; then
	        MYPID=`head -n 1 "${LCK_FILE}"`
	        TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`
	
	        if [ -z "${TEST_RUNNING}" ]; then
	                echo "Info: Obtained locked for ${THIS_PID}, processing directory ${LOG_DIR}"
	                echo "${THIS_PID}" > "${LCK_FILE}"
	        else
	                echo "Info: Sorry `basename $0` is already running[${MYPID}]"
	                exit 0
	        fi
	else
	        echo "Info: Obtained locked for ${THIS_PID}, processing directory ${LOG_DIR}"
	        echo "${THIS_PID}" > "${LCK_FILE}"
	fi
	
	echo "Info: Will sleep for ${SLEEP}s to help balance network traffic"
	sleep ${SLEEP}
	
	for FILE in `find $LOG_DIR -name '*.log'`
	do
	        echo "Info: Processing ${FILE}"
	        RESPONSE_HTTP=`curl ${CURL_OPTS} --write-out "RESPONSE_CODE=%{http_code}" --data-binary @${FILE} "${STROOM_URL}" -H "Feed:${FEED}" -H "System:${SYSTEM}" -H "Environment:${ENVIRONMENT}" 2>&1`
	        RESPONSE_LINE=`echo ${RESPONSE_HTTP} | head -1`
	        RESPONSE_MSG=`echo ${RESPONSE_HTTP} | grep -o -e RESPONSE_CODE=.*$`
	        RESPONSE_CODE=`echo ${RESPONSE_MSG} | cut -f2 -d '='`
	        if [ "${RESPONSE_CODE}" != "200" ]
	        then
	                msg_text="Error: Unable to send file ${FILE}, error was ${RESPONSE_LINE}"
	                echo ${msg_text}
	        else
	                echo "Info: Sent File ${FILE}, response code was ${RESPONSE_CODE}"
	               rm ${FILE}
	        fi
	done
	
	rm ${LCK_FILE}

