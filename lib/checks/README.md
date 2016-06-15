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

### RummagerContentMissingFromPublishingApi

This check finds content present in Rummager for which the base_path doesn't map to a user-visible content item in the Publishing API.
The assumption is that anything present in Rummager should be user-visible.
Our proxy for 'user-visible' is that the `/lookup-by-base-path` endpoint in Publishing API finds a content_id.
Recommended links are excluded.
Withdrawn items are excluded, because the content_id lookup does not guarantee to find a content_id for them.

### PublishingApiContentMissingFromRummager

This check finds user-visible content present in Publishing API for which no base_path is present in Rummager.
The assumption is that everything published in Publishing API should be in Rummager.
Our proxy for 'being published' is that the some content item of the content_id has state `published`, `unpublished`, or `superseded`.

### RummagerLinkTargetsMissingFromPublishingApi

This check finds link targets for links present in Rummager for which the target base_path doesn't map to a user-visible content item in the Publishing API.
The assumption is that any link target in Rummager should be user-visible.
Our proxy for 'user-visible' is that the `/lookup-by-base-path` endpoint in Publishing API finds a content_id.

### RummagerLinkTargetsMissingFromRummager

This check finds link targets for links present in Rummager for which the target base_path is not present in Rummager.
The assumption is that any link target in Rummager should be indexed.

### MissingLinks

This check creates two reports:

- links present in Rummager which are not present in Publishing API.
- links present in Publishing API which are not present in Rummager.

The assumption is that links should always be in sync.
This check only reports missing links on items for which the base_path in Rummager can be mapped to the content_id in Publishing API.
Items which cannot be mapped should be covered by the missing content checks.

### RedirectedRummagerContent

Checks for documents in rummager where the base path is now redirected according to publishing api.

This is equivalent to the following:

- Lookup the base path of the rummager document to get a content id
- Check whether a redirect exists for that content id

### RedirectedRummagerLinkTargets

Checks for links in rummager that point to content that is redirected in the publishing api.

These should point to the target of the redirect rather than the old URL.
