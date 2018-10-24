#!/usr/bin/env bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.6.1
# ARG_OPTIONAL_BOOLEAN([secure], [s], [Check for valid certificates if running over HTTPS], off)
# ARG_OPTIONAL_BOOLEAN([delete-after-sending], [d], [Delete log files after sending them], off)
# ARG_OPTIONAL_BOOLEAN([pretty], [p], [Use colours in the output, it is recomended to disable this when sending the results to a log file], on)
# ARG_OPTIONAL_SINGLE([file-regex], [r], [The regex pattern used to match files that will be sent. E.g. '.*/\w\+-\d\+-\d\+-\d\+T.*\.log'. Regex is emacs syntax. If not set, all files in the directory will be sent.], ".*/.*\.log")
# ARG_OPTIONAL_SINGLE([max-sleep], [m], [Max time allowed to sleep (e.g. to avoid all cron's in the estate sending log files at the same time)], 0)
# ARG_POSITIONAL_SINGLE([log-dir], [Directory to look for log files],)
# ARG_POSITIONAL_SINGLE([feed], [ Your feed name given to you],)
# ARG_POSITIONAL_SINGLE([system], [Your system name, i.e. what your project/service or capability is known as], )
# ARG_POSITIONAL_SINGLE([environment], [Your environment name. Usually SITE_DEPLOYMENT], )
# ARG_POSITIONAL_SINGLE([stroom-url], [The URL you are sending data to (N.B. This should be the HTTPS URL)],)
# ARG_DEFAULTS_POS
# ARG_HELP([This script will send log files to Stroom.])
# ARG_VERSION([echo $0 v0.1])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO
