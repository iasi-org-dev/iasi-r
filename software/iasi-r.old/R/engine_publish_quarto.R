# Quarto publish ----------------------------------------------------------
#
# Existing publication pipeline, adapted to the current context/project model.
#
# Flow:
# build output -> unique sibling temporary tree -> post-process -> metadata -> replace target.
# The final publication is never modified until the temporary tree is complete.

.export_formats = c(pdf = "PDF", pdfua = "PDF/UA", epub = "EPUB", docx = "DOCX", odt = "ODT", git = "GitBook")

.publish_root_profiles = c("web", "html")

# Each project owns its publication tree. The destination is resolved from the
# project/configuration root only; build-format directories never participate in
# destination resolution. release() assembles project publications later.
.publish_destination = function(project) {
  value = project$config$paths$publish
  base = .config_base(project$path, "publish")
  path = if (.is_absolute_path(value)) value else file.path(base, value)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}


# Materialise one publication atomically. The source tree is never modified:
# work happens in a unique temporary directory beside the final destination so
# the final rename remains on the same filesystem.
.publish_project_to = function(project, destination, hash, formats, clean = TRUE) {
  source_path = file.path(project$path, .IASI$dirs$output)

  .check_publish_tree(source = source_path, destination = destination, project = project$name)

  source_formats = intersect(formats, .publish_format_directories(source_path, project))

  if (!length(source_formats)) stop(sprintf("Publish source contains no selected non-empty format directories for project '%s': %s.", project$name, source_path), call. = FALSE)

  if (clean) {
    work_path = .publish_temporary_path(destination)
    dir.create(work_path, recursive = TRUE, showWarnings = FALSE)

    on.exit(
      if (dir.exists(work_path)) {
        unlink(work_path, recursive = TRUE, force = TRUE)
      },
      add = TRUE
    )

    .prepare_publish_tree(source = source_path, destination = work_path, project = project, hash = hash, formats = source_formats)

    .replace_publish_tree(work = work_path, destination = destination)
  } else {
    dir.create(destination, recursive = TRUE, showWarnings = FALSE)

    .prepare_publish_tree(source = source_path, destination = destination, project = project, hash = hash, formats = source_formats)
  }

  project$publish_path = .normalise_project_path(destination)

  project$publish_outputs = source_formats
  project$published = TRUE

  project
}


# Create a unique staging path beside the final publication. Keeping staging on
# the same filesystem preserves rename semantics while avoiding a shared fixed
# `_publish.work` directory across runs.
.publish_temporary_path = function(destination) {
  parent = dirname(destination)
  dir.create(parent, recursive = TRUE, showWarnings = FALSE)

  tempfile(
    pattern = paste0(".", basename(destination), "-"),
    tmpdir = parent
  )
}

# Copy one complete build tree, apply strategy-specific normalisation, move
# the preferred browser-facing profile into the publication root, and stamp metadata.
.prepare_publish_tree = function(source, destination, project, hash, formats) {
  message("- Preparando árbol de publicación...")

  for (format in formats) {
    source_format = file.path(source, format)
    destination_format = file.path(destination, format)

    .copy_publish_directory(
      from = source_format,
      to = destination_format,
      project = project
    )
  }

  formats = .publish_format_directories(destination, project)

  publication = .publication_info(project)

  message(sprintf("- Normalizando salida [%s]...", project$strategy))

  .normalise_publish_tree(path = destination, project = project, formats = formats)

  message("- Organizando formatos...")

  .move_publish_primary_to_root(destination)
  .normalise_publish_exports(destination)
  .sync_export_anchors(destination)

  message("- Aplicando metadatos...")

  .normalise_publication(path = destination, project = project, formats = formats, publication = publication)

  .write_publish_metadata(destination, publication$stamp, hash)

  message("- Publicación preparada.")

  invisible(TRUE)
}

# Replace only the target publication. This is what lets multiproject publish
# update `user-guide/` without touching sibling publication slots.
.replace_publish_tree = function(work, destination) {
  if (dir.exists(destination)) unlink(destination, recursive = TRUE, force = TRUE)
  if (!file.rename(work, destination)) stop(sprintf("Could not replace publish directory '%s'.", destination), call. = FALSE)

  invisible(TRUE)
}

# Source and destination must be disjoint trees. Publishing inside the build
# output is rejected explicitly because it creates recursive/self-copy hazards.
.check_publish_tree = function(source, destination, project) {
  if (!dir.exists(source)) stop(sprintf("Publish source does not exist for project '%s': %s.", project, source), call. = FALSE)

  source_path = normalizePath(source, winslash = "/", mustWork = TRUE)

  destination_path = normalizePath(destination, winslash = "/", mustWork = FALSE)

  source_key = tolower(source_path)
  destination_key = tolower(destination_path)

  source_prefix = paste0(source_key, "/")

  destination_prefix = paste0(destination_key, "/")

  invalid_overlap =
    identical(source_key, destination_key) ||
    startsWith(source_prefix, destination_prefix) ||
    startsWith(destination_prefix, source_prefix)

  if (invalid_overlap) {
    stop(sprintf("Publish source overlaps destination for project '%s'.", project), call. = FALSE)
  }

  invisible(TRUE)
}

# Only non-empty first-level directories are publication formats. Empty output
# directories are not evidence that a format was successfully built.
.publish_reserved_directory_names = function(project = NULL) {
  names = c(
    .IASI$dirs$output,
    .IASI$dirs$publish,
    .IASI$dirs$release,
    paste0(.IASI$dirs$publish, ".work")
  )

  if (!is.null(project) && is.list(project$config$paths)) {
    configured = unname(unlist(project$config$paths[c("publish", "release")], use.names = FALSE))
    configured = configured[is.character(configured) & !is.na(configured) & nzchar(configured)]

    if (length(configured)) {
      names = c(names, basename(gsub("\\\\", "/", configured)))
    }
  }

  unique(tolower(names[nzchar(names)]))
}


.publish_skip_directory = function(path, project = NULL) {
  tolower(basename(path)) %in% .publish_reserved_directory_names(project)
}


.publish_tree_files = function(path, project = NULL) {
  if (!dir.exists(path)) return(character())

  entries = list.files(path, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  if (!length(entries)) return(character())

  directories = entries[dir.exists(entries)]
  directories = directories[!vapply(directories, .publish_skip_directory, logical(1), project = project)]

  files = entries[!dir.exists(entries)]
  files = files[basename(files) != ".publish"]

  nested = if (length(directories)) {
    unlist(lapply(directories, .publish_tree_files, project = project), use.names = FALSE)
  } else {
    character()
  }

  c(files, nested)
}


.copy_publish_directory = function(from, to, project = NULL) {
  if (!dir.exists(from)) {
    stop(sprintf("Publish format source does not exist: %s.", from), call. = FALSE)
  }

  dir.create(to, recursive = TRUE, showWarnings = FALSE)

  entries = list.files(from, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  if (!length(entries)) return(invisible(TRUE))

  for (entry in entries) {
    target = file.path(to, basename(entry))

    if (dir.exists(entry)) {
      if (.publish_skip_directory(entry, project)) next
      .copy_publish_directory(entry, target, project)
      next
    }

    if (identical(basename(entry), ".publish")) next

    copied = file.copy(
      entry,
      target,
      overwrite = TRUE,
      copy.mode = FALSE,
      copy.date = TRUE
    )

    if (!isTRUE(copied)) {
      stop(sprintf("Could not copy publication file from '%s' to '%s'.", entry, target), call. = FALSE)
    }
  }

  invisible(TRUE)
}


# Only non-empty first-level directories are publication formats. Generated
# IASI trees are never formats, even if stale copies are already present under
# the build root.
.publish_format_directories = function(path, project = NULL) {
  entries = list.files(path, recursive = FALSE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  entries = entries[dir.exists(entries)]

  if (!length(entries)) return(character())

  entries = entries[!vapply(entries, .publish_skip_directory, logical(1), project = project)]
  if (!length(entries)) return(character())

  non_empty = vapply(
    entries,
    function(entry) length(.publish_tree_files(entry, project)) > 0L,
    logical(1)
  )

  basename(entries[non_empty])
}

.sync_export_anchors = function(publish_path) {
  indexes = list.files(publish_path, pattern = "^index\\.html$", recursive = TRUE, full.names = TRUE)
  if (!length(indexes)) return(invisible(TRUE))

  targets = .discover_export_targets(publish_path)
  lapply(indexes, .sync_export_anchor, publish_path = publish_path, targets = targets)
  invisible(TRUE)
}

.discover_export_targets = function(publish_path) {
  targets = lapply(names(.export_formats), .discover_export_target, publish_path = publish_path)
  names(targets) = names(.export_formats)
  targets[!vapply(targets, is.null, logical(1))]
}

.discover_export_target = function(format, publish_path) {
  path = file.path(publish_path, format)
  if (!dir.exists(path)) return(NULL)

  if (identical(format, "git")) {
    readme = file.path(path, "README.md")
    if (file.exists(readme)) return(readme)
    return(NULL)
  }

  extension = switch(format, pdf = "pdf", pdfua = "pdf", epub = "epub", docx = "docx", odt = "odt")
  files = list.files(path, pattern = paste0("\\.", extension, "$"), recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (!length(files)) return(NULL)

  files[[1L]]
}

.sync_export_anchor = function(index, publish_path, targets) {
  html = paste(readLines(index, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  anchors = c("<!-- IASI_EXPORT -->", '<div class="iasi-export"></div>', '<div class="iasi-export-anchor"></div>')
  anchor = anchors[vapply(anchors, function(value) grepl(value, html, fixed = TRUE), logical(1))]
  if (!length(anchor)) return(invisible(FALSE))

  block = .export_block(index, targets)
  html = gsub(anchor[[1L]], block, html, fixed = TRUE)
  writeLines(html, index, useBytes = TRUE)
  invisible(TRUE)
}

.export_block = function(index, targets) {
  if (!length(targets)) return("")

  items = Map(function(format, target) {
    label = unname(.export_formats[[format]])
    href = utils::URLencode(.relative_href(dirname(index), target), reserved = FALSE)
    sprintf('      <li><a class="dropdown-item" href="%s">%s</a></li>', href, label)
  }, names(targets), targets)

  paste(c(
    '<div class="dropdown iasi-export">',
    '  <a class="quarto-navigation-tool px-1 dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Export">Export</a>',
    '  <ul class="dropdown-menu dropdown-menu-end">',
    unlist(items, use.names = FALSE),
    '  </ul>',
    '</div>'
 ), collapse = "\n")
}

.relative_href = function(from, to) {
  from = strsplit(normalizePath(from, winslash = "/", mustWork = TRUE), "/", fixed = TRUE)[[1L]]
  to = strsplit(normalizePath(to, winslash = "/", mustWork = TRUE), "/", fixed = TRUE)[[1L]]
  limit = min(length(from), length(to))
  common = 0L

  while (common < limit && tolower(from[[common + 1L]]) == tolower(to[[common + 1L]])) common = common + 1L
  tail = if (common < length(to)) to[(common + 1L):length(to)] else character()
  parts = c(rep("..", length(from) - common), tail)
  if (!length(parts)) return(".")
  paste(parts, collapse = "/")
}

.move_publish_primary_to_root = function(path) {
  available = .publish_format_directories(path)
  candidates = .publish_root_profiles[
    .publish_root_profiles %in% available
  ]

  if (!length(candidates)) {
    return(invisible(NULL))
  }

  primary = candidates[[1L]]
  source = file.path(path, primary)
  entries = list.files(source, full.names = TRUE, all.files = TRUE, no.. = TRUE)

  targets = file.path(path, basename(entries))

  conflicts = targets[
    file.exists(targets) |
      dir.exists(targets)
  ]

  if (length(conflicts)) {
    stop(sprintf("Primary publication '%s' conflicts with another published output: %s.", primary, paste(basename(conflicts), collapse = ", ")), call. = FALSE)
  }

  if (length(entries)) {
    moved = file.rename(entries, targets)

    if (!all(moved)) {
      stop(sprintf("Could not move primary publication '%s' to '%s'.", primary, path), call. = FALSE)
    }
  }

  unlink(source, recursive = TRUE, force = TRUE)

  invisible(primary)
}

.normalise_publish_exports = function(path) {
  exports = file.path(path, "exports.json")
  if (!file.exists(exports)) return(invisible(TRUE))

  content = readLines(exports, warn = FALSE, encoding = "UTF-8")
  normalised = gsub('"href": "../', '"href": "', content, fixed = TRUE)

  if (!identical(content, normalised)) {
    writeLines(normalised, exports, useBytes = TRUE)
  }

  invisible(TRUE)
}

.publication_info = function(project, timestamp = Sys.time()) {
   version = project$version

   if (
      is.null(version) ||
      length(version) != 1L ||
      is.list(version) ||
      is.na(version) ||
      !nzchar(as.character(version))
  ) {
      version = NULL
   } else {
      version = as.character(version)
   }

   stamp = format(timestamp, tz = "UTC", format = "%Y-%m-%dT%H:%M:%OS6Z")

   publish_date = format(timestamp, "%d/%m/%Y")

   text = if (is.null(version)) {
      sprintf("Publicado: %s", publish_date)
   } else {
      sprintf("v%s · Publicado: %s", version, publish_date)
   }

   list(timestamp = timestamp, stamp = stamp, date = publish_date, version = version, text = text)
}

.normalise_publication = function(path, project, formats, publication) {
   for (format in formats) {
      name = paste0(".normalise_publication_", format)

      if (!exists(name, mode = "function")) next

      fn = get(name, mode = "function")
      fn(path = path, project = project, publication = publication)
   }

   invisible(TRUE)
}

.normalise_publication_html = function(path, project, publication) {
   files = list.files(path, pattern = "\\.html$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)

   if (!length(files)) return(invisible(TRUE))

   placeholder = '<span id="iasi-publish-date"></span>'
   replacement = sprintf('<span id="iasi-publish-date">%s</span>', publication$text)

   for (file in files) {
      html = paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

      if (!grepl(placeholder, html, fixed = TRUE)) next

      html = gsub(placeholder, replacement, html, fixed = TRUE)

      writeLines(html, file, useBytes = TRUE)
   }

   invisible(TRUE)
}

.normalise_publication_web = function(path, project, publication) {
   .normalise_publication_html(path = path, project = project, publication = publication)
}

# Dispatch strategy-specific post-processing after the build tree has been
# copied. Each strategy may provide format-specific normalisers.

.normalise_publish_tree = function(path, project, formats) {
   name = paste0(".normalise_", project$strategy)

   if (!exists(name, mode = "function")) return(invisible(TRUE))

   fn = get(name, mode = "function")
   fn(path = path, project = project, formats = formats)

   invisible(TRUE)
}


.normalise_regular = function(path, project, formats) {
   for (format in formats) {
      name = paste0(".normalise_regular_", format)

      if (!exists(name, mode = "function")) next

      fn = get(name, mode = "function")
      fn(path = path, project = project)
   }

   invisible(TRUE)
}

.normalise_regular_html = function(path, project) {
   html_path = file.path(path, "html")

   if (!dir.exists(html_path)) return(invisible(TRUE))

   files = list.files(html_path, pattern = "\\.html$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)

   for (file in files) {
      document = xml2::read_html(file)
      document = .normalise_regular_html_sidebar(document, file)
      xml2::write_html(document, file)
   }

   invisible(TRUE)
}

.normalise_regular_html_sidebar = function(document, file) {
   chapters = xml2::xml_find_all(document, "//*[@id='quarto-sidebar']/div[contains(@class,'sidebar-menu-container')]/ul/li")

   for (chapter in chapters) {
      .normalise_regular_html_sidebar_chapter(chapter, file)
   }

   document
}

.normalise_regular_html_sidebar_chapter = function(chapter, file) {
   link = xml2::xml_find_first(chapter, "./div[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-container ')]//a[@href] | ./a[@href]")

   if (inherits(link, "xml_missing")) return(chapter)

   href = xml2::xml_attr(link, "href")
   if (is.na(href) || !nzchar(href) || startsWith(href, "#")) return(chapter)

   target_href = sub("[?#].*$", "", href)
   target = file.path(dirname(file), utils::URLdecode(target_href))
   if (!file.exists(target)) return(chapter)

   target_document = xml2::read_html(target)
   sections = xml2::xml_find_first(target_document, "//*[@id='TOC']/ul")
   if (inherits(sections, "xml_missing")) return(chapter)

   links = xml2::xml_find_all(sections, ".//a[@href]")

   for (section_link in links) {
      section_href = xml2::xml_attr(section_link, "href")

      if (!is.na(section_href) && startsWith(section_href, "#")) {
         xml2::xml_attr(section_link, "href") = paste0(target_href, section_href)
      }
   }

   section_id = paste0("iasi-sidebar-", gsub("[^A-Za-z0-9_-]+", "-", target_href))

   chapter_class = xml2::xml_attr(chapter, "class")
   if (is.na(chapter_class)) chapter_class = ""

   xml2::xml_attr(chapter, "class") = trimws(paste(chapter_class, "sidebar-item-section"))

   container = xml2::xml_find_first(chapter, "./div[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-container ')]")

   if (inherits(container, "xml_missing")) return(chapter)

   toggle = xml2::xml_add_child(container, "a")
   xml2::xml_attr(toggle, "class") = "sidebar-item-toggle text-start collapsed"
   xml2::xml_attr(toggle, "data-bs-toggle") = "collapse"
   xml2::xml_attr(toggle, "data-bs-target") = paste0("#", section_id)
   xml2::xml_attr(toggle, "role") = "navigation"
   xml2::xml_attr(toggle, "aria-expanded") = "false"
   xml2::xml_attr(toggle, "aria-controls") = section_id
   xml2::xml_attr(toggle, "aria-label") = "Toggle section"

   icon = xml2::xml_add_child(toggle, "i")
   xml2::xml_attr(icon, "class") = "bi bi-chevron-right ms-2"

   xml2::xml_attr(sections, "id") = section_id
   xml2::xml_attr(sections, "class") = "collapse list-unstyled sidebar-section depth2"

   sections = .normalise_regular_html_sidebar_sections(sections, prefix = section_id, depth = 2L)

   xml2::xml_add_child(chapter, sections, .copy = TRUE)

   chapter
}

.normalise_regular_html_sidebar_sections = function(sections, prefix, depth) {
   items = xml2::xml_find_all(sections, "./li")

   for (i in seq_along(items)) {
      item = items[[i]]
      children = xml2::xml_find_first(item, "./ul")

      if (inherits(children, "xml_missing")) next

      id = paste0(prefix, "-", i)

      item_class = xml2::xml_attr(item, "class")
      if (is.na(item_class)) item_class = ""

      xml2::xml_attr(item, "class") = trimws(paste(item_class, "sidebar-item-section"))

      toggle = xml2::xml_add_child(item, "a")
      xml2::xml_attr(toggle, "class") = "sidebar-item-toggle text-start collapsed"
      xml2::xml_attr(toggle, "data-bs-toggle") = "collapse"
      xml2::xml_attr(toggle, "data-bs-target") = paste0("#", id)
      xml2::xml_attr(toggle, "role") = "navigation"
      xml2::xml_attr(toggle, "aria-expanded") = "false"
      xml2::xml_attr(toggle, "aria-controls") = id
      xml2::xml_attr(toggle, "aria-label") = "Toggle section"

      icon = xml2::xml_add_child(toggle, "i")
      xml2::xml_attr(icon, "class") = "bi bi-chevron-right ms-2"

      xml2::xml_attr(children, "id") = id
      xml2::xml_attr(children, "class") = paste0("collapse list-unstyled sidebar-section depth", depth + 1L)

      .normalise_regular_html_sidebar_sections(children, prefix = id, depth = depth + 1L)
   }

   sections
}

.normalise_structured = function(path, project, formats) {
   for (format in formats) {
      name = paste0(".normalise_structured_", format)

      if (!exists(name, mode = "function")) next

      fn = get(name, mode = "function")
      fn(path = path, project = project)
   }

   invisible(TRUE)
}

.normalise_structured_html = function(path, project) {
   html_path = file.path(path, "html")

   if (!dir.exists(html_path)) return(invisible(TRUE))

   files = list.files(html_path, pattern = "\\.html$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)

   for (file in files) {
      document = xml2::read_html(file)

      document = .normalise_structured_html_sidebar(document, project, file)
      document = .normalise_structured_html_content(document, project, file)

      xml2::write_html(document, file)
   }

   invisible(TRUE)
}


.normalise_structured_html_content = function(document, project, file) {
   active = xml2::xml_find_first(
      document,
      "//*[@id='quarto-sidebar']//a[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-link ') and contains(concat(' ', normalize-space(@class), ' '), ' active ')]"
  )

   if (inherits(active, "xml_missing")) return(document)

   node = xml2::xml_find_first(active, "ancestor::li[1]")
   if (inherits(node, "xml_missing")) return(document)

   .normalise_structured_html_content_node(document, node)
}

.normalise_structured_html_content_node = function(document, node) {
   link = xml2::xml_find_first(node, "./div[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-container ')]//a[@href] | ./a[@href]")

   if (!inherits(link, "xml_missing")) {
      chapter_number_node = xml2::xml_find_first(link, ".//span[contains(concat(' ', normalize-space(@class), ' '), ' chapter-number ')]")

      section_number_node = xml2::xml_find_first(link, ".//span[contains(concat(' ', normalize-space(@class), ' '), ' header-section-number ')]")

      if (!inherits(chapter_number_node, "xml_missing")) {
         number = trimws(xml2::xml_text(chapter_number_node))

         target_number_node = xml2::xml_find_first(
            document,
            "//*[@id='title-block-header']//h1[contains(concat(' ', normalize-space(@class), ' '), ' title ')]//span[contains(concat(' ', normalize-space(@class), ' '), ' chapter-number ')]"
        )

         if (!inherits(target_number_node, "xml_missing")) {
            xml2::xml_text(target_number_node) = number
         }
      } else if (!inherits(section_number_node, "xml_missing")) {
         href = xml2::xml_attr(link, "href")

         if (!is.na(href) && grepl("#", href, fixed = TRUE)) {
            id = sub("^[^#]*#", "", href)
            id = utils::URLdecode(id)
            number = trimws(xml2::xml_text(section_number_node))

            document = .normalise_structured_html_content_section(document = document, id = id, number = number)
         }
      }
   }

   children = xml2::xml_find_first(node, "./ul[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-section ')]")

   if (!inherits(children, "xml_missing")) {
      items = xml2::xml_find_all(children, "./li")

      for (item in items) {
         document = .normalise_structured_html_content_node(document = document, node = item)
      }
   }

   document
}

.normalise_structured_html_content_section = function(document, id, number) {
   candidates = xml2::xml_find_all(document, "//main//*[@id]")
   if (!length(candidates)) return(document)

   ids = xml2::xml_attr(candidates, "id")
   index = which(ids == id)
   if (!length(index)) return(document)

   section = candidates[[index[[1L]]]]
   heading = xml2::xml_find_first(section, "./h1 | ./h2 | ./h3 | ./h4 | ./h5 | ./h6")
   if (inherits(heading, "xml_missing")) return(document)

   number_node = xml2::xml_find_first(heading, ".//span[contains(concat(' ', normalize-space(@class), ' '), ' header-section-number ')]")

   if (!inherits(number_node, "xml_missing")) {
      xml2::xml_text(number_node) = number
   }

   document
}

.normalise_structured_html_sidebar = function(document, project, file) {
   document = .normalise_structured_html_sidebar_structure(document, project)

   parts = xml2::xml_find_all(document, "//*[@id='quarto-sidebar']//li[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-section ')]")

   for (part in parts) {
      chapters = xml2::xml_find_all(part, "./ul[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-section ')]/li")

      for (chapter in chapters) {
         .normalise_structured_html_sidebar_chapter(chapter, file)
      }
   }

   document
}

.normalise_structured_html_sidebar_structure = function(document, project) {
   root_number = xml2::xml_find_first(
      document,
      "//*[@id='quarto-sidebar']/div[contains(@class,'sidebar-menu-container')]/ul/li[not(contains(@class,'sidebar-item-section'))][1]//span[contains(@class,'chapter-number')]"
  )

   if (!inherits(root_number, "xml_missing")) {
      xml2::xml_remove(root_number)
   }

   parts = xml2::xml_find_all(document, "//*[@id='quarto-sidebar']//li[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-section ')]")

   for (i in seq_along(parts)) {
      part = parts[[i]]

      title = xml2::xml_find_first(
         part,
         "./div[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-container ')]//span[contains(concat(' ', normalize-space(@class), ' '), ' menu-text ')]"
     )

      if (!inherits(title, "xml_missing")) {
         xml2::xml_text(title) = paste(as.roman(i), xml2::xml_text(title))
      }

      numbers = xml2::xml_find_all(
         part,
         "./ul[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-section ')]/li//span[contains(concat(' ', normalize-space(@class), ' '), ' chapter-number ')]"
     )

      if (length(numbers)) {
         xml2::xml_text(numbers) = as.character(seq_along(numbers))
      }
   }

   document
}

.normalise_structured_html_sidebar_chapter = function(chapter, file) {
   link = xml2::xml_find_first(chapter, ".//a[@href]")
   if (inherits(link, "xml_missing")) return(chapter)

   href = xml2::xml_attr(link, "href")
   if (is.na(href) || !nzchar(href) || startsWith(href, "#")) return(chapter)

   target_href = sub("[?#].*$", "", href)
   target = file.path(dirname(file), utils::URLdecode(target_href))
   if (!file.exists(target)) return(chapter)

   target_document = xml2::read_html(target)
   sections = xml2::xml_find_first(target_document, "//*[@id='TOC']/ul")
   if (inherits(sections, "xml_missing")) return(chapter)

   links = xml2::xml_find_all(sections, ".//a[@href]")

   for (section_link in links) {
      section_href = xml2::xml_attr(section_link, "href")

      if (!is.na(section_href) && startsWith(section_href, "#")) {
         xml2::xml_attr(section_link, "href") = paste0(target_href, section_href)
      }
   }

   chapter_number_node = xml2::xml_find_first(chapter, ".//span[contains(concat(' ', normalize-space(@class), ' '), ' chapter-number ')]")

   if (inherits(chapter_number_node, "xml_missing")) return(chapter)

   chapter_number = xml2::xml_text(chapter_number_node)

   section_id = paste0("iasi-sidebar-", gsub("[^A-Za-z0-9_-]+", "-", target_href))

   chapter_class = xml2::xml_attr(chapter, "class")
   if (is.na(chapter_class)) chapter_class = ""

   xml2::xml_attr(chapter, "class") = trimws(paste(chapter_class, "sidebar-item-section"))

   container = xml2::xml_find_first(chapter, "./div[contains(concat(' ', normalize-space(@class), ' '), ' sidebar-item-container ')]")

   if (inherits(container, "xml_missing")) return(chapter)

   toggle = xml2::xml_add_child(container, "a")
   xml2::xml_attr(toggle, "class") = "sidebar-item-toggle text-start collapsed"
   xml2::xml_attr(toggle, "data-bs-toggle") = "collapse"
   xml2::xml_attr(toggle, "data-bs-target") = paste0("#", section_id)
   xml2::xml_attr(toggle, "role") = "navigation"
   xml2::xml_attr(toggle, "aria-expanded") = "false"
   xml2::xml_attr(toggle, "aria-controls") = section_id
   xml2::xml_attr(toggle, "aria-label") = "Toggle section"

   icon = xml2::xml_add_child(toggle, "i")
   xml2::xml_attr(icon, "class") = "bi bi-chevron-right ms-2"

   xml2::xml_attr(sections, "id") = section_id
   xml2::xml_attr(sections, "class") = "collapse list-unstyled sidebar-section depth2"

   sections = .normalise_structured_html_sidebar_sections(sections, prefix = section_id, number = chapter_number, depth = 2L)

   xml2::xml_add_child(chapter, sections, .copy = TRUE)

   chapter
}

.normalise_structured_html_sidebar_sections = function(sections, prefix, number, depth) {
   items = xml2::xml_find_all(sections, "./li")

   for (i in seq_along(items)) {
      item = items[[i]]
      item_number = paste(number, i, sep = ".")

      number_node = xml2::xml_find_first(item, "./a//span[contains(concat(' ', normalize-space(@class), ' '), ' header-section-number ')]")

      if (!inherits(number_node, "xml_missing")) {
         xml2::xml_text(number_node) = item_number
      }

      children = xml2::xml_find_first(item, "./ul")

      if (inherits(children, "xml_missing")) next

      id = paste0(prefix, "-", i)

      item_class = xml2::xml_attr(item, "class")
      if (is.na(item_class)) item_class = ""

      xml2::xml_attr(item, "class") = trimws(paste(item_class, "sidebar-item-section"))

      toggle = xml2::xml_add_child(item, "a")
      xml2::xml_attr(toggle, "class") = "sidebar-item-toggle text-start collapsed"
      xml2::xml_attr(toggle, "data-bs-toggle") = "collapse"
      xml2::xml_attr(toggle, "data-bs-target") = paste0("#", id)
      xml2::xml_attr(toggle, "role") = "navigation"
      xml2::xml_attr(toggle, "aria-expanded") = "false"
      xml2::xml_attr(toggle, "aria-controls") = id
      xml2::xml_attr(toggle, "aria-label") = "Toggle section"

      icon = xml2::xml_add_child(toggle, "i")
      xml2::xml_attr(icon, "class") = "bi bi-chevron-right ms-2"

      xml2::xml_attr(children, "id") = id
      xml2::xml_attr(children, "class") = paste0("collapse list-unstyled sidebar-section depth", depth + 1L)

      children = .normalise_structured_html_sidebar_sections(children, prefix = id, number = item_number, depth = depth + 1L)
   }

   sections
}
