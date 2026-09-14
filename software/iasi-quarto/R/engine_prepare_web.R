.prepare_web_project = function(project) {
  project$publication = .new_publication(
    path = project$path,
    type = project$type,
    strategy = NULL,
    chapters = character(),
    artifacts = character(),
    changed = FALSE
  )

  project
}
