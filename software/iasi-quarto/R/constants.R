# Internal IASI Quarto constants.
#
# Canonical names and defaults used by the package live here so engines do not
# scatter protocol strings and filesystem conventions through their code.

.IASI = list(
  status = list(
    OK = 0L,
    ERROR = 1L
  ),

  files = list(
    iasi = c("_iasi.yml", ".iasi.yml")
  ),

  dirs = list(
    output = "_outputs",
    publish = "_publish",
    release = "release"
  ),

  types = list(
    repo = "repository",
    guide = "guide",
    web = "web",
    pkg = "r-package"
  ),

  targets = list(
    validate = c("guide", "web", "r-package"),
    build = c("guide", "web", "r-package"),
    publish = c("guide", "web"),
    release = c("guide", "web", "r-package")
  )
)
