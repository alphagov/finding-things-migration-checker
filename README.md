# Finding Things Migration Checker

Check that publishing-api, rummager links are in sync.


## fetch_publishing_api_links

The script will check the dev environment if DATABASE_URL is not set.

This script extracts all links from the [publishing api](https://github.com/alphagov/publishing-api), for later comparison
with [rummager](https://github.com/alphagov/rummager) data.

### Usage

Run the script with

    govuk_setenv publishing-api bundle exec bin/fetch_publishing_api_links FILE_NAME


# LICENSE

[MIT](LICENSE)
