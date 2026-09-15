# Create the mutable execution context used by every public action.
.new_context = function(...) {
  context = list2env(list(...), parent = emptyenv())
  context$rc = .IASI$status$OK
  context
}


# Accumulate one return-code bit or mask in the execution context.
.rc_add = function(context, rc) {
  context$rc = bitwOr(as.integer(context$rc), as.integer(rc))
  invisible(context$rc)
}


.prepare_context = function(context) {
  context$path = normalizePath(context$path, winslash = "/", mustWork = TRUE)
  context$plan = .discover(context)
  context$projects = .select_projects(context)
  context$current = length(context$projects) == 1L && identical(context$projects[[1L]]$path, context$path)
  context
}


.select_projects = function(context) {
  if (!length(context$plan)) {
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(list())
  }

  projects = lapply(context$plan, function(path) .read_iasi_project(path, context))
  projects = Filter(Negate(is.null), projects)

  selected = Filter(
    function(project) !identical(project$config$type, .IASI$types$repo),
    projects
  )

  if (!length(selected)) .rc_add(context, .IASI$status$NOTHING_TO_DO)

  selected
}


.read_iasi_project = function(path, context) {
  config_file = .iasi_file(path, required = TRUE)
  config = .read_config(config_file)

  type = config$type

  if (is.null(type) || !is.character(type) || length(type) != 1L || is.na(type) || !nzchar(type)) {
    message("ATTENTION: Missing project type in: ", config_file)
    .rc_add(context, .IASI$status$ATTENTION)
    return(NULL)
  }

  valid = unname(unlist(.IASI$types, use.names = FALSE))

  if (!type %in% valid) {
    message("ATTENTION: Invalid project type '", type, "' in: ", config_file)
    .rc_add(context, .IASI$status$ATTENTION)
    return(NULL)
  }

  project = list(
    name = basename(path),
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    config_file = normalizePath(config_file, winslash = "/", mustWork = TRUE),
    config = config
  )

  class(project) = c("iasi_project", "list")
  project
}


.prepare_project_config = function(project) {
  project$config = .resolve_config(project)
  project
}


.resolve_config = function(project) {
  config = project$config
  path = dirname(project$path)

  repeat {
    inherited = .read_optional_iasi(path)

    if (!is.null(inherited)) config = .merge_missing(config, inherited)

    parent = dirname(path)
    if (identical(parent, path)) break
    path = parent
  }

  if (is.null(config$paths)) config$paths = list()
  if (identical(config$type, .IASI$types$pkg) && is.null(config$paths$output)) config$paths$output = "."
  if (is.null(config$paths$publish)) config$paths$publish = .IASI$dirs$publish
  if (is.null(config$paths$release)) config$paths$release = .IASI$dirs$release

  config
}


.merge_missing = function(target, source) {
  if (!is.list(source)) return(target)

  for (name in names(source)) {
    if (is.null(target[[name]])) {
      target[[name]] = source[[name]]
    } else if (is.list(target[[name]]) && is.list(source[[name]])) {
      target[[name]] = .merge_missing(target[[name]], source[[name]])
    }
  }

  target
}


.read_optional_iasi = function(path) {
  file = .iasi_file(path)
  if (is.null(file)) return(NULL)
  .read_config(file)
}


.iasi_file = function(path, required = FALSE) {
  candidates = file.path(path, .IASI$files$iasi)
  found = candidates[file.exists(candidates)]

  if (length(found) > 1L) {
    message("Multiple IASI configuration files found in: ", path)
    stop("IASI configuration is ambiguous.", call. = FALSE)
  }

  if (!length(found)) {
    if (required) {
      message("IASI configuration not found in: ", path)
      stop("IASI configuration not found.", call. = FALSE)
    }

    return(NULL)
  }

  found[[1L]]
}


.read_config = function(path) {
  config = tryCatch(
    yaml::read_yaml(path),
    error = function(error) {
      message("Invalid IASI configuration: ", path, ": ", conditionMessage(error))
      stop(error)
    }
  )

  if (is.null(config)) config = list()

  if (!is.list(config)) {
    message("IASI configuration must be a mapping: ", path)
    stop("Invalid IASI configuration.", call. = FALSE)
  }

  config
}
