# Engine Architecture

Each public operation calls one internal engine:

```text
.engine_validate()
.engine_build()
.engine_publish()
.engine_release()
```

The engine function should be the first function in its engine file.

Generic orchestration belongs in the generic engine file. Implementation-specific
behavior is separated only when there is a real responsibility boundary.

`prepare_context()` owns project discovery and generic project selection.
`prepare_project_config()` owns inherited configuration resolution.

Quarto configuration is normalized in `core_quarto.R`. In particular,
`publication.strategy` is the single canonical source of Quarto publication
strategy. Engines must not read a root-level `strategy` key.
