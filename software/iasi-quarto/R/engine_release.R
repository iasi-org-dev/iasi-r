.engine_release = function(context) {
  context = .prepare_context(context)

  results = lapply(context$projects, function(project) .release_project(context, project))

  if (length(results) && any(unlist(results) != .IASI$status$OK)) return(.IASI$status$ERROR)

  .IASI$status$OK
}


.release_project = function(context, project) {
  project = .prepare_project_config(project)

  message("Release project: ", project$path, " [", project$config$type, "]")

  if (identical(project$config$type, .IASI$types$pkg)) return(.release_package(context, project))

  .release_published(context, project)
}


.release_package = function(context, project) {
  release = .release_path(project)

  artifacts = list.files(
    project$path,
    pattern = "(\\.tar\\..+|\\.zip)$",
    full.names = TRUE,
    recursive = FALSE
  )

  if (!length(artifacts)) {
    message("No package artifacts found in: ", project$path)
    return(.IASI$status$OK)
  }

  dir.create(release, recursive = TRUE, showWarnings = FALSE)

  moved = file.rename(
    artifacts,
    file.path(release, basename(artifacts))
  )

  if (!all(moved)) {
    message("Unable to move one or more package artifacts from: ", project$path)
    stop("Package release failed.", call. = FALSE)
  }

  .IASI$status$OK
}


.release_published = function(context, project) {
  release = .release_path(project)

  quarto = .as_quarto_project(project)
  publish_context = context
  publish_context$projects = list(quarto)
  publish_context$current = identical(context$path, project$path)

  source = .publish_destination(publish_context, quarto)

  if (!dir.exists(source)) {
    message("No published content found in: ", source)
    return(.IASI$status$OK)
  }

  entries = list.files(source, full.names = TRUE, all.files = TRUE, no.. = TRUE)

  if (!length(entries)) {
    message("No published content found in: ", source)
    return(.IASI$status$OK)
  }

  target = if (identical(project$config$type, .IASI$types$web)) {
    release
  } else {
    file.path(release, .publish_slot(quarto))
  }

  dir.create(target, recursive = TRUE, showWarnings = FALSE)

  copied = file.copy(
    entries,
    target,
    recursive = TRUE,
    overwrite = TRUE,
    copy.mode = TRUE,
    copy.date = TRUE
  )

  if (!all(copied)) {
    message("Unable to copy one or more published artifacts from: ", source)
    stop("Published release failed.", call. = FALSE)
  }

  .IASI$status$OK
}


.release_path = function(project) {
  value = project$config$paths$release
  base = .config_base(project$path, "release")

  path = if (.is_absolute_path(value)) value else file.path(base, value)

  normalizePath(path, winslash = "/", mustWork = FALSE)
}


.config_base = function(path, key) {
  current = path

  repeat {
    config = .read_optional_iasi(current)

    if (!is.null(config) && is.list(config$paths) && !is.null(config$paths[[key]])) {
      return(current)
    }

    parent = dirname(current)

    if (identical(parent, current)) {
      return(path)
    }

    current = parent
  }
}
