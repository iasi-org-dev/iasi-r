test_that("status constants are numeric bitmasks", {
  expect_identical(iasi:::.IASI$status$OK, 0x00L)
  expect_identical(iasi:::.IASI$status$ERROR, 0x10L)
})


test_that("publish exposes only format and path", {
  expect_identical(names(formals(iasi::publish)), c("format", "path"))
  expect_null(formals(iasi::publish)$format)
  expect_identical(formals(iasi::publish)$path, ".")
})
