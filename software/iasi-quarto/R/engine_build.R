# Prepare the shared context and build every selected project.
.engine_build = function(context) {
  context = .prepare_context(context)
  message(sprintf("Building %d IASI project(s)...", length(context$projects)))

  lapply(context$projects, function(project) .build_project(context, project))

  invisible(context$rc)
}


# Dispatch one selected project to the build implementation for its type.
.build_project = function(context, project) {
  project = .prepare_project_config(project)
  message("Building: ", project$path, " [", project$config$type, "]")

  if (identical(project$config$type, .IASI$types$pkg)) return(.build_package_project(context, project))
  .build_quarto_project(context, project)
}
