test_that("status constants are numeric", {
  expect_identical(iasi.quarto:::.IASI$status$OK, 0L)
  expect_identical(iasi.quarto:::.IASI$status$ERROR, 1L)
})

test_that("deploy is not public", {
  expect_false("deploy" %in% getNamespaceExports("iasi.quarto"))
})
