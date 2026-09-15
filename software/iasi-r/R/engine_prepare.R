.prepare_project = function(project) {
  switch(
    project$type,
    book = .prepare_book_project(project),
    website = .prepare_web_project(project),
    stop(
      sprintf(
        "Unsupported Quarto project type '%s'.",
        .display_checked_value(project$type)
      ),
      call. = FALSE
    )
  )
}

.prepare_book_project = function(project) {
  switch(
    project$strategy,
    regular = .prepare_regular_project(project),
    structured = .prepare_structured_project(project),
    parted = .prepare_parted_project(project),
    direct = .prepare_direct_project(project),
    stop(
      sprintf(
        "Unsupported IASI strategy '%s'.",
        .display_checked_value(project$strategy)
      ),
      call. = FALSE
    )
  )
}
