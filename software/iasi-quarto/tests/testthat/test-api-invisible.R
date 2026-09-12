test_that("public APIs delegate through the cumulative RC runner", {
  body_text = paste(deparse(body(iasi.quarto:::.run_action)), collapse = "\n")
  expect_match(body_text, "invisible\\(context\\$rc\\)")

  for (name in c("validate", "build", "publish", "release")) {
    fn = getExportedValue("iasi.quarto", name)
    expect_match(paste(deparse(body(fn)), collapse = "\n"), "\\.run_action")
  }
})
