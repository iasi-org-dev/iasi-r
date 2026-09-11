# Engine Architecture

Each public operation calls one internal engine:

```text
.engine_validate()
.engine_build()
.engine_publish()
.engine_release()
```

The engine function should be the first function in its engine file.

Generic orchestration belongs in the generic engine file.

Implementation-specific behavior may be separated when there is a real responsibility boundary.

Avoid creating thin files whose only purpose is forwarding calls.

`prepare_context()` owns discovery and target selection.

`prepare_project_config()` owns inherited configuration resolution.

Action engines should consume the prepared context instead of rediscovering or reselecting projects.
