# Type and Publication Strategy

`type` and `publication.strategy` are different dimensions.

`type` answers: what kind of IASI project is this?

For `type: quarto`, `publication.strategy` answers: how should IASI structure
and post-process the Quarto publication?

Canonical configuration:

```yaml
type: quarto

publication:
  strategy: parted
```

Supported Quarto publication strategies are:

```text
regular
structured
parted
direct
```

A top-level `strategy` key is not valid. Strategy belongs to `publication`.
If a Quarto project omits `publication.strategy`, IASI renders it with Quarto
as-is.
