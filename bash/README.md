# send_to_stroom.sh

This script is essentially a wrapper around curl to simplify sending data to a stroom instance/cluster.
When run it will attempt to send all files in the specified directory to the specified URL, deleting the sent files afterwards.
If it encounters an empty file or a .gz/.zip that that has no content then it will not be sent and by default will be deleted.

The basic form of the script is as follows:

```bash
./send_to_stroom.sh [OPTIONS] <log-dir> <feed> <stroom-url>
```

* `log-dir` - The directory to search in for log files. It does not recurse into sub-directories.
* `feed` - The name of the feed in Stroom the data will be sent to. The feed must exist prior to sending data.
* `stroom-url` - The URL of Stroom's _datafeed_ endpoint that the files will be send to, e.g. `https://some-host/stroom/datafeed`.

The script has a large number of optional arguments for controlling things like certificates, file name regex matching, deletion policy, additional headers, etc.

For full details of the optional arguments execute:

```bash
./send_to_stroom.sh --help
```


## Headers

Stroom has a number of optional reserved header keys that it will look for when ingesting the data sent by this script.
The reserved headers are:

* `Compression` - Defines the compression algorithm used when sending the data.
  This header will be set automatically by the script. See [Compression](#compression).
* `Environment` - Defines the environment of the system producing the log events, e.g. DEV, REF, OPS, etc.
  This will be set automatically using the optional `--environment` argument.
* `Feed` - Defines the feed that the data will be ingested into.
  A feed is a concept in stroom to group data, typically data conforming to the same structure and coming from the same source are grouped into a single feed.
  This header argument is set automatically by the positional `feed` argument.
* `System` - The name of the system producing the log events.
  This will be set automatically using the optional `--system` argument.


## Compression

If the file being sent has a `.gz` or `.zip` file extension then the appropriate `Compression` header will be set.
If the `-z` or `--compress` flag is set then the file will be compressed with GZIP compression before being sent and the `Compression` header will be set.


## Notes for developers of this script

The `send_to_stroom.sh` script makes use of an [argbash](https://argbash.io) generated script (`send_to_stroom_args.sh`) for parsing the command line arguments.
The _argbash_ binary needs to be installed to make changes to the command line arguments that `send_to_stroom.sh` expects/allows.
The _argbash_ binary does NOT need to be installed to run `send_to_stroom.sh`.

To modify the command line arguments edit the `.m4` file (see the argbash documentation for details of the syntax) then run

```bash
./build.sh
```

to regenerate the `send_to_stroom_args.sh` script.
This script runs argbash in a docker container so you need to have docker installed, but no other dependencies.

Alternatively, you can use the argbash online script generator and save the output file as `bash/send_to_stroom_args.sh`

### Releasing

To release a new version of the script run the generation as follows:

```bash
./build.sh v1.2.3
```

Tag the version in git:

```bash
version="v1.2.3" git tag -a "send-to-stroom-${version}" -m "Releasing send_to_stroom ${version}" && git push origin "send-to-stroom-${version}"
```

In github create a release for this tag and upload the following files as release artefacts:

* send_to_stroom.sh
* send_to_stroom_args.sh

