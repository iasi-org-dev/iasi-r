# Project Types

IASI recognizes four project types:

```text
repository
quarto
website
r-package
```

`repository` is a container/configuration project. It may contain other IASI
projects and provide inherited configuration, but it is not itself built,
published, or released as a deliverable.

`quarto` is a Quarto project. It may opt into IASI publication processing by
declaring `publication.strategy`. Without a strategy it is rendered by Quarto
as-is.

`website` is an IASI website project. It uses Quarto rendering but does not use
the Quarto publication strategies.

`r-package` is an R software package. It is built and released, but not
published.
