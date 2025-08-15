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

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.6.1
# ARG_OPTIONAL_REPEATED([header], [H], [Extra header in the form 'Key:value'. Any number of extra headers may be specified. These headers trump headers from the additional headers file.], )
# ARG_OPTIONAL_SINGLE([headers], , [File containing additional HTTP headers. In the form 'Key:value'], )
# ARG_OPTIONAL_BOOLEAN([secure], [s], [Check for valid certificates if running over HTTPS], off)
# ARG_OPTIONAL_BOOLEAN([delete-after-sending], [d], [Delete log files after sending them], off)
# ARG_OPTIONAL_BOOLEAN([pretty], [p], [Use colours in the output, it is recomended to disable this when sending the results to a log file], on)
# ARG_OPTIONAL_BOOLEAN([compress], [z], [Compress the data sent to stroom using gzip compression. This will set the required 'Compression:GZIP' header. The source log file will not be changed.], off)
# ARG_OPTIONAL_SINGLE([file-regex], [r], [The regex pattern used to match files that will be sent. E.g. '.*/[a-z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}T.*\\.log'. Regex syntax is that used in bash.], ".*/.*\\.log")
# ARG_OPTIONAL_SINGLE([max-sleep], [m], [Max time allowed to sleep (e.g. to avoid all cron's in the estate sending log files at the same time)], 0)
# ARG_OPTIONAL_SINGLE([key], , [The client's private key file path.],)
# ARG_OPTIONAL_SINGLE([key-type], , [The type of the client's private key.], PEM)
# ARG_OPTIONAL_SINGLE([cert], , [The client's certificate file path.],)
# ARG_OPTIONAL_SINGLE([cert-type], , [The type of the client's certificate.], PEM)
# ARG_OPTIONAL_SINGLE([auth-generator], , [Path to a zero args executable that outputs the required "Authorization: Bearer" credential to stdout. Typically used in conjunction with Data Feed Keys],)
# ARG_OPTIONAL_SINGLE([token-endpoint], , [Required for OIDC token authentication - The IdP token endpoint. e.g https://login.microsoftonline.com/<tenant id>/oauth2/token],)
# ARG_OPTIONAL_SINGLE([token-client-app-id], , [Required for OIDC token authentication - The ID of your client app as known to the IdP. This is a UUID when Active Directory is the IdP.],)
# ARG_OPTIONAL_SINGLE([token-stroom-app-id], , [Required for OIDC token authentication - The ID of the stroom destination app known to the IdP.  Ask your Stroom admin for this information if unknown.],)
# ARG_OPTIONAL_SINGLE([token-client-secret-filename], , [Required for OIDC token authentication - A single line text file containing the secret associated with the app client known to the IdP.  The secret can be created by admins of the client app, e.g. with Active Directory.],)
# ARG_OPTIONAL_SINGLE([token-scopes], , [Space separate list of OAuth scopes to request when fetching a token. If not set the scope "openid" will be used. ],)
# ARG_OPTIONAL_SINGLE([cacert], , [The certificate authority's certificate file path. The certificate must be in PEM format],)
# ARG_OPTIONAL_SINGLE([system], , [The name of the system producing the log events, shortcut for -H System:SYSTEM_NAME], )
# ARG_OPTIONAL_SINGLE([environment], , [The type of environment of the system producing the log events, E.g. DEV,OPS,etc., shortcut for -H Environment:ENV_NAME], )
# ARG_OPTIONAL_BOOLEAN([debug], , [Run with debug logging enabled], off)

# ARG_POSITIONAL_SINGLE([log-dir], [Directory to look for matching log files in],)
# ARG_POSITIONAL_SINGLE([feed], [The name of the Stroom feed that the data will be sent to.  If stroom is configured to assign the feed automatically, you should supply the literal 'auto' for this arg],)
# ARG_POSITIONAL_SINGLE([stroom-url], [The URL you are sending data to (N.B. This should be the HTTPS URL)],)
# ARG_DEFAULTS_POS
# ARG_HELP([This script will send log files in 'log-dir' to Stroom using the specified stroom-url.\nIf matching log files have the extension .gz or .zip then the appropriate 'Compression:...' header will be set.\nOnly one instance of send_to_stroom can run in a 'log-dir' at once.\n])
# ARG_VERSION_AUTO([SNAPSHOT_VERSION])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO

# vim:set filetype=sh et sw=2 ts=2:
