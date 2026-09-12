# Publish

`publish()` applies only to publicable project types.

Public API intent:

```r
publish(path = ".", force = FALSE)
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

Before publishing, the `_outputs` tree is fingerprinted. If the fingerprint matches the previous successful publication and `force = FALSE`, publication may be skipped.

`force = TRUE` means publish again even when the build-output content did not change.

Publication is prepared in a temporary sibling work tree:

```text
_publish.work
```

Pipeline:

```text
_outputs
  -> fingerprint
  -> copy to temporary work tree
  -> post-process
  -> write publication metadata
  -> replace _publish
```

The previous publication remains intact if processing fails before replacement.

The `.publish` metadata stores at least `timestamp` and `hash`.
