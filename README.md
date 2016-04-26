# Finding Things Migration Checker

The scripts in this repository compare [publishing api](https://github.com/alphagov/publishing-api) links
with [rummager](https://github.com/alphagov/rummager) to know if both are in sync.


## fetch_publishing_api_links

The script will check the dev environment if DATABASE_URL is not set.

This script extracts all links from the [publishing api](https://github.com/alphagov/publishing-api), for later comparison
with [rummager](https://github.com/alphagov/rummager) data.

### Usage

Run the script with

    govuk_setenv publishing-api bundle exec bin/fetch_publishing_api_links FILE_NAME


# LICENSE

[MIT](LICENSE)
