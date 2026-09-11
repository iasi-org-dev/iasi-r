# Refactor snapshot

Public API: `validate()`, `build()`, `publish()`, `release()`.

`deploy()` has been removed from `iasi.quarto`.

Shared infrastructure lives in `core-*`. Action orchestration lives in
`engine-action-*`. Existing Quarto preparation/render/publish helpers are
retained from the recovered package snapshot.

This snapshot is intentionally pending integration tests in the real repository.
