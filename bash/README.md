# send_to_stroom.sh

This script is essentially a wrapper around curl to simplify sending data to a stroom instance/cluster.
When run it will attempt to send all files in the specified directory to the specified URL, deleting the sent files afterwards.
If it encounters an empty file or a .gz/.zip that that has no content then it will not be sent and by default will be deleted.

The basic form of the script is as follows:

```bash
./send_to_stroom.sh [OPTIONS] <log-dir> <feed> <system> <environment> <stroom-url>
```

* `log-dir` - The directory to search in for log files. It does not recurse into sub-directories.
* `feed` - The name of the feed in Stroom the data will be sent to. The feed must exist prior to sending data.
* `system` - The name of the system that the logs are for.
* `environment` - The name of the environment of the system that the logs are for, e.g. OPS, DEV, etc.
* `stroom-url` - The URL of Stroom's _datafeed_ endpoint that the files will be send to, e.g. `https:some-host/stroom/datafeed`.

The script has a large number of optional arguments for controlling things like certificates, file name regex matching, deletion policy, additional headers, etc.

For full details of the optional arguments execute:

```bash
./send_to_stroom.sh --help
```

## Notes for developers of this script

The `send_to_stroom.sh` script makes use of an [argbash](https://argbash.io) generated script (`send_to_stroom_args.sh`) for parsing the command line arguments.
The _argbash_ binary needs to be installed to make changes to the command line arguments that `send_to_stroom.sh` expects/allows.
The _argbash_ binary does NOT need to be installed to run `send_to_stroom.sh`.

To modify the command line arguments edit the `.m4` file (see the argbash documentation for details of the syntax) then run

```bash
argbash send_to_stroom_args.m4 -o send_to_stroom_args.sh
```

to regenerate the `send_to_stroom_args.sh` script.
