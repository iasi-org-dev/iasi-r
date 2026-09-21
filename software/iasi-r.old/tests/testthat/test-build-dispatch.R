test_that("build dispatches by IASI project type before Quarto format resolution", {
  body_text = paste(deparse(body(iasi.quarto:::.build_project)), collapse = "\n")

  expect_match(body_text, "\\.IASI\\$types\\$pkg")
  expect_match(body_text, "\\.build_package_project")
  expect_false(grepl("\\.resolve_build_formats", body_text))
})


test_that("book is a supported IASI Quarto project type", {
  expect_identical(iasi.quarto:::.IASI$types$book, "book")
  expect_true("book" %in% iasi.quarto:::.IASI$targets$validate)
  expect_true("book" %in% iasi.quarto:::.IASI$targets$build)
  expect_true("book" %in% iasi.quarto:::.IASI$targets$publish)
  expect_true("book" %in% iasi.quarto:::.IASI$targets$release)

  body_text = paste(deparse(body(iasi.quarto:::.build_project)), collapse = "\n")
  expect_match(body_text, "\\.IASI\\$types\\$book")
})


test_that("build returns an error RC when a discovered IASI project is invalid", {
  root = tempfile("iasi-invalid-build-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  writeLines("type: invalid", file.path(root, "_iasi.yml"))

  rc = suppressMessages(iasi.quarto::build(path = root))

  expect_true(bitwAnd(rc, iasi.quarto:::.IASI$status$ATTENTION) != 0L)
  expect_true(bitwAnd(rc, iasi.quarto:::.IASI$status$ERROR) != 0L)
})


test_that("build with no IASI projects remains nothing-to-do, not an error", {
  root = tempfile("iasi-empty-build-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  rc = suppressMessages(iasi.quarto::build(path = root))

  expect_true(bitwAnd(rc, iasi.quarto:::.IASI$status$NOTHING_TO_DO) != 0L)
  expect_identical(bitwAnd(rc, iasi.quarto:::.IASI$status$ERROR_MASK), 0L)
})

