# Publish

`publish()` materializes already-built public output. It never renders sources.

Public API:

```r
publish(format = NULL, path = ".")
```

Publish consumes selected non-empty format directories below:

```text
<project>/_outputs
```

and materializes them into the project publication tree, by default:

```text
<project>/_publish
```

`format = NULL` publishes every available built format. An explicit format
selection publishes only matching built materializations.

Publication is prepared in a unique temporary sibling directory and replaces the
final publication only after preparation succeeds. The selected output tree is
fingerprinted and the hash is stored with the publication timestamp in
`.publish` metadata.
