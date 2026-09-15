test_that("write_if_changed writes generated files with LF line endings", {
  path = tempfile("iasi-lf-")
  withr::defer(unlink(path, force = TRUE))

  changed = .write_if_changed(c("one", "two"), path)

  expect_true(changed)
  expect_identical(
    readBin(path, what = "raw", n = file.info(path)$size),
    charToRaw("one\ntwo\n")
  )
})

test_that("write_if_changed normalises CRLF even when content is unchanged", {
  path = tempfile("iasi-crlf-")
  withr::defer(unlink(path, force = TRUE))

  connection = file(path, open = "wb")
  writeBin(charToRaw("one\r\ntwo\r\n"), connection)
  close(connection)

  expect_true(.write_if_changed(c("one", "two"), path))
  expect_identical(
    readBin(path, what = "raw", n = file.info(path)$size),
    charToRaw("one\ntwo\n")
  )
  expect_false(.write_if_changed(c("one", "two"), path))
})
