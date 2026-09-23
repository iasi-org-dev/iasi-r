# IASI Quarto Implementation Conventions

## Public API

Keep public APIs minimal.

Current intent:

```r
validate(path = ".")
build(format = NULL, path = ".")
publish(path = ".", force = FALSE)
release(path = ".")
```

Do not expose parameters that duplicate configuration already known by the project.

Examples of removed redundant parameters include:

```text
book
source
build force
release force
```

`publish force` remains because it has clear semantics: repeat publication even when the build-output hash is unchanged.

Return status codes invisibly.

## Engines

Each public operation calls one internal engine:

```text
.engine_validate()
.engine_build()
.engine_publish()
.engine_release()
```

The engine function should be the first function in its engine file.

Generic orchestration belongs in the generic engine file.

Implementation-specific logic may live in focused files, for example:

```text
engine_build.R
engine_build_quarto.R
engine_build_package.R
```

Avoid creating thin files that merely forward calls without adding a real responsibility boundary.

## Naming

R source filenames use `snake_case`.

Internal R functions also use underscore-based names.

Do not mix hyphenated and underscored R source filenames.

## R style

Prefer `=` rather than `<-` for assignment.

Keep function calls, assignments, and simple conditions on one line while they remain readable.

Use multiline formatting only when it materially improves readability.

Avoid ceremonial vertical formatting.

## Messages

Do not print discovery/selection debug lists during normal operation.

Do print concise progress messages when they tell the user what work is being performed.

Examples:

```text
Building 2 IASI project(s)...
Building: ... [guide]
Building source package...
Building binary package...
```

Keep raw R and Quarto subprocess output visible because it contains useful build information.

Errors and anomalous situations should remain explicit.

## Responsibility boundaries

`prepare_context()` owns discovery and action-target selection.

Action engines should not repeat that filtering.

`prepare_project_config()` owns configuration inheritance.

`build` creates artifacts.

`publish` performs publication materialization and post-processing.

`release` collects deliverables.

External deployment does not belong to `iasi.quarto`.
