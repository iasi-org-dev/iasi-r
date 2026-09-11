# R Code Conventions

R source filenames use `snake_case`.

Internal function names also use underscores.

Prefer `=` rather than `<-` for assignment.

Keep calls, assignments, and simple conditions on one line while they remain readable.

Use multiline formatting only when it materially improves readability.

Avoid ceremonial vertical formatting.

Public APIs should stay minimal. Do not expose parameters that duplicate configuration already known by the project.

Parameters deliberately removed during the current refactor include `book`, `source`, build `force`, and release `force`.

Publish `force` remains because it has explicit semantics.
