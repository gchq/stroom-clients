# send_to_stroom.sh

This script is essentially a wrapper arround curl to simplifiy sending data to a stroom instance/cluster.

To see how the script should be run execute

```bash
./send_to_stroom.sh --help
```

## argbash

The `send_to_stroom.sh` script makes use of an [argbash](https://argbash.io) generated script (`send_to_stroom_args.sh`) for parsing the command line arguments.
The _argbash_ binary needs to be installed to make changes to the command line arguments that `send_to_stroom.sh` expects/allows.
The _argbash_ binary does NOT need to be installed to run `send_to_stroom.sh`.

To modify the command line arguments edit the `.m4` file (see the argbash documentation for details of the syntax) then run

```bash
argbash send_to_stroom_args.m4 -o send_to_stroom_args.sh
```

to regenerate the `send_to_stroom_args.sh` script.
