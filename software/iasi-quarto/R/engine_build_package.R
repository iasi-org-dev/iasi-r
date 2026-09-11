# R package build --------------------------------------------------------

# Build both source and binary artifacts for an R package.
.build_package_project = function(context, project) {
  previous = setwd(project$path)
  on.exit(setwd(previous), add = TRUE)

  r = file.path(R.home("bin"), "R")

  source_status = system2(
    r,
    c("CMD", "build", ".")
  )

  if (!identical(source_status, 0L)) {
    message("R package source build failed in: ", project$path)
    stop("R package source build failed.", call. = FALSE)
  }

  source = .latest_package_source(project$path)

  if (is.null(source)) {
    message("R package source artifact not found in: ", project$path)
    stop("R package source artifact not found.", call. = FALSE)
  }

  binary_status = system2(
    r,
    c("CMD", "INSTALL", "--build", source)
  )

  if (!identical(binary_status, 0L)) {
    message("R package binary build failed in: ", project$path)
    stop("R package binary build failed.", call. = FALSE)
  }

  .IASI$status$OK
}


# Return the most recently generated source package archive.
.latest_package_source = function(path) {
  files = list.files(
    path,
    pattern = "\\.tar\\.gz$",
    full.names = TRUE,
    recursive = FALSE
  )

  if (!length(files)) {
    return(NULL)
  }

  info = file.info(files)

  files[[which.max(info$mtime)]]
}
