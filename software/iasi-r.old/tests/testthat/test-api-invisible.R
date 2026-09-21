test_that("public APIs delegate through the cumulative RC runner", {
  body_text = paste(deparse(body(iasi.quarto:::.run_action)), collapse = "\n")
  expect_match(body_text, "invisible\\(context\\$rc\\)")

  for (name in c("validate", "build", "publish", "release")) {
    fn = getExportedValue("iasi.quarto", name)
    expect_match(paste(deparse(body(fn)), collapse = "\n"), "\\.run_action")
  }
})


test_that("public action errors remain visible while returning the error RC", {
  context = iasi.quarto:::.new_context(action = "test", path = ".")
  engine = function(context) stop("visible failure", call. = FALSE)

  rc = NULL
  expect_message(
    rc = iasi.quarto:::.run_action(context, engine),
    "ERROR: visible failure",
    fixed = TRUE
  )

  expect_true(bitwAnd(rc, iasi.quarto:::.IASI$status$ERROR) != 0L)
})
