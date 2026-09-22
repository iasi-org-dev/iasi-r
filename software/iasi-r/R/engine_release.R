.engine_release = function(context) {
  context = .prepare_context(context)
  lapply(context$projects, function(project) .release_project(context, project))
  invisible(context$rc)
}


.release_project = function(context, project) {
  project = .prepare_project_config(project)
  type = project$config$type

  message("Release project: ", project$path, " [", type, "]")

  if (identical(type, .IASI$types$pkg)) return(.release_package(context, project))

  if (.publish_applicable(project)) {
    root = identical(type, .IASI$types$web)
    return(.release_tree(context, project, project$config$paths$publish, root = root))
  }

  if (identical(type, .IASI$types$quarto)) {
    return(.release_tree(context, project, .IASI$dirs$output, root = FALSE))
  }

  .rc_add(context, .IASI$status$NOTHING_TO_DO)
  invisible(context$rc)
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


.release_tree = function(context, project, source, root) {
  source = .release_source_path(project, source)

  if (!dir.exists(source)) {
    message("No release content found in: ", source)
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  entries = list.files(source, full.names = TRUE, all.files = TRUE, no.. = TRUE)

  if (!length(entries)) {
    message("No release content found in: ", source)
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  release = .release_path(project)
  target = if (root) release else file.path(release, sub("^[0-9]+-", "", basename(project$path)))
  dir.create(target, recursive = TRUE, showWarnings = FALSE)

  copied = file.copy(entries, target, recursive = TRUE, overwrite = TRUE, copy.mode = TRUE, copy.date = TRUE)

  if (!all(copied)) {
    message("Unable to copy one or more release artifacts from: ", source)
    stop("Release failed.", call. = FALSE)
  }

  invisible(context$rc)
}


.release_source_path = function(project, source) {
  if (.is_absolute_path(source)) return(normalizePath(source, winslash = "/", mustWork = FALSE))

  base = if (identical(source, project$config$paths$publish)) {
    .config_base(project$path, "publish")
  } else {
    project$path
  }

  normalizePath(file.path(base, source), winslash = "/", mustWork = FALSE)
}


.release_path = function(project) {
  value = project$config$paths$release
  base = .config_base(project$path, "release", repository_fallback = TRUE)
  path = if (.is_absolute_path(value)) value else file.path(base, value)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}


.config_base = function(path, key, repository_fallback = FALSE) {
  current = path
  repository_base = NULL

  repeat {
    config = .read_optional_iasi(current)

    if (!is.null(config)) {
      if (is.list(config$paths) && !is.null(config$paths[[key]])) return(current)

      if (
        isTRUE(repository_fallback) &&
          is.null(repository_base) &&
          identical(config$type, .IASI$types$repo)
      ) {
        repository_base = current
      }
    }

    parent = dirname(current)
    if (identical(parent, current)) break
    current = parent
  }

  if (!is.null(repository_base)) return(repository_base)

  path
}
