# Internal IASI Quarto constants.
#
# Canonical names and defaults used by the package live here so engines do not
# scatter protocol strings and filesystem conventions through their code.

.IASI = list(
  status = list(
    OK = 0x00L,
    NOTHING_TO_DO = 0x01L,
    INFO = 0x02L,
    WARNING = 0x04L,
    ATTENTION = 0x08L,
    ERROR = 0x10L,
    SEVERE = 0x20L,
    FATAL = 0x40L,
    NOTICE_MASK = 0x0FL,
    ERROR_MASK = 0xF0L
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
    repo  = "repository",
    guide = "guide",
    web   = "web",
    pkg   = "r-package",
    book  = "book"
  )
)
