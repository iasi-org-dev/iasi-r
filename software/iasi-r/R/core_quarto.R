.config_publication_strategy = function(config) {
  publication = .yaml_section(config, "publication")
  .yaml_field(publication, "strategy")
}


.as_quarto_project = function(project) {
  if (!file.exists(file.path(project$path, "_quarto.yml"))) {
    message("Missing _quarto.yml in: ", project$path)
    stop("Missing Quarto configuration.", call. = FALSE)
  }

  quarto_project = .discover_project(project$path, project$config)
  quarto_project$config = project$config
  quarto_project$iasi_type = project$config$type
  quarto_project
}


.ensure_checked_project = function(project) {
  checked = .check_project(project)

  if (!isTRUE(checked$valid)) {
    for (error in checked$errors) {
      message(project$name, ": ", error)
    }

    stop("Project validation failed.", call. = FALSE)
  }

  for (warning in checked$warnings) {
    warning(warning, call. = FALSE)
  }

  checked
}


# Quarto project parsing --------------------------------------------------

.discover_project = function(path, iasi_source = NULL) {
  project_path = .normalise_project_path(path)

  quarto_file = file.path(
    project_path,
    "_quarto.yml"
  )

  iasi_file = .iasi_file(project_path, required = TRUE)

  quarto = .read_yaml_file(quarto_file)
  if (is.null(iasi_source)) iasi_source = .read_yaml_file(iasi_file)

  quarto_project = .yaml_section(
    quarto,
    "project"
  )

  type = .yaml_field(
    quarto_project,
    "type"
  )

  iasi = .normalise_iasi_config(
    source = iasi_source,
    type = type
  )

  publication = .yaml_section(
    iasi,
    "publication"
  )

  project = list(
    name = basename(project_path),
    path = project_path,
    quarto_file = .normalise_project_path(quarto_file),
    iasi_file = .normalise_project_path(iasi_file),
    type = type,
    strategy = .yaml_field(publication, "strategy"),
    front_matter_dir = .yaml_field(publication, "front-matter"),
    front_matter_path = .content_path(
      project_path,
      .yaml_field(publication, "front-matter")
    ),
    content_dir = .yaml_field(publication, "content-dir"),
    content_path = .content_path(
      project_path,
      .yaml_field(publication, "content-dir")
    ),
    back_matter_dir = .yaml_field(publication, "back-matter"),
    back_matter_path = .content_path(
      project_path,
      .yaml_field(publication, "back-matter")
    ),
    exclude = .normalise_exclude(
      .yaml_field(iasi, "exclude")
    ),
    numbered = .yaml_field(publication, "numbered"),
    html_landing_page = .yaml_field(
      .yaml_section(publication, "html"),
      "landing-page"
    ),
    quarto = quarto,
    iasi = iasi,
    iasi_source = iasi_source
  )

  class(project) = c(
    "iasi_quarto_project",
    "list"
  )

  project
}


.read_yaml_file = function(path) {
  tryCatch(
    {
      contents = yaml::read_yaml(path)

      if (is.null(contents)) {
        return(list())
      }

      contents
    },
    error = function(error) {
      stop(
        sprintf(
          "Invalid YAML file '%s': %s",
          path,
          conditionMessage(error)
        ),
        call. = FALSE
      )
    }
  )
}


.normalise_iasi_config = function(source, type) {
  is_book = identical(type, "book")

  defaults = list(
    publication = list(
      `front-matter` = if (is_book) "front-matter" else NULL,
      `content-dir` = if (is_book) "chapters" else NULL,
      `back-matter` = if (is_book) "back-matter" else NULL,
      numbered = if (is_book) TRUE else NULL,
      html = list(
        `landing-page` = FALSE
      )

    )
  )

  .merge_iasi_defaults(source, defaults)
}


.normalise_exclude = function(value) {
  if (is.null(value)) {
    return(character())
  }

  if (is.character(value)) {
    if (any(is.na(value)) || any(!nzchar(value))) {
      return(character())
    }

    return(unique(unname(value)))
  }

  if (!is.list(value)) {
    return(character())
  }

  valid = vapply(
    value,
    function(item) {
      is.character(item) &&
        length(item) == 1L &&
        !is.na(item) &&
        nzchar(item)
    },
    logical(1)
  )

  if (!all(valid)) {
    return(character())
  }

  unique(unname(unlist(value, use.names = FALSE)))
}


.merge_iasi_defaults = function(source, defaults) {
  if (!is.list(source)) {
    return(source)
  }

  result = source

  for (name in names(defaults)) {
    default = defaults[[name]]
    value = result[[name]]

    if (is.null(value)) {
      result[[name]] = default
      next
    }

    if (is.list(default) && is.list(value)) {
      result[[name]] = .merge_iasi_defaults(value, default)
    }
  }

  result
}


.project_format_type = function(project, format) {
  if (
    identical(format, "html") &&
      identical(project$type, "book") &&
      isTRUE(project$html_landing_page)
  ) {
    return("website")
  }

  project$type
}


.yaml_section = function(source, name) {
  value = .yaml_field(
    source,
    name
  )

  if (!is.list(value)) {
    return(list())
  }

  value
}


.yaml_field = function(source, name) {
  if (
    !is.list(source) ||
      is.null(names(source)) ||
      !name %in% names(source)
  ) {
    return(NULL)
  }

  source[[name]]
}


.content_path = function(project_path, content_dir) {
  if (
    !is.character(content_dir) ||
      length(content_dir) != 1L ||
      is.na(content_dir) ||
      !nzchar(content_dir)
  ) {
    return(NULL)
  }

  file.path(
    project_path,
    content_dir
  )
}
