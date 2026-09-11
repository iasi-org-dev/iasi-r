# Configuration Inheritance

A project's local `_iasi.yml` or `.iasi.yml` is the starting configuration.

`prepare_project_config()` walks upward through parent directories and merges inherited IASI configuration.

Inheritance is additive only:

> local values win; parent values fill only missing configuration.

Nested lists follow the same rule recursively.

This allows repository-level defaults without forcing intermediate directories to become IASI projects.

Path defaults currently include:

```text
publish -> _publish
release -> release
```

For `r-package`, the build output path defaults to the project root.
