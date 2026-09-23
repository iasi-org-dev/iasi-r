# Publish engine ----------------------------------------------------------
#
# publish() is meaningful only for Quarto projects that opt into an IASI
# publication strategy, plus IASI website projects. All other project types are
# valid calls with nothing to do.


.engine_publish = function(context) {
  context = .prepare_context(context)

  projects = lapply(context$projects, .prepare_project_config)
  projects = Filter(.publish_applicable, projects)

  if (!length(projects)) {
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  lapply(projects, function(project) {
    quarto = .as_quarto_project(project)
    quarto = .ensure_checked_project(quarto)
    .publish_project(context, quarto)
  })

  invisible(context$rc)
}


.publish_applicable = function(project) {
  if (identical(project$config$type, .IASI$types$web)) {
    return(TRUE)
  }

  identical(project$config$type, .IASI$types$quarto) &&
    !is.null(.config_publication_strategy(project$config))
}


.publish_project = function(context, project) {
  source = file.path(project$path, .IASI$dirs$output)
  formats = .resolve_publish_formats(source, context$format, project)

  if (!length(formats)) {
    message("No matching built formats to publish: ", project$path)
    .rc_add(context, .IASI$status$NOTHING_TO_DO)
    return(invisible(context$rc))
  }

  destination = .publish_destination(project)
  hash = .publish_hash(source, formats, project)

  .publish_project_to(
    project = project,
    destination = destination,
    hash = hash,
    formats = formats,
    clean = TRUE
  )

  invisible(context$rc)
}


.resolve_publish_formats = function(source, format = NULL, project = NULL) {
  if (!dir.exists(source)) return(character())

  available = .publish_format_directories(source, project)

  # A build root may contain stale directories left by an earlier plain Quarto
  # render. Only formats declared by the current Quarto project are publication
  # formats; arbitrary first-level directories are never promoted to formats.
  if (!is.null(project) && inherits(project, "iasi_quarto_project")) {
    declared = .resolve_project_build_formats(project, "all", warn = FALSE)
    available = intersect(declared, available)
  }

  selection = .normalise_build_selection(format, "format")

  if (identical(selection, "all")) return(available)

  missing = selection[!selection %in% available]
  if (length(missing)) {
    for (name in missing) warning(sprintf("Ignoring '%s': no built output is available.", name), call. = FALSE)
  }

  unique(selection[selection %in% available])
}


.write_publish_metadata = function(path, stamp, hash) {
  yaml::write_yaml(list(timestamp = as.character(stamp), hash = hash), file.path(path, ".publish"))
  invisible(TRUE)
}


.read_publish_metadata = function(path) {
  file = file.path(path, ".publish")
  if (!file.exists(file)) return(NULL)

  metadata = tryCatch(yaml::read_yaml(file), error = function(error) NULL)
  if (!is.list(metadata)) return(NULL)
  metadata
}


.publish_hash = function(path, formats, project = NULL) {
  path = normalizePath(path, winslash = "/", mustWork = TRUE)
  roots = file.path(path, formats)
  roots = roots[dir.exists(roots)]

  files = unlist(
    lapply(roots, .publish_tree_files, project = project),
    use.names = FALSE
  )
  files = sort(unique(files))

  relative = if (length(files)) substring(normalizePath(files, winslash = "/", mustWork = TRUE), nchar(path) + 2L) else character()
  hashes = if (length(files)) unname(tools::md5sum(files)) else character()
  manifest = paste(relative, hashes, sep = "\t")

  tmp = tempfile("iasi-publish-hash-")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(manifest, tmp, useBytes = TRUE)

  unname(tools::md5sum(tmp)[[1L]])
}
