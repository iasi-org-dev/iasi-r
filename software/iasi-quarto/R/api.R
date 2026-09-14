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
#' Publishes one or more already-built formats from `_outputs` into the local
#' publication tree. `publish()` never renders sources again.
#'
#' When `format` is `NULL`, every available built format is published. When one
#' or more formats are supplied, only those existing build outputs are used.
#'
#' @param format Optional built format/profile selection.
#' @param path Directory from which IASI projects are discovered.
#' @return Numeric status bitmask.
#' @export
publish = function(format = NULL, path = ".") {
  context = .new_context(action = "publish", format = format, path = path)
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
