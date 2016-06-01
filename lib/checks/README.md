## Check Form

A check always has the same input and output types.

Input:

- check name
- checker database, for access to imported data
- whitelist, for access to output filtering rules for the check

Output:

- a report object, including csv output for writing to a file

Each check is independent of the others and has a single purpose.
However, they may have overlapping output, in that several checks may detect the same content discrepancy.

## Checks

### BasePathsMissingFromPublishingApi

This check finds content present in Rummager for which the base_path doesn't map to a published content item in the Publishing API.
The assumption is that anything present in Rummager should be published.
Our proxy for 'being published' is that the `/lookup-by-base-path` endpoint in Publishing API finds a content_id.
Recommended links are excluded.

### BasePathsMissingFromRummager

This check finds published content present in Publishing API for which no base_path is present in Rummager.
The assumption is that everything published in Publishing API should be in Rummager.
Our proxy for 'being published' is that the some content item of the content_id is state `published`, `unpublished`, or `superseded`.

### LinkedBasePathsMissingFromPublishingApi

This check finds link targets for links present in Rummager for which the target base_path doesn't map to a published content item in the Publishing API.
The assumption is that any link target in Rummager should be published.
Our proxy for 'being published' is that the `/lookup-by-base-path` endpoint in Publishing API finds a content_id.

### RummagerLinksNotIndexedInRummager

This check finds link targets for links present in Rummager for which the target base_path is not present in Rummager.
The assumption is that any link target in Rummager should be indexed.

### LinksMissingFromPublishingApi

This check finds links present in Rummager which are not present in Publishing API.
The assumption is that links should always be in sync.

### LinksMissingFromRummager

This check finds links present in Publishing API which are not present in Rummager.
The assumption is that links should always be in sync.

### ExpiredWhitelistEntries

This check doesn't check anything about Rummager or Publishing API.
Instead, it reports on whitelist entries which have expired.
This is so that when the checks are running automatically in Jenkins, we are eventually reminded of discrepancies we previously whitelisted.
We should provide a reason and a sensible recheck time when we add a whitelist entry.

# RummagerRedirects

Checks for documents in rummager where the base path is now redirected according to publishing api.

This is equivalent to the following:

- Lookup the base path of the rummager document to get a content id
- Check whether a redirect exists for that content id
