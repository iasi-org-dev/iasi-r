test_that("public APIs return status invisibly", {
  # Structural regression test: public wrappers must finish with invisible(rc).
  api = readLines(system.file("R", "api.R", package = "iasi.quarto"), warn = FALSE)
  skip_if(!length(api))
  expect_gte(sum(grepl("invisible\\(rc\\)", api)), 4L)
})
