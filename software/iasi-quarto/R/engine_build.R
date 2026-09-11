# Prepare the shared context and build every selected project.
.engine_build = function(context) {
  context = .prepare_context(context)
  message(sprintf("Building %d IASI project(s)...", length(context$projects)))

  results = lapply(
    context$projects,
    function(project) .build_project(context, project)
  )

  if (length(results) && any(unlist(results) != .IASI$status$OK)) {
    return(.IASI$status$ERROR)
  }

  .IASI$status$OK
}


# Dispatch one selected project to the build implementation for its type.
.build_project = function(context, project) {
  project = .prepare_project_config(project)
  message("Building: ", project$path, " [", project$config$type, "]")

  if (identical(project$config$type, .IASI$types$pkg)) {
    return(.build_package_project(context, project))
  }

  if (project$config$type %in% c(.IASI$types$guide, .IASI$types$web)) {
    return(.build_quarto_project(context, project))
  }

  .IASI$status$OK
}
