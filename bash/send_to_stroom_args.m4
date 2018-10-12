#!/usr/bin/env bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.6.1
# ARG_OPTIONAL_BOOLEAN([secure], [s], [Check for valid certificates if running over HTTPS], false)
# ARG_OPTIONAL_BOOLEAN([delete_after_sending], [d], [Delete log files after sending them], false)
# ARG_OPTIONAL_BOOLEAN([no_pretty], [p], [Disable colours in the output, which is useful when sending the results to a log file], false)
# ARG_OPTIONAL_SINGLE([max_sleep], [m], [Max time allowed to sleep (e.g. to avoid all cron's in the estate sending log files at the same time)], 0)
# ARG_POSITIONAL_SINGLE([log_dir], [Directory to look for log files],)
# ARG_POSITIONAL_SINGLE([feed], [ Your feed name given to you],)
# ARG_POSITIONAL_SINGLE([system], [Your system name, i.e. what your project/service or capability is known as], )
# ARG_POSITIONAL_SINGLE([environment], [Your environment name. Usually SITE_DEPLOYMENT], )
# ARG_POSITIONAL_SINGLE([stroom_url], [The URL you are sending data to (N.B. This should be the HTTPS URL)],)
# ARG_DEFAULTS_POS
# ARG_HELP([This script will send log files to Stroom.])
# ARG_VERSION([echo $0 v0.1])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO
