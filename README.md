# stroom-clients

This repository contains a collection of client applications or example applications for sending data into Stroom.

See also [event-logging](https://github.com/gchq/event-logging) which is a java library for generating XML events conforming to the event-logging XML schema.


## Bash - send_to_stroom.sh

This script can be used to send all matching files, e.g. rolled log files, in a directory to Stroom from the command line.

See [send_to_stroom](./bash/README.md)

See also [stroom-log-sender](https://hub.docker.com/r/gchq/stroom-log-sender/) which is a packaged Docker image that makes use of send_to_stroom.sh.
