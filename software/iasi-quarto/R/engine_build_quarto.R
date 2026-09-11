# Quarto build -----------------------------------------------------------
#
# Quarto-specific build implementation.
# Resolve profiles, render them, clean generated output, and expose exports.


# Build one selected Quarto project.
.build_quarto_project = function(context, project) {
  formats = .resolve_build_formats(context$format)
  quarto = .as_quarto_project(project)
  quarto = .ensure_checked_project(quarto)
  quarto = .prepare_project(quarto)
  quarto = .render_build_project(quarto, formats)
  .IASI$status$OK
}


# Format resolution -------------------------------------------------------

# Normalize the optional public format selection.
.resolve_build_formats = function(format = NULL) .normalise_build_selection(format, "format")


# Return the profiles declared by the Quarto project.
.project_declared_formats = function(project) {
  profile = .yaml_section(project$quarto, "profile")
  groups = .yaml_field(profile, "group")
  formats = unique(as.character(unlist(groups, use.names = FALSE)))
  formats = formats[!is.na(formats) & nzchar(formats)]
  if (length(formats)) return(formats)

  default = .yaml_field(profile, "default")
  if (is.character(default) && length(default) == 1L && !is.na(default) && nzchar(default)) return(default)

  switch(project$type, website = "web", character())
}


# Resolve the renderer for one project type/profile pair.
.project_build_renderer = function(project, format) {
  switch(project$type, website = switch(format, web = ".render_website", NULL), book = paste0(".render_", format), NULL)
}


# Keep only declared profiles that have a renderer.
.resolve_project_build_formats = function(project, formats, warn = TRUE) {
  declared = .project_declared_formats(project)
  selected = if (identical(formats, "all")) declared else formats

  if (!identical(formats, "all")) {
    missing = selected[!selected %in% declared]
    if (length(missing) && warn) for (format in missing) warning(sprintf("Ignoring '%s': it is not declared in 'profile.group'.", format), call. = FALSE)
    selected = selected[selected %in% declared]
  }

  resolved = character()

  for (format in selected) {
    renderer = .project_build_renderer(project, format)

    if (is.null(renderer) || !exists(renderer, mode = "function")) {
      if (warn) warning(sprintf("Ignoring '%s': no renderer is available for project type '%s'.", format, project$type), call. = FALSE)
      next
    }

    resolved = c(resolved, format)
  }

  unique(resolved)
}


# Validate and normalize a format selection. NULL means all declared profiles.
.normalise_build_selection = function(value, argument) {
  if (is.null(value)) return("all")

  value = unique(as.character(value))
  if (!length(value) || anyNA(value) || any(!nzchar(value))) stop(sprintf("`%s` must contain at least one non-empty value.", argument), call. = FALSE)
  if ("all" %in% value && length(value) > 1L) stop(sprintf('`%s = "all"` cannot be combined with other values.', argument), call. = FALSE)

  value
}


# Rendering ---------------------------------------------------------------

# Dispatch rendering by Quarto project type.
.render_build_project = function(project, formats) {
  switch(project$type, website = .render_website(project, formats), book = .render_artifacts(project, formats), stop(sprintf("Unsupported Quarto project type '%s'.", .display_checked_value(project$type)), call. = FALSE))
}


# Render every selected book profile.
.render_artifacts = function(project, formats) {
  publication = project$publication
  project_formats = .resolve_project_build_formats(project, formats)

  for (format in project_formats) {
    message(sprintf("Rendering '%s' as %s...", project$name, toupper(format)))
    config = .profile_config(project, format)
    renderer = get(.project_build_renderer(project, format), mode = "function")
    publication = renderer(publication, config)
    .remove_build_output_exclusions(project = project, output_path = config$output_path)
  }

  if ("html" %in% project_formats) .write_html_exports(project)

  project$html_generated = FALSE
  project$publication = publication
  project$render_formats = project_formats
  project
}


# Build-output cleanup ----------------------------------------------------

# Resolve output-only paths that must be removed from rendered static resources.
.build_output_exclusion_paths = function(project) {
  paths = .yaml_section(project$iasi, "paths")
  release = .yaml_field(paths, "release")
  if (!is.character(release) || length(release) != 1L || is.na(release) || !nzchar(release)) return(character())

  project_root = normalizePath(project$path, winslash = "/", mustWork = TRUE)
  release_path = if (.is_absolute_path(release)) release else file.path(project_root, release)
  release_path = normalizePath(release_path, winslash = "/", mustWork = FALSE)

  prefix = paste0(tolower(project_root), "/")
  if (!startsWith(tolower(release_path), prefix)) return(character())

  relative = substring(release_path, nchar(project_root) + 2L)
  if (!nzchar(relative)) return(character())

  gsub("\\\\", "/", relative)
}


# Remove output-only paths accidentally copied into build output.
.remove_build_output_exclusions = function(project, output_path) {
  if (is.null(output_path) || !dir.exists(output_path)) return(invisible(character()))

  exclusions = .build_output_exclusion_paths(project)
  if (!length(exclusions)) return(invisible(character()))

  removed = character()

  for (relative in exclusions) {
    target = file.path(output_path, relative)
    if (!file.exists(target) && !dir.exists(target)) next

    unlink(target, recursive = TRUE, force = TRUE)
    if (file.exists(target) || dir.exists(target)) stop(sprintf("Could not remove output-only path '%s' from build output.", relative), call. = FALSE)

    removed = c(removed, target)
  }

  invisible(removed)
}


# Export discovery --------------------------------------------------------

# Resolve the expected output filename for an export profile.
.resolve_export_output_file = function(project, profile) {
  profile_file = file.path(project$path, sprintf("_quarto-%s.yml", profile))
  profile_quarto = if (file.exists(profile_file)) .read_yaml_file(profile_file) else list()

  candidates = list(.yaml_field(.yaml_section(profile_quarto, "book"), "output-file"), .yaml_field(.yaml_section(project$quarto, "book"), "output-file"), project$name)

  for (candidate in candidates) {
    if (is.character(candidate) && length(candidate) == 1L && !is.na(candidate) && nzchar(candidate)) return(candidate)
  }

  project$name
}


# Locate the materialized artifact produced by one export profile.
.resolve_export_target = function(project, profile) {
  config = .profile_config(project, profile)
  output_path = config$output_path
  if (is.null(output_path) || !dir.exists(output_path)) return(NULL)

  if (identical(profile, "git")) {
    target = file.path(output_path, "README.md")
    return(if (file.exists(target)) target else NULL)
  }

  extensions = c(pdf = "pdf", pdfua = "pdf", epub = "epub", docx = "docx", odt = "odt")
  if (!profile %in% names(extensions)) return(output_path)

  extension = extensions[[profile]]
  output_file = .resolve_export_output_file(project, profile)
  if (!grepl(sprintf("\\.%s$", extension), output_file, ignore.case = TRUE)) output_file = paste0(output_file, ".", extension)

  target = file.path(output_path, output_file)
  if (file.exists(target)) return(target)

  candidates = list.files(output_path, pattern = sprintf("\\.%s$", extension), recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  if (!length(candidates)) return(NULL)

  candidates[[1L]]
}


# Write exports.json used by HTML publications to link other formats.
.write_html_exports = function(project) {
  html_path = .profile_config(project, "html")$output_path
  if (is.null(html_path) || !dir.exists(html_path)) return(invisible(NULL))

  profiles = setdiff(.resolve_project_build_formats(project, "all", warn = FALSE), "html")
  targets = lapply(profiles, function(profile) .resolve_export_target(project, profile))
  names(targets) = profiles

  available = !vapply(targets, is.null, logical(1))
  profiles = profiles[available]
  targets = targets[available]

  labels = c(pdf = "PDF", pdfua = "PDF/UA", epub = "eBook", docx = "DOCX", odt = "ODT", git = "GitBook")
  icons = c(pdf = "file-earmark-pdf", pdfua = "file-earmark-pdf", epub = "book", docx = "file-earmark-word", odt = "file-earmark-text", git = "book")

  items = vapply(
    profiles,
    function(profile) {
      label = if (profile %in% names(labels)) labels[[profile]] else profile
      icon = if (profile %in% names(icons)) icons[[profile]] else "download"
      href = .relative_href(html_path, targets[[profile]])
      sprintf('    {"profile": %s, "text": %s, "icon": %s, "href": %s}', encodeString(profile, quote = '"'), encodeString(label, quote = '"'), encodeString(icon, quote = '"'), encodeString(href, quote = '"'))
    },
    character(1)
  )

  content = if (length(items)) c("{", '  "exports": [', paste(items, collapse = ",\n"), "  ]", "}") else c("{", '  "exports": []', "}")
  path = file.path(html_path, "exports.json")
  .write_if_changed(content, path)
  invisible(path)
}
