# Publish

`publish()` applies only to publicable project types.

Public API intent:

```r
publish(format = NULL, path = ".")
```

Publish always consumes:

```text
<project>/_outputs
```

There is no public `source` parameter.

Each project owns its own publication tree:

```text
<project>/_publish
```

Before publishing, the selected `_outputs/<format>` materializations are fingerprinted. If the fingerprint matches the previous successful publication, publication is skipped.

`format = NULL` publishes every available built format. An explicit `format` selection publishes only those built materializations.

Publication is prepared in a temporary sibling work tree:

```text
_publish.work
```

Pipeline:

```text
_outputs/<selected formats>
  -> fingerprint
  -> copy to temporary work tree
  -> post-process
  -> write publication metadata
  -> replace _publish
```

The previous publication remains intact if processing fails before replacement.

The `.publish` metadata stores at least `timestamp` and `hash`.
