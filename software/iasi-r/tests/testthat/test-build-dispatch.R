test_that("build dispatches packages before Quarto", {
  body_text = paste(deparse(body(iasi:::.build_project)), collapse = "\n")

  expect_match(body_text, "\\.IASI\\$types\\$pkg")
  expect_match(body_text, "\\.build_package_project")
  expect_match(body_text, "\\.build_quarto_project")
})


test_that("build returns an error RC when a discovered IASI project is invalid", {
  root = tempfile("iasi-invalid-build-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  writeLines("type: invalid", file.path(root, "_iasi.yml"))

  rc = suppressMessages(iasi::build(path = root))

  expect_true(bitwAnd(rc, iasi:::.IASI$status$ATTENTION) != 0L)
  expect_true(bitwAnd(rc, iasi:::.IASI$status$ERROR) != 0L)
})


test_that("build with no IASI projects remains nothing-to-do, not an error", {
  root = tempfile("iasi-empty-build-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  rc = suppressMessages(iasi::build(path = root))

  expect_true(bitwAnd(rc, iasi:::.IASI$status$NOTHING_TO_DO) != 0L)
  expect_identical(bitwAnd(rc, iasi:::.IASI$status$ERROR_MASK), 0L)
})
