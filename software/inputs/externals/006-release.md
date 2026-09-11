# Release

`release()` gathers local deliverables.

Public API intent:

```r
release(path = ".")
```

It does not deploy anything to external systems.

For `r-package`, release moves package artifacts from the package project root into the configured release directory.

For publicable projects, release copies the already prepared project-local `_publish`.

Release is responsible for organizing multiple project deliverables into the final release layout.

This means publication and release have deliberately different scopes:

```text
publish -> local to each project
release -> organizes deliverables
```
