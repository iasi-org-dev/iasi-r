# Lifecycle

The IASI Quarto lifecycle is:

```text
validate
build
publish
release
```

Responsibilities:

```text
validate -> check selected projects
build    -> construct artifacts
publish  -> prepare publicable artifacts
release  -> collect deliverables
```

External deployment is deliberately outside `iasi.quarto`.

A higher-level tool such as `iasi-dev` may deploy released artifacts to external systems.

Artifact progression for publicable projects:

```text
sources -> _outputs -> _publish -> release
```

Artifact progression for software packages:

```text
sources -> *.tar.gz / *.zip -> release
```
