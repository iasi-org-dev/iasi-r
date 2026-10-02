.write_if_changed = function(content, path) {
  content = enc2utf8(content)

  text = if (length(content)) {
    paste0(
      paste(content, collapse = "\n"),
      "\n"
    )
  } else {
    ""
  }

  expected = charToRaw(text)
  current = if (file.exists(path)) {
    size = file.info(path)$size
    readBin(path, what = "raw", n = size)
  } else {
    raw()
  }

  if (identical(current, expected)) {
    return(FALSE)
  }

  dir.create(
    dirname(path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  connection = file(path, open = "wb")
  on.exit(close(connection), add = TRUE)

  writeBin(expected, connection)

  TRUE
}
