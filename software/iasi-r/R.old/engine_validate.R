# Validate engine ---------------------------------------------------------

.engine_validate = function(context) {
  context = .prepare_context(context)
  lapply(context$projects, function(project) .validate_project(context, project))
  invisible(context$rc)
}


# Validate one selected project.
.validate_project = function(context, project) {
  project = .prepare_project_config(project)

  if (identical(project$config$type, .IASI$types$pkg)) {
    if (!file.exists(file.path(project$path, "DESCRIPTION"))) {
      message("Missing DESCRIPTION in R package: ", project$path)
      stop("Invalid R package project.", call. = FALSE)
    }

    return(invisible(context$rc))
  }

  quarto = .as_quarto_project(project)
  .ensure_checked_project(quarto)
  invisible(context$rc)
}
