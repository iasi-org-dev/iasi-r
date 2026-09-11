.engine_release = function(context) {
  context = .prepare_context(context)
  lapply(context$projects, function(project) .release_project(context, project))
  invisible(context$rc)
}


.release_project = function(context, project) {
  project = .prepare_project_config(project)

  message("Release project: ", project$path, " [", project$config$type, "]")

  if (identical(project$config$type, .IASI$types$pkg)) return(.release_package(context, project))
  .release_published(context, project)
}


.release_package = function(context, project) {
  release = .release_path(project)

  artifacts = list.files(project$path, pattern = "(\\.tar\\..+|\\.zip)$", full.names = TRUE, recursive = FALSE)

  if (!length(artifacts)) {
    message("No package artifacts found in: ", project$path)
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  dir.create(release, recursive = TRUE, showWarnings = FALSE)

  moved = file.rename(artifacts, file.path(release, basename(artifacts)))

  if (!all(moved)) {
    message("Unable to move one or more package artifacts from: ", project$path)
    stop("Package release failed.", call. = FALSE)
  }

  invisible(context$rc)
}


.release_published = function(context, project) {
  release = .release_path(project)

  quarto = .as_quarto_project(project)
  source = .publish_destination(quarto)

  if (!dir.exists(source)) {
    message("No published content found in: ", source)
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  entries = list.files(source, full.names = TRUE, all.files = TRUE, no.. = TRUE)

  if (!length(entries)) {
    message("No published content found in: ", source)
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  target = if (identical(project$config$type, .IASI$types$web)) release else file.path(release, sub("^[0-9]+-", "", basename(quarto$path)))

  dir.create(target, recursive = TRUE, showWarnings = FALSE)

  copied = file.copy(entries, target, recursive = TRUE, overwrite = TRUE, copy.mode = TRUE, copy.date = TRUE)

  if (!all(copied)) {
    message("Unable to copy one or more published artifacts from: ", source)
    stop("Published release failed.", call. = FALSE)
  }

  invisible(context$rc)
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

    if (!is.null(config) && is.list(config$paths) && !is.null(config$paths[[key]])) return(current)

    parent = dirname(current)
    if (identical(parent, current)) return(path)
    current = parent
  }
}
