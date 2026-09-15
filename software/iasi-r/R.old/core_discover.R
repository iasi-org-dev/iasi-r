.discover = function(context) {
  root = normalizePath(context$path, winslash = "/", mustWork = TRUE)

  directories = c(
    root,
    list.dirs(
      root,
      recursive = TRUE,
      full.names = TRUE
    )
  )

  directories = unique(
    normalizePath(
      directories,
      winslash = "/",
      mustWork = TRUE
    )
  )

  relative = vapply(
    directories,
    function(path) {
      if (identical(tolower(path), tolower(root))) {
        return(".")
      }

      substring(path, nchar(root) + 2L)
    },
    character(1)
  )

  excluded = grepl(
    "(^|/)(\\.git|tests|\\.Rcheck|\\.Rproj\\.user|\\.quarto|_freeze|_generated|_outputs)(/|$)",
    relative,
    ignore.case = TRUE
  )

  directories = directories[!excluded]

  projects = directories[
    vapply(
      directories,
      function(path) {
        candidates = file.path(path, .IASI$files$iasi)
        any(file.exists(candidates))
      },
      logical(1)
    )
  ]

  sort(unique(projects))
}
