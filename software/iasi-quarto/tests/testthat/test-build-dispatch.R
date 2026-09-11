test_that("build dispatches by IASI project type before Quarto format resolution", {
  body_text = paste(deparse(body(iasi.quarto:::.build_project)), collapse = "\n")

  expect_match(body_text, "\\.IASI\\$types\\$pkg")
  expect_match(body_text, "\\.build_package_project")
  expect_false(grepl("\\.resolve_build_formats", body_text))
})
