# Project Types

IASI Quarto recognizes four project types:

```text
repository
guide
web
r-package
```

`repository` is a container/configuration project. It may contain other IASI projects and provide inherited configuration, but it is not itself built, published, or released as a deliverable.

`guide` and `web` are publicable projects.

`r-package` is a software project. It is built and released, but it is not published.

Intermediate directories do not need to be IASI projects. Discovery continues recursively until marked projects are found, except below excluded paths.
