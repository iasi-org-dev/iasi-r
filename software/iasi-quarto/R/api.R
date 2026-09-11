# Run one public action while preserving the cumulative return-code mask.
.run_action = function(context, engine) {
  tryCatch(
    withCallingHandlers(
      engine(context),
      error = function(error) {
        if (bitwAnd(context$rc, .IASI$status$ERROR_MASK) == 0L) .rc_add(context, .IASI$status$ERROR)
      }
    ),
    error = function(error) NULL
  )

  invisible(context$rc)
}


#' Validate IASI projects
#'
#' @param path Directory from which IASI projects are discovered.
#' @return Numeric status bitmask.
#' @export
validate = function(path = ".") {
  context = .new_context(action = "validate", path = path)
  .run_action(context, .engine_validate)
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
#' @return Numeric status bitmask.
#' @export
build = function(format = NULL, path = ".") {
  context = .new_context(action = "build", format = format, path = path)
  .run_action(context, .engine_build)
}


#' Publish built IASI projects locally
#'
#' Publishes selected build outputs from `_outputs` only when their content
#' changed, unless `force = TRUE`.
#'
#' @param path Directory from which IASI projects are discovered.
#' @param force Publish even when the build-output hash has not changed.
#' @return Numeric status bitmask.
#' @export
publish = function(path = ".", force = FALSE) {
  context = .new_context(action = "publish", path = path, force = force)
  .run_action(context, .engine_publish)
}


#' Collect local IASI release artifacts
#'
#' @param path Directory from which IASI projects are discovered.
#' @return Numeric status bitmask.
#' @export
release = function(path = ".") {
  context = .new_context(action = "release", path = path)
  .run_action(context, .engine_release)
}
