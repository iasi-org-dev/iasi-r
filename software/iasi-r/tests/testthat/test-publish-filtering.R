test_that("publish ignores generated IASI trees recursively", {
  root = tempfile("iasi-publish-source-")
  source = file.path(root, "_outputs", "html")
  destination = file.path(root, "copy", "html")

  dir.create(file.path(source, "assets"), recursive = TRUE)
  dir.create(file.path(source, "release", "iasi-book", "_publish", "nested"), recursive = TRUE)
  dir.create(file.path(source, "_publish", "nested"), recursive = TRUE)
  dir.create(file.path(source, "_outputs", "html"), recursive = TRUE)

  writeLines("index", file.path(source, "index.html"))
  writeLines("asset", file.path(source, "assets", "site.css"))
  writeLines("bad", file.path(source, "release", "iasi-book", "_publish", "nested", "bad.txt"))
  writeLines("bad", file.path(source, "_publish", "nested", "bad.txt"))
  writeLines("bad", file.path(source, "_outputs", "html", "bad.txt"))

  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  project = list(config = list(paths = list(publish = "_publish", release = "release")))
  iasi:::.copy_publish_directory(source, destination, project)

  expect_true(file.exists(file.path(destination, "index.html")))
  expect_true(file.exists(file.path(destination, "assets", "site.css")))
  expect_false(dir.exists(file.path(destination, "release")))
  expect_false(dir.exists(file.path(destination, "_publish")))
  expect_false(dir.exists(file.path(destination, "_outputs")))
})


test_that("generated IASI directories are never treated as publish formats", {
  root = tempfile("iasi-publish-formats-")
  dir.create(file.path(root, "html"), recursive = TRUE)
  dir.create(file.path(root, "release"), recursive = TRUE)
  dir.create(file.path(root, "_publish"), recursive = TRUE)
  dir.create(file.path(root, "_outputs"), recursive = TRUE)

  writeLines("index", file.path(root, "html", "index.html"))
  writeLines("bad", file.path(root, "release", "bad.txt"))
  writeLines("bad", file.path(root, "_publish", "bad.txt"))
  writeLines("bad", file.path(root, "_outputs", "bad.txt"))

  withr::defer(unlink(root, recursive = TRUE, force = TRUE))

  expect_identical(iasi:::.publish_format_directories(root), "html")
})
