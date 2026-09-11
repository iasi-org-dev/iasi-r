#' Validate IASI projects
#'
#' @param path Directory from which IASI projects are discovered.
#' @return Numeric status code. `0` means success.
#' @export
validate = function(path = ".") {
  context = list(action = "validate", path = path)

  rc = tryCatch(
    {
      .engine_validate(context)
    },
    error = function(error) {
      .IASI$status$ERROR
    }
  )

  invisible(rc)
}


#' Build IASI projects
#'
#' Builds every selected IASI project to which the build action applies.
#'
#' Calling `build()` always performs the build. The function does not decide
#' whether a project needs rebuilding.
#'
#' @param format Optional Quarto format/profile selection.
#' @param path Directory from which IASI projects are discovered.
#' @return Numeric status code. `0` means success.
#' @export
build = function(format = NULL, path = ".") {
  context = list(
    action = "build",
    format = format,
    path = path
  )

  rc = tryCatch(
    {
      .engine_build(context)
    },
    error = function(error) {
      .IASI$status$ERROR
    }
  )

  invisible(rc)
}


#' Publish built IASI projects locally
#'
#' Publishes selected build outputs from `_outputs` only when their content
#' changed, unless `force = TRUE`.
#'
#' @param path Directory from which IASI projects are discovered.
#' @param force Publish even when the build-output hash has not changed.
#' @return Numeric status code. `0` means success.
#' @export
publish = function(path = ".", force = FALSE) {
  context = list(action = "publish", path = path, force = force)

  rc = tryCatch(
    .engine_publish(context),
    error = function(error) .IASI$status$ERROR
  )

  invisible(rc)
}


#' Collect local IASI release artifacts
#'
#' @param path Directory from which IASI projects are discovered.
#' @return Numeric status code. `0` means success.
#' @export
release = function(path = ".") {
  context = list(action = "release", path = path)

  rc = tryCatch(
    .engine_release(context),
    error = function(error) .IASI$status$ERROR
  )

  invisible(rc)
}
