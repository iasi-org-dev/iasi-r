test_that("publication strategy is nested under publication", {
  config = list(
    type = "quarto",
    publication = list(strategy = "parted")
  )

  expect_identical(iasi:::.config_publication_strategy(config), "parted")
})


test_that("top-level strategy is not a publication strategy", {
  config = list(type = "quarto", strategy = "parted")
  expect_null(iasi:::.config_publication_strategy(config))
})


test_that("Quarto normalization does not invent a publication strategy", {
  config = iasi:::.normalise_iasi_config(list(publication = list()), "book")
  expect_null(config$publication$strategy)
  expect_identical(config$publication$`content-dir`, "chapters")
})



test_that("Quarto project discovery reads publication.strategy", {
  root = tempfile("iasi-strategy-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  writeLines(
    c("project:", "  type: book"),
    file.path(root, "_quarto.yml")
  )

  writeLines(
    c("type: quarto", "", "publication:", "  strategy: parted"),
    file.path(root, "_iasi.yml")
  )

  project = iasi:::.discover_project(root)
  expect_identical(project$strategy, "parted")
})


test_that("build and publish do not read root config strategy", {
  build_body = paste(deparse(body(iasi:::.build_quarto_project)), collapse = "\n")
  publish_body = paste(deparse(body(iasi:::.publish_applicable)), collapse = "\n")

  expect_false(grepl("project\\$config\\$strategy", build_body))
  expect_false(grepl("project\\$config\\$strategy", publish_body))
  expect_match(build_body, "quarto\\$strategy")
  expect_match(publish_body, "config_publication_strategy")
})


test_that("obsolete top-level strategy is rejected", {
  root = tempfile("iasi-obsolete-strategy-")
  dir.create(root)
  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  writeLines(
    c("project:", "  type: book"),
    file.path(root, "_quarto.yml")
  )

  writeLines(
    c("type: quarto", "strategy: parted"),
    file.path(root, "_iasi.yml")
  )

  project = iasi:::.discover_project(root)
  project$iasi_type = "quarto"
  checked = iasi:::.check_project(project)

  expect_false(checked$valid)
  expect_true(any(grepl("publication.strategy", checked$errors, fixed = TRUE)))
})
