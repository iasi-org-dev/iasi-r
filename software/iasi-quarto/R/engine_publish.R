# Publish engine ----------------------------------------------------------
#
# prepare_context() supplies the publish targets. Each target is converted to
# the existing Quarto publication model, hashed, materialised in a temporary
# tree, post-processed, and atomically installed in its final destination.


# Publish every selected target.
.engine_publish = function(context) {
  context = .prepare_context(context)
  if (!length(context$projects)) return(.IASI$status$OK)

  results = lapply(context$projects, function(project) {
    project = .prepare_project_config(project)
    quarto = .as_quarto_project(project)
    quarto = .ensure_checked_project(quarto)
    .publish_project(context, quarto)
  })

  if (length(results) && any(unlist(results) != .IASI$status$OK)) return(.IASI$status$ERROR)

  .IASI$status$OK
}


# Publish one target from its `_outputs` directory unless unchanged.
.publish_project = function(context, project) {
  source = file.path(project$path, .IASI$dirs$output)
  destination = .publish_destination(project)
  hash = .publish_hash(source)

  if (!isTRUE(context$force) && .publish_unchanged(destination, hash)) {
    message("Publication unchanged: ", project$path)
    return(.IASI$status$OK)
  }

  project = .publish_project_to(project = project, destination = destination, hash = hash, clean = TRUE)

  .IASI$status$OK
}


# Publish metadata --------------------------------------------------------

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


.publish_unchanged = function(path, hash) {
  metadata = .read_publish_metadata(path)
  !is.null(metadata) && identical(as.character(metadata$hash), as.character(hash))
}


.publish_hash = function(path) {
  path = normalizePath(path, winslash = "/", mustWork = TRUE)
  files = list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  files = sort(files[file.exists(files) & !dir.exists(files)])

  relative = if (length(files)) substring(normalizePath(files, winslash = "/", mustWork = TRUE), nchar(path) + 2L) else character()
  hashes = if (length(files)) unname(tools::md5sum(files)) else character()
  manifest = paste(relative, hashes, sep = "	")

  tmp = tempfile("iasi-publish-hash-")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(manifest, tmp, useBytes = TRUE)

  unname(tools::md5sum(tmp)[[1L]])
}
