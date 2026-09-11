# Validate engine ---------------------------------------------------------

.engine_validate = function(context) {
  context = .prepare_context(context)

  results = lapply(context$projects, function(project) .validate_project(project))

  if (length(results) && any(unlist(results) != .IASI$status$OK)) {
    return(.IASI$status$ERROR)
  }

  .IASI$status$OK
}


# Validate one selected project.
.validate_project = function(project) {
  project = .prepare_project_config(project)

  if (identical(project$config$type, .IASI$types$pkg)) {
    if (!file.exists(file.path(project$path, "DESCRIPTION"))) {
      message("Missing DESCRIPTION in R package: ", project$path)
      stop("Invalid R package project.", call. = FALSE)
    }

    return(.IASI$status$OK)
  }

  quarto = .as_quarto_project(project)
  .ensure_checked_project(quarto)
  .IASI$status$OK
}
