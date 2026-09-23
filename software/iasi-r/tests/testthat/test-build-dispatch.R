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


test_that("build output cleanup removes the complete derived output tree", {
  root = tempfile("iasi-build-output-clean-")
  output = file.path(root, "_outputs")

  dir.create(file.path(output, "html", "site_libs"), recursive = TRUE)
  dir.create(file.path(output, "pdf"), recursive = TRUE)
  writeLines("old html", file.path(output, "html", "index.html"))
  writeLines("old pdf", file.path(output, "pdf", "book.pdf"))

  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  project = list(path = root)
  cleaned = iasi:::.clean_build_outputs(project)

  expect_identical(cleaned, file.path(root, "_outputs"))
  expect_false(dir.exists(output))
})


test_that("Quarto build cleans previous outputs before choosing a render path", {
  body_text = paste(deparse(body(iasi:::.build_quarto_project)), collapse = "\n")

  clean = regexpr("\\.clean_build_outputs\\(project\\)", body_text)[[1L]]
  plain = regexpr("\\.render_plain_quarto", body_text)[[1L]]
  prepared = regexpr("\\.prepare_project", body_text)[[1L]]

  expect_gt(clean, 0L)
  expect_gt(plain, clean)
  expect_gt(prepared, clean)
})
