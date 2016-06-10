# Finding Things Migration Checker

This project compares content in [publishing api](https://github.com/alphagov/publishing-api)
with that in [rummager](https://github.com/alphagov/rummager) to check whether both are in sync.

## Technical documentation

This project is normally intended to be invoked by Jenkins via the `bin/run_automated_checks` script.
The entry point is the `CheckRunner` class.

There are two phases to a run:

- Query Rummager and Publishing API public apis and import their data into an in-memory sqlite db
- Run several independent checks against the local db, each of which writes a csv output file in the working directory.

The exit code for a run is `1` if any check fails, `0` otherwise.

Each check can filter its usual output using a whitelist. This allows us to run the checks automatically
in Jenkins and still keep the job green even though there may be some known problems we are working on.

Each check's purpose and way of working should be described in the [checks readme](lib/checks/README.md)

Whitelist entries have a reason for existing and an expiry date.
Expired entries are reported as errors.

### Dependencies

- [publishing api](https://github.com/alphagov/publishing-api)
- [rummager](https://github.com/alphagov/rummager)

### Running the application

`bundle install && bin/run_automated_checks`

The `CheckRunner` requires a list of check class names as input.
These can be provided as command line arguments, in which case the `CheckRunner` will only run the requested checks.
If no checks are specified, all checks in the `lib/checks` directory are run.

There are a few environment variables which can be used to configure other behaviours:

- `CHECKER_DB_NAME=foo.db` to use a file-backed db instead of an in-memory one
- `SKIP_DATA_IMPORT=set` (any value works) to not run the data import phase
- `WHITELIST_FILE=alternative_whitelist.yml` specify a whitelist file other than the default `whitelist.yml`
- `CHECK_OUTPUT_DIR=/tmp/my_check_output` specify a csv output directory other than the default `.`
- `SUPPRESS_PROGRESS=set` (any value works) to not emit progress reporting to stdout

### Running the test suite

`bundle exec govuk-lint-ruby && bundle exec rspec`

## Licence

[MIT License](LICENCE)
