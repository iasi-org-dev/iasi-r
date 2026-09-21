# Current architecture

This source tree is the cleaned baseline of the `iasi` R package.

## Public API

```r
validate(path = ".")
build(format = NULL, path = ".")
publish(format = NULL, path = ".")
release(path = ".")
```

## Configuration invariant

Project type is a root property. Quarto publication strategy is not.

```yaml
type: quarto

publication:
  strategy: parted
```

`publication.strategy` is the only canonical strategy location. A root-level
`strategy` is rejected as obsolete.

A Quarto project without `publication.strategy` is valid and is rendered by
Quarto as-is.

## Project types

```text
repository
quarto
website
r-package
```

## Source layout

- `core_*`: shared discovery, configuration and Quarto model helpers.
- `engine_*`: action orchestration and implementation.
- `tests/testthat`: regression tests for the public contract and internal invariants.
- `inputs/externals`: concise engineering contract for the implementation.

Historical duplicate source trees, IDE state, built package archives and release
artifacts are intentionally excluded from this baseline.
