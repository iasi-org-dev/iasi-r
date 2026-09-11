.as_quarto_project = function(project) {
  if (!file.exists(file.path(project$path, "_quarto.yml"))) {
    message("Missing _quarto.yml in: ", project$path)
    stop("Missing Quarto configuration.", call. = FALSE)
  }

  quarto_project = .discover_project(project$path)
  quarto_project$config = project$config
  quarto_project$iasi_type = project$config$type
  quarto_project
}


.ensure_checked_project = function(project) {
  checked = .check_project(project)

  if (!isTRUE(checked$valid)) {
    for (error in checked$errors) {
      message(project$name, ": ", error)
    }

    stop("Project validation failed.", call. = FALSE)
  }

  for (warning in checked$warnings) {
    warning(warning, call. = FALSE)
  }

  checked
}
