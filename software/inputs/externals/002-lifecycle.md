# IASI Quarto Lifecycle

## Public lifecycle

IASI Quarto exposes four public operations:

```text
validate
build
publish
release
```

Deployment is deliberately outside `iasi.quarto` because it interacts with external systems. That responsibility belongs to a higher-level tool such as `iasi-dev`.

## Validate

`validate()` checks selected projects.

It does not build, publish, or release artifacts.

## Build

`build()` always builds when invoked.

It does not try to decide whether source files changed.

For Quarto projects, build artifacts are materialized under:

```text
_outputs/
```

For an `r-package`, build produces both:

```text
source package  -> *.tar.gz
binary package  -> *.zip   (on Windows)
```

The package artifacts are left in the package project root for `release()` to collect later.

## Publish

`publish()` applies only to publicable project types.

It always consumes:

```text
<project>/_outputs
```

There is no public `source` parameter.

Each project owns its own publication tree:

```text
<project>/_publish
```

Publish does not create one shared repository-level `_publish`.

Before publishing, the content of `_outputs` is hashed.

If the hash matches the previous publication and `force = FALSE`, publication may be skipped.

With:

```r
publish(force = TRUE)
```

the publication is repeated even when the input hash did not change.

Publication is prepared in a temporary sibling work tree:

```text
_publish.work
```

The pipeline is:

```text
_outputs
  -> calculate hash
  -> copy to temporary work tree
  -> post-process
  -> write publication metadata
  -> atomically replace _publish
```

The existing publication remains intact if processing fails before replacement.

The `.publish` metadata stores at least:

```text
timestamp
hash
```

## Release

`release()` collects local deliverables.

For `r-package`, it moves package artifacts from the package project root into the configured release directory.

For publicable projects, it copies the already prepared project-local `_publish`.

`release()` is responsible for organizing multiple project deliverables into the release layout.

The conceptual lifecycle is:

```text
validate  -> check
build     -> construct artifacts
publish   -> prepare publicable artifacts
release   -> collect deliverables
```
