# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).


## [Unreleased]

* Relax the requirement to use parameters `--token-client-secret-filename` and `--token-client-secret-filename` when using OIDC. The secret is not required if the IDP is doing x509 authentication.

* Add the parameter `--token-scopes`

* Parse token response JSON with jq if jq is present.


## [send-to-stroom-v3.3.0] - 2025-04-23

* Add option to specify a script/executable to call that determines Authorization:Bearer

* Allow feed to be set to 'auto' to suppress FEED header where Stroom automatically assigns feed

* Redact Authorization:Bearer token from the log output

## [send-to-stroom-v3.2.2] - 2023-05-15

* Fix bug setting OIDC secret from file


## [send-to-stroom-v3.2.1] - 2022-11-08

* Output version number on start-up.


## [send-to-stroom-v3.2.0] - 2022-11-08

* Added support for OIDC Client Credentials Authentication


## [send-to-stroom-v3.1.0] - 2021-05-26

* Added optional `--system` and `--environment` arguments.

* Split one info logging line into three.


## [send-to-stroom-v3.0] - 2020-12-08

* Removed mandatory system and environment positional arguments.


[Unreleased]: https://github.com/gchq/stroom-clients/compare/send-to-stroom-v3.2.1...HEAD
[send-to-stroom-v3.2.1]: https://github.com/gchq/stroom-clients/compare/send-to-stroom-v3.2.0..send-to-stroom-v3.2.1
[send-to-stroom-v3.2.0]: https://github.com/gchq/stroom-clients/compare/send-to-stroom-v3.1.0..send-to-stroom-v3.2.0
[send-to-stroom-v3.1.0]: https://github.com/gchq/stroom-clients/compare/send-to-stroom-v3.0..send-to-stroom-v3.1.0
[send-to-stroom-v3.0]: https://github.com/gchq/stroom-clients/compare/send-to-stroom-v2.1..send-to-stroom-v3.0
