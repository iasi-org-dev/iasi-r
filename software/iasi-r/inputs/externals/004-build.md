# Build

`build()` always builds when invoked.

It does not try to determine whether source material changed.

Public API intent:

```r
build(format = NULL, path = ".")
```

For Quarto projects, artifacts are materialized under:

```text
_outputs/
```

Profiles/formats are resolved from the Quarto configuration already loaded for the project.

For `r-package`, build creates both package forms:

```text
source package  -> *.tar.gz
binary package  -> *.zip on Windows
```

Package artifacts are left in the package project root so `release()` can collect them later.

Build reports concise progress and keeps raw R and Quarto subprocess output visible.
