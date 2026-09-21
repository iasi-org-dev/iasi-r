# Refactor snapshot

Public API: `validate()`, `build()`, `publish()`, `release()`.

`deploy()` has been removed from `iasi.quarto`.

Shared infrastructure lives in `core-*`. Action orchestration lives in
`engine-action-*`. Existing Quarto preparation/render/publish helpers are
retained from the recovered package snapshot.

This snapshot is intentionally pending integration tests in the real repository.

## v3 correction

Public status codes are returned invisibly.

`build` now dispatches by IASI project `type` before resolving any Quarto
format/profile information. `r-package` therefore follows its package build
path independently of document/Quarto build logic.

## v4 correction

Project selection is action-independent. `prepare_context()` now reports every
selected IASI project with its effective declared type. Individual action
engines decide whether a selected type requires processing.

## v6 correction

Discovery no longer drops a project directory merely because both supported
IASI configuration filenames are present. Discovery reports the candidate;
configuration loading is responsible for reporting ambiguity explicitly.

`build` now ignores valid selected types for which it has no build operation,
such as `repository`, instead of treating them as Quarto projects.

## v7 correction

Discovery walks the whole directory tree beneath the requested path. Intermediate
directories do not need an IASI marker. A directory becomes a discovered IASI
project only when that directory itself contains `_iasi.yml` or `.iasi.yml`.

Known generated/test trees are excluded from inspection, but ordinary container
directories such as `software/` remain traversable.

## v8 correction

`build()` now has only `format` and `path`.

`book` was removed because project scope is determined by `path`.
`force` was removed because invoking `build()` means build unconditionally;
the build action does not perform freshness/change decisions.

## v9 correction

`r-package` build now always creates both package forms:

1. source package via `R CMD build .`
2. binary package via `R CMD INSTALL --build <source.tar.gz>`

Both artifacts are left in the package project root, where `release()` already
collects `*.tar.*` and `*.zip`.

## v10 cleanup

The temporary `engine-action-*` layer has been removed.

Action orchestration is now colocated with each engine:

- `engine-build.R`
- `engine-publish.R`
- `engine-release.R`
- `engine-validate.R`

No separate action-engine files remain.

## v11 cleanup

All R source filenames now use snake_case. Temporary hyphenated files have
been merged into their canonical underscore counterparts and removed.

Canonical engine files are:

- `engine_build.R`
- `engine_publish.R`
- `engine_release.R`
- `engine_validate.R`

Canonical core files use the same convention (`core_context.R`,
`core_discover.R`, `core_quarto.R`).

The obsolete `.select_build_books()` helper has been removed because `build()`
no longer exposes `book`.

## v12 build split

Build implementation is separated by responsibility:

- `engine_build.R`: orchestration and type dispatch only.
- `engine_build_package.R`: R package source/binary build.
- `engine_build_quarto.R`: Quarto build and all Quarto-specific helpers.

## v13 readability

Added short intent comments to the build orchestration, dispatch, package build,
source-artifact selection, and Quarto build entry points.

## v14 Quarto build documentation

`engine_build_quarto.R` now includes a module-level responsibility summary,
section headers, and concise comments for the main internal helpers. These are
ordinary code comments, not roxygen documentation, because the functions are
internal.

## v15 Pandoc cleanup

The custom Pandoc staging/rendering subsystem has been removed.

- removed `engine_pandoc.R`;
- removed `engine_render_pandoc.R`;
- removed the `_outputs/pandoc` staging path and state exclusions;
- removed the custom `single` format;
- DOCX and ODT now use the normal Quarto renderer path;
- `engine_build_quarto.R` is organized around format resolution, rendering,
  output cleanup, and export discovery only.

## v16 style cleanup

`engine_build_quarto.R` now follows the compact R style used by the project:
function calls and conditions stay on one line while they remain readable;
multiline layout is reserved for genuinely complex expressions and blocks.

## v17 compact Quarto build style

`engine_build_quarto.R` received a second compacting pass. Simple assignments,
calls, conditions, switches, and returns stay on one line. Multiline layout is
reserved for loops, branches with several statements, and callbacks where it
still improves readability.

## v18 publish refactor

Publish now follows the current context/project model.

- `book` was removed from the public publish API; `force` remains.
- `prepare_context()` selects action targets by IASI type.
- `engine_publish.R` contains orchestration only.
- `engine_publish_quarto.R` retains the existing temporary-tree and post-process pipeline.
- build-output content is hashed deterministically; unchanged publications are skipped unless forced.
- `.publish` is YAML metadata containing the publication timestamp and source hash.
- old `plan`/`report_publish` code was removed.
- simple calls and conditions were compacted to the current one-line style.

## v19 publish source simplification

`publish()` no longer accepts `source`.

Publish always consumes `<project>/_outputs`, which is the canonical build
materialization root. The obsolete explicit-source resolver and publish-source
state were removed. `force`, hashing, temporary `.work` processing, post-process,
and atomic replacement remain unchanged.

## v20 cleanup radiography

Removed obsolete architecture that no longer participates in the current API:

- removed `engine_state.R`; build always builds and publish owns its hash metadata;
- removed the old validation plan/discovery/reporting implementation;
- moved live Quarto parsing helpers into `core_quarto.R`;
- removed legacy plan reports from prepare/check;
- removed unused output-root inference;
- moved publish hash/metadata helpers into `engine_publish.R`;
- simplified `release()` to `release(path = ".")`;
- removed remaining `plan`/`book`/freshness-model residue.

## v21 project-local publish

Publish destinations are now project-local.

Each selected publicable project materializes its own configured publish path
(default `_publish`) below the configuration base that defines it. Publish no
longer creates repository-level slots or resolves multiproject destination
collisions. `release()` is responsible for assembling project publications into
the repository-level release layout.

## v22 console cleanup

Removed only the temporary `discovered` / `selected` project diagnostics from
`prepare_context()`.

IASI progress messages and raw R/Quarto subprocess output remain visible.

## v23 build progress messages

Build now reports concise progress without restoring discovery/selection debug:

- operation start with selected project count;
- one line per project;
- source/binary phase messages for R packages.

Raw R and Quarto subprocess output remains visible.
