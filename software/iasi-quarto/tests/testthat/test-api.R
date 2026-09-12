test_that("status constants are numeric bitmasks", {
  expect_identical(iasi.quarto:::.IASI$status$OK, 0x00L)
  expect_identical(iasi.quarto:::.IASI$status$ERROR, 0x10L)
})

test_that("deploy is not public", {
  expect_false("deploy" %in% getNamespaceExports("iasi.quarto"))
})
