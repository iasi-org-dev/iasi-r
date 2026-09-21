# Action Targets

All public actions use the same discovery infrastructure.

Public actions:

```text
validate
build
publish
release
```

`prepare_context()` discovers marked IASI projects below `path` and excludes
repository containers from execution. Each action then decides what is
applicable to the remaining project types.

Current behavior:

```text
validate  -> quarto, website, r-package
build     -> quarto, website, r-package
publish   -> website, and quarto with publication.strategy
release   -> website, r-package, and quarto
```

For `quarto` without `publication.strategy`, build uses Quarto as-is and release
collects the build output directly. Such a project has no IASI publish step.
