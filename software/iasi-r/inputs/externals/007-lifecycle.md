# Lifecycle

The IASI lifecycle is:

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
publish  -> materialize publicable built artifacts
release  -> collect deliverables
```

External deployment is deliberately outside `iasi`. A higher-level tool such as
`iasi-dev` may deploy released artifacts to external systems.

For Quarto projects with an IASI publication strategy:

```text
sources -> _outputs -> _publish -> release
```

For Quarto projects without a strategy:

```text
sources -> _outputs -> release
```

For R packages:

```text
sources -> *.tar.gz / *.zip -> release
```
