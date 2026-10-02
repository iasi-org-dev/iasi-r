.generated_dir_name = "_generated"
.iasi_metadata_name = "iasi-metadata.yml"
.generated_navbar_left_name = "navbar-left.yml"

.generated_dir = function(project) {
  file.path(
    project$path,
    .generated_dir_name
  )
}

.generated_artifact_path = function(project, name) {
  file.path(
    .generated_dir(project),
    name
  )
}

.generated_artifact_relative_path = function(name) {
  gsub(
    "\\\\",
    "/",
    file.path(
      .generated_dir_name,
      name
    )
  )
}

.book_structure_path = function(project) {
  .generated_artifact_path(
    project,
    .iasi_metadata_name
  )
}

.book_structure_relative_path = function() {
  .generated_artifact_relative_path(
    .iasi_metadata_name
  )
}

.navbar_left_path = function(project) {
  .generated_artifact_path(
    project,
    .generated_navbar_left_name
  )
}

.navbar_left_relative_path = function() {
  .generated_artifact_relative_path(
    .generated_navbar_left_name
  )
}
