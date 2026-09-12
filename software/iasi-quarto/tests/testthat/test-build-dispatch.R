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
