# R Code Conventions

R source filenames use `snake_case`.
Internal function names also use underscores.
Prefer `=` rather than `<-` for assignment.

Keep calls, assignments, and simple conditions on one line while they remain
readable. Use multiline formatting only when it materially improves readability.

Public APIs should stay minimal. Do not expose parameters that duplicate
configuration already known by the project.

Current public APIs are:

```r
validate(path = ".")
build(format = NULL, path = ".")
publish(format = NULL, path = ".")
release(path = ".")
```
