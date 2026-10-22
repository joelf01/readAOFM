fixture_name <- function(...) {
  file.path(...)
}

fixture_public_source_path <- function(...) {
  file.path(testthat::test_path("..", "..", "inst", "extdata"), ...)
}

fixture_source_path <- fixture_public_source_path

fixture_test_source_path <- function(...) {
  testthat::test_path("fixtures", ...)
}

fixture_installed_path <- function(...) {
  system.file("extdata", ..., package = "readAOFM")
}

fixture_path <- function(...) {
  test_source_path <- fixture_test_source_path(...)
  public_source_path <- fixture_public_source_path(...)
  installed_path <- fixture_installed_path(...)

  if (file.exists(test_source_path)) {
    return(normalizePath(test_source_path, mustWork = TRUE))
  }

  if (file.exists(public_source_path)) {
    return(normalizePath(public_source_path, mustWork = TRUE))
  }

  if (nzchar(installed_path) && file.exists(installed_path)) {
    return(normalizePath(installed_path, mustWork = TRUE))
  }

  stop(
    sprintf(
      "Fixture '%s' was not found in source or installed extdata.",
      fixture_name(...)
    ),
    call. = FALSE
  )
}
