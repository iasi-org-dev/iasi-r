# Action Targets

All public actions use the same discovery and selection infrastructure.

Public actions:

```text
validate
build
publish
release
```

`prepare_context()` discovers projects below `path` and selects only the project types to which the current action applies.

Current applicability:

```text
validate  -> guide, web, r-package
build     -> guide, web, r-package
publish   -> guide, web
release   -> guide, web, r-package
```

Projects to which an action does not apply are ignored silently.

Action engines do not repeat target filtering. Selection belongs to `prepare_context()`.
