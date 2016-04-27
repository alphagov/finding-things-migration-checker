# Finding Things Migration Checker

The scripts in this repository compare [publishing api](https://github.com/alphagov/publishing-api) links
with [rummager](https://github.com/alphagov/rummager) to know if both are in sync.

The script will check the dev environment if `DATABASE_URL` is not set for publishing api.

The script will check the dev environment if `RUMMAGER_URL` is not set for rummager.

This script extracts all links from the [publishing api](https://github.com/alphagov/publishing-api), for later comparison
with [rummager](https://github.com/alphagov/rummager) data.

### Usage

You can simply run the following

    ./bin/bootstrap

Create a local PostgreSQL database called `migration_checker`

    ./bin/setup.sh

Import data from Publishing API and Rummager

    ./bin/import

    # or to only import one of them do

    IMPORT="rummager" ./bin/import
    IMPORT="publishing_api" ./bin/import


To compare the data

    ./bin/compare

# LICENSE

[MIT](LICENSE)
