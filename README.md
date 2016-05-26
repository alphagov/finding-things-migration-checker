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

### Dependencies

- [publishing api](https://github.com/alphagov/publishing-api)
- [rummager](https://github.com/alphagov/rummager)

### Running the application

`bin/run_automated_checks`

The `CheckRunner` requires a list of check class names as input.
Usually, these are provided as command line arguments (see `bin/run_automated_checks`).
The `CheckRunner` will only run the requested checks.

There are a few environment variables which can be used to configure other behaviours:

- `CHECKER_DB_NAME=foo.db` to use a file-backed db instead of an in-memory one
- `SKIP_DATA_IMPORT=set` (any value works) to not run the data import phase
- `PUBLISHING_API_URL=http://p.api.loc/v2/grouped_content_and_links` the URL to use to access Publishing API (soon to be obsoleted by `gds-api-adapters`)
- `WHITELIST_FILE=alternative_whitelist.yml` specify a whitelist file other than the default `whitelist.yml`

### Running the test suite

`bundle exec govuk-lint-ruby && bundle exec rspec`

## Licence

[MIT License](LICENCE)
