# IASI Quarto Project Model

## Project types

IASI Quarto recognizes these project types:

```text
repository
guide
web
r-package
```

A `repository` may contain and configure other IASI projects but is not itself built, published, or released as a deliverable.

Intermediate directories do not need to be IASI projects. Discovery continues recursively until marked projects are found, except below excluded paths.

## Discovery and selection

All public actions use the same discovery infrastructure.

The public operations are:

```text
validate
build
publish
release
```

`prepare_context()` discovers projects below `path` and selects only the projects to which the current action applies.

Current applicability:

```text
validate  -> guide, web, r-package
build     -> guide, web, r-package
publish   -> guide, web
release   -> guide, web, r-package
```

Projects to which an action does not apply are ignored silently.

## Configuration inheritance

A project's local `_iasi.yml` or `.iasi.yml` is the starting configuration.

`prepare_project_config()` walks upward through parent directories and merges inherited IASI configuration.

Inheritance never overwrites values already defined closer to the project:

> local values win; parent values only fill missing configuration.

This allows repository-level defaults without turning every intermediate directory into a project.

## Type and strategy

`type` and `strategy` are different dimensions.

`type` describes what the project is.

`strategy` describes how a publication is organized or post-processed.

A Quarto publication may therefore have one type and different strategies, such as:

```text
regular
structured
parted
direct
```
