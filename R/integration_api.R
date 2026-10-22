#' List AOFM data tables known to the package
#'
#' Returns the package's local table catalogue without downloading a workbook
#' or contacting the AOFM website. Stable `table_id` values can be passed to
#' [download_aofm_file()] and [read_aofm_file()].
#'
#' The catalogue contains 23 parser-supported rows by default. Seven
#' additional rows are retained as raw-only/unsupported source records and can
#' be included for catalogue or raw-download workflows with
#' `include_unsupported = TRUE`; they are not accepted by the parser APIs.
#'
#' @param include_unsupported Logical scalar (default `FALSE`). Include the
#'   seven catalogue rows without a package parser when `TRUE`.
#' @returns A base `data.frame` with one row per selected table and these
#'   columns: `security`, `type`, `table_id`, `reader`, `category`, `title`,
#'   `description`, `source_url`, `file_name`, and logical `supported`.
#'   Character columns are returned as character vectors, not factors. The
#'   `source_url` values for parser-supported rows are the current HTTPS AOFM
#'   workbook routes used by the package; raw-only rows are retained for
#'   catalogue continuity and may use their verified raw-download routes.
#'
#' @details
#' Catalogue lookup is deterministic and offline. It does not validate a URL
#' by making a network request. A non-missing logical scalar is required for
#' `include_unsupported`; invalid values throw an error.
#'
#' @seealso [search_aofm()] for text search, [download_aofm_file()] for the
#'   opt-in managed download/cache workflow, and [read_aofm_file()] for parsing
#'   a local workbook.
#' @examples
#' catalog <- aofm_catalog()
#' catalog[, c("table_id", "reader", "supported")]
#'
#' all_catalogue_rows <- aofm_catalog(include_unsupported = TRUE)
#' table(all_catalogue_rows$supported)
#' @export
aofm_catalog <- function(include_unsupported = FALSE) {
  if (
    !is.logical(include_unsupported) ||
      length(include_unsupported) != 1L ||
      is.na(include_unsupported)
  ) {
    stop(
      "`include_unsupported` must be one non-missing logical value.",
      call. = FALSE
    )
  }
  aofm_validate_catalog_contract(aofm_index)
  catalog <- aofm_apply_catalog_overrides(aofm_index)
  supported <- catalog$fn != "no function exists"

  if (!isTRUE(include_unsupported)) {
    catalog <- catalog[supported, , drop = FALSE]
    supported <- supported[supported]
  }

  data.frame(
    security = as.character(catalog$p.security),
    type = as.character(catalog$p.type),
    table_id = as.character(catalog$id),
    reader = as.character(catalog$fn),
    category = as.character(catalog$category),
    title = as.character(catalog$title),
    description = as.character(catalog$despription),
    source_url = as.character(catalog$file.path),
    file_name = as.character(catalog$file.save),
    supported = unname(supported),
    stringsAsFactors = FALSE
  )
}

aofm_catalog_contract <- function() {
  data.frame(
    security = c(
      "summary", "aggregate", "aggregate", "tb", "tb", "tib", "tib", "tn",
      "tn", "tb", NA, "tb", "tb", "tib", "tib", "tib", "tn", "retail",
      "slf", "ownership", "ownership", "tb", "tib", "termpremium",
      rep(NA, 6)
    ),
    type = c(
      NA, "dealt", "settlement", "dealt", "settlement", "dealt",
      "settlement", "dealt", "settlement", "issuance", NA, "syndication",
      "buyback", "issuance", "syndication", "buyback", "issuance", NA, NA,
      "public", "nonresident", "turnover", "turnover", NA, rep(NA, 6)
    ),
    table_id = c(
      "summary",
      "aggregate_position_dealt",
      "aggregate_position_settlement",
      "tb_position_dealt",
      "tb_position_settlement",
      "tib_position_dealt",
      "tib_position_settlement",
      "tn_position_dealt",
      "tn_position_settlement",
      "tb_issuance",
      "tb_issuance_conversion",
      "tb_syndication",
      "tb_buyback",
      "tib_issuance",
      "tib_syndication",
      "tib_buyback",
      "tn_issuance",
      "retail",
      "slf",
      "ownership_public",
      "ownership_nonresident",
      "tb_turnover",
      "tib_turnover",
      "termpremium",
      "indexation_factors",
      "rmbs_transactions",
      "rmbs_auctions",
      "interest_rate_swaps",
      "cross_currency_swaps",
      "portfolio_overview"
    ),
    reader = c(
      "read_eofy",
      rep("read_eom", 8),
      "read_transactional",
      "no function exists",
      "read_syndication",
      "read_transactional",
      "read_transactional",
      "read_syndication",
      "read_transactional",
      "read_transactional",
      "read_transactional",
      "read_transactional",
      "read_ownership",
      "read_ownership",
      "read_secondary",
      "read_secondary",
      "read_premium",
      rep("no function exists", 6)
    ),
    stringsAsFactors = FALSE
  )
}

aofm_validate_catalog_contract <- function(catalog) {
  required <- c("p.security", "p.type", "id", "fn")
  missing <- setdiff(required, names(catalog))
  if (length(missing)) {
    stop(
      sprintf(
        "The internal AOFM catalogue is missing: %s.",
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (anyDuplicated(catalog$id)) {
    stop("The internal AOFM catalogue contains duplicate table IDs.", call. = FALSE)
  }

  actual <- data.frame(
    security = as.character(catalog$p.security),
    type = as.character(catalog$p.type),
    table_id = as.character(catalog$id),
    reader = as.character(catalog$fn),
    stringsAsFactors = FALSE
  )
  expected <- aofm_catalog_contract()
  actual <- actual[order(actual$table_id), , drop = FALSE]
  expected <- expected[order(expected$table_id), , drop = FALSE]
  rownames(actual) <- NULL
  rownames(expected) <- NULL
  if (!identical(actual, expected)) {
    stop(
      paste0(
        "The internal AOFM catalogue drifted from the exact ",
        "23-supported/7-unsupported contract."
      ),
      call. = FALSE
    )
  }
  invisible(catalog)
}

aofm_supported_table_row <- function(table_id) {
  if (!is.character(table_id) ||
      length(table_id) != 1L ||
      is.na(table_id) ||
      !nzchar(trimws(table_id))) {
    stop("`table_id` must be a single non-empty string.", call. = FALSE)
  }

  row <- aofm_table_row(trimws(table_id))
  if (identical(row$fn[[1]], "no function exists")) {
    stop(
      sprintf("AOFM table '%s' does not yet have a parser.", table_id),
      call. = FALSE
    )
  }

  row
}

aofm_ensure_cache_directory <- function(parent, name) {
  parent <- normalizePath(parent, winslash = "/", mustWork = TRUE)
  candidate <- file.path(parent, name)
  if (file.exists(candidate) || dir.exists(candidate)) {
    link <- Sys.readlink(candidate)
    if (!is.na(link) && nzchar(link)) {
      stop("The readAOFM cache cannot traverse a symlink.", call. = FALSE)
    }
    if (!dir.exists(candidate)) {
      stop("A readAOFM cache directory path is not a directory.", call. = FALSE)
    }
  } else if (!dir.create(candidate, recursive = FALSE, showWarnings = FALSE)) {
    stop("Could not create the readAOFM cache directory.", call. = FALSE)
  }
  resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
  if (!startsWith(resolved, paste0(parent, "/"))) {
    stop("The readAOFM cache path escaped the requested root.", call. = FALSE)
  }
  resolved
}

aofm_cache_paths <- function(path, table_id) {
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(trimws(path))
  ) {
    stop("`path` must be a single non-empty directory.", call. = FALSE)
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(path)) {
    stop(sprintf("Could not create download directory '%s'.", path), call. = FALSE)
  }
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  cache_root <- aofm_ensure_cache_directory(root, ".readAOFM")
  data_root <- aofm_ensure_cache_directory(cache_root, "data")
  table_directory <- aofm_ensure_cache_directory(data_root, table_id)
  list(
    root = root,
    cache_root = cache_root,
    data_root = data_root,
    table_directory = table_directory,
    metadata = file.path(table_directory, "current.rds"),
    lock = file.path(table_directory, ".writer.lock")
  )
}

aofm_atomic_save_rds <- function(object, path) {
  temporary <- tempfile(
    pattern = ".current-",
    tmpdir = dirname(path),
    fileext = ".rds"
  )
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  saveRDS(object, temporary, version = 3)
  if (!file.rename(temporary, path)) {
    backup <- tempfile(
      pattern = ".previous-current-",
      tmpdir = dirname(path),
      fileext = ".rds"
    )
    on.exit(unlink(backup, force = TRUE), add = TRUE)
    if (
      !file.exists(path) ||
        !file.rename(path, backup) ||
        !file.rename(temporary, path)
    ) {
      if (!file.exists(path) && file.exists(backup)) {
        file.rename(backup, path)
      }
      stop("Could not atomically save AOFM cache metadata.", call. = FALSE)
    }
  }
  invisible(path)
}

aofm_read_cache_metadata <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(
    readRDS(path),
    error = function(error) {
      warning(
        "Unreadable AOFM cache metadata will be repaired: ",
        conditionMessage(error),
        call. = FALSE
      )
      NULL
    }
  )
}

aofm_cache_entry_status <- function(
    metadata, paths, row, max_bytes, max_age) {
  required <- c(
    "schema_version", "table_id", "source_url", "source_filename",
    "cache_file", "raw_sha256", "raw_bytes", "retrieved_at"
  )
  if (!is.list(metadata) || length(setdiff(required, names(metadata)))) {
    return("metadata schema changed")
  }
  expected <- list(
    schema_version = 1L,
    table_id = as.character(row$id[[1L]]),
    source_url = as.character(row$file.path[[1L]]),
    source_filename = as.character(row$file.save[[1L]])
  )
  if (any(vapply(names(expected), function(name) {
    !identical(metadata[[name]], expected[[name]])
  }, logical(1)))) {
    return("table identity changed")
  }
  extension <- tolower(tools::file_ext(row$file.save[[1L]]))
  expected_file <- paste0(metadata$raw_sha256, ".", extension)
  if (
    !is.character(metadata$raw_sha256) ||
      length(metadata$raw_sha256) != 1L ||
      !grepl("^[a-f0-9]{64}$", metadata$raw_sha256) ||
      !identical(metadata$cache_file, expected_file)
  ) {
    return("content-addressed filename is invalid")
  }
  file <- file.path(paths$table_directory, metadata$cache_file)
  if (!file.exists(file)) return("cached workbook is missing")
  resolved <- normalizePath(file, winslash = "/", mustWork = TRUE)
  if (!startsWith(resolved, paste0(paths$table_directory, "/"))) {
    return("cached workbook escaped its table directory")
  }
  bytes <- unname(file.info(file)$size)
  if (
    is.na(bytes) ||
      bytes <= 0 ||
      bytes > max_bytes ||
      !identical(as.numeric(metadata$raw_bytes), as.numeric(bytes))
  ) {
    return("raw byte verification failed")
  }
  raw_sha256 <- digest::digest(
    file,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
  if (!identical(raw_sha256, metadata$raw_sha256)) {
    return("raw SHA-256 verification failed")
  }
  retrieved_at <- as.POSIXct(metadata$retrieved_at, tz = "UTC")
  age <- as.numeric(difftime(Sys.time(), retrieved_at, units = "secs"))
  if (is.na(age) || age < -60 || age > max_age) {
    return("cache age bound failed")
  }
  NA_character_
}

aofm_owned_cache_files <- function(data_root) {
  if (!dir.exists(data_root)) return(character())
  data_root <- normalizePath(data_root, winslash = "/", mustWork = TRUE)
  table_directories <- list.dirs(
    data_root,
    recursive = FALSE,
    full.names = TRUE
  )
  files <- unique(unlist(lapply(table_directories, function(directory) {
    link <- Sys.readlink(directory)
    resolved <- normalizePath(directory, winslash = "/", mustWork = TRUE)
    if (
      (!is.na(link) && nzchar(link)) ||
        !startsWith(resolved, paste0(data_root, "/"))
    ) {
      stop(
        "A readAOFM cache directory escaped through a symlink.",
        call. = FALSE
      )
    }
    candidates <- list.files(
      directory,
      pattern = "^[a-f0-9]{64}\\.(xls|xlsx)$",
      full.names = TRUE,
      ignore.case = TRUE
    )
    for (candidate in candidates) {
      file_link <- Sys.readlink(candidate)
      file_resolved <- normalizePath(
        candidate,
        winslash = "/",
        mustWork = TRUE
      )
      if (
        (!is.na(file_link) && nzchar(file_link)) ||
          !startsWith(file_resolved, paste0(resolved, "/"))
      ) {
        stop(
          "A readAOFM cache file escaped through a symlink.",
          call. = FALSE
        )
      }
    }
    candidates
  }), use.names = FALSE))
  files
}

aofm_prune_cache <- function(
    paths, keep_file, max_age, max_files, max_cache_bytes) {
  files <- aofm_owned_cache_files(paths$data_root)
  if (!length(files)) return(invisible(NULL))
  now <- Sys.time()
  age <- as.numeric(difftime(now, file.info(files)$mtime, units = "secs"))
  expired <- files[
    !is.na(age) &
      age > max_age &
      normalizePath(files, winslash = "/", mustWork = FALSE) != keep_file
  ]
  if (length(expired)) unlink(expired, force = TRUE)
  files <- setdiff(files, expired)

  current_metadata <- list.files(
    paths$data_root,
    pattern = "^current\\.rds$",
    recursive = TRUE,
    full.names = TRUE
  )
  current_map <- character()
  for (metadata_path in current_metadata) {
    metadata <- suppressWarnings(tryCatch(
      readRDS(metadata_path),
      error = function(error) NULL
    ))
    if (
      is.list(metadata) &&
        is.character(metadata$cache_file) &&
        length(metadata$cache_file) == 1L
    ) {
      current_map[file.path(dirname(metadata_path), metadata$cache_file)] <-
        metadata_path
    }
  }

  while (
    length(files) > max_files ||
      sum(file.info(files)$size, na.rm = TRUE) > max_cache_bytes
  ) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    noncurrent <- !files %in% names(current_map)
    removable <- files[noncurrent & normalized != keep_file]
    if (!length(removable)) {
      removable <- files[normalized != keep_file]
    }
    if (!length(removable)) {
      unlink(c(keep_file, paths$metadata), force = TRUE)
      stop(
        "The retained AOFM workbook alone exceeds cache bounds.",
        call. = FALSE
      )
    }
    modified <- file.info(removable)$mtime
    remove <- removable[order(modified)][[1L]]
    unlink(remove, force = TRUE)
    if (remove %in% names(current_map)) {
      unlink(unname(current_map[[remove]]), force = TRUE)
    }
    files <- setdiff(files, remove)
  }
  invisible(NULL)
}

aofm_download_metadata <- function(path, metadata, cache_hit) {
  result <- normalizePath(path, winslash = "/", mustWork = TRUE)
  metadata$cache_hit <- isTRUE(cache_hit)
  attr(result, "table_id") <- metadata$table_id
  attr(result, "source_url") <- metadata$source_url
  attr(result, "raw_sha256") <- metadata$raw_sha256
  attr(result, "raw_bytes") <- metadata$raw_bytes
  attr(result, "retrieved_at") <- metadata$retrieved_at
  attr(result, "cache_hit") <- metadata$cache_hit
  attr(result, "aofm_metadata") <- metadata
  result
}

#' Download one AOFM workbook by stable table ID
#'
#' This is the explicit, managed-download API. It retrieves one current AOFM
#' workbook over HTTPS, verifies its size and SHA-256 digest, and stores it in
#' a content-addressed cache. Use [read_aofm_file()] to parse a retained local
#' file without another network request.
#'
#' @param table_id A stable, parser-supported `table_id` returned by
#'   [aofm_catalog()]. Raw-only/unsupported rows are rejected because no local
#'   parser contract exists for them.
#' @param path Root directory selected by the caller for the managed cache
#'   (default `tempdir()`). The function creates
#'   `.readAOFM/data/<table_id>/` below this root; it does not write to the
#'   package installation, the global workspace, or the user's home directory
#'   unless that location is explicitly supplied as `path`.
#' @param overwrite Logical scalar (default `TRUE`). Download and verify the
#'   current workbook even when a valid content-addressed cache entry exists.
#'   Set `FALSE` to reuse a valid entry within `max_age`.
#' @param timeout Per-attempt HTTPS transport timeout in seconds (default from
#'   `getOption("readAOFM.timeout", 30)`).
#' @param retries Non-negative number of retries after the first transport
#'   attempt (default from `getOption("readAOFM.retries", 1L)`).
#' @param max_bytes Maximum accepted workbook size in bytes (default from
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`).
#' @param max_age Maximum age of a cache entry in seconds when
#'   `overwrite = FALSE` (default from `getOption("readAOFM.max_age", 7 *
#'   24 * 60^2)`). Expired entries are refreshed.
#' @param max_files Maximum number of content-addressed workbooks retained
#'   below the selected cache root (default from
#'   `getOption("readAOFM.max_files", 100L)`).
#' @param max_cache_bytes Maximum combined byte size of retained workbooks
#'   (default from `getOption("readAOFM.max_cache_bytes", 500 * 1024^2)`).
#' @param lock_timeout Maximum seconds to wait for another writer for the same
#'   table (default from `getOption("readAOFM.lock_timeout", 10)`).
#' @returns A normalized character path to the verified workbook. The returned
#'   path has `table_id`, `source_url`, `raw_sha256`, `raw_bytes`,
#'   `retrieved_at`, `cache_hit`, and `aofm_metadata` attributes. The metadata
#'   list records the schema version, source filename, content-addressed cache
#'   filename, exact byte count, SHA-256 digest, and UTC retrieval time.
#'
#' @details
#' Each table cache contains a SHA-256-named `.xls`/`.xlsx` file, a
#' `current.rds` metadata record, and a short-lived writer lock. Successful
#' downloads prune old entries according to `max_age`, `max_files`, and
#' `max_cache_bytes`; the current verified file is retained. Temporary staging
#' files and atomic metadata replacement prevent partial downloads from being
#' exposed. The managed cache is opt-in through this function; the legacy
#' [download_aofm_xlsx()] and [read_aofm()] workflows retain their existing
#' temporary staging and explicit `data/`/`output/` side effects.
#' On Windows, an old same-host lock is conservatively treated as active
#' because base R has no non-terminating process-liveness probe there; the
#' caller receives the usual lock-timeout error instead of the package risking
#' termination of the lock owner.
#'
#' Invalid table IDs, unsupported rows, unsafe paths or bounds, lock timeouts,
#' HTTP/transport failures, non-workbook responses, oversized files, and
#' failed integrity checks throw errors. No credentials are required. AOFM
#' controls the remote URL and workbook layout, so a source change can require
#' a package update.
#'
#' @seealso [aofm_catalog()] for offline discovery, [aofm_file_metadata()] for
#' local provenance, [read_aofm_file()] for offline parsing, and
#' [download_aofm_xlsx()] for the legacy explicit `data/` download workflow.
#' @examples
#' # Downloading is deliberately interactive because it contacts the live
#' # AOFM website. The bounds keep an example transfer finite.
#' if (interactive()) {
#'   cache_root <- tempfile("readAOFM-cache-")
#'   workbook <- download_aofm_file(
#'     "tb_issuance",
#'     path = cache_root,
#'     overwrite = FALSE,
#'     timeout = 5,
#'     retries = 0,
#'     max_bytes = 50 * 1024^2,
#'     max_age = 24 * 60^2,
#'     max_files = 2,
#'     max_cache_bytes = 100 * 1024^2,
#'     lock_timeout = 5
#'   )
#'   c(path = workbook, sha256 = attr(workbook, "raw_sha256"))
#' }
#' @export
download_aofm_file <- function(
    table_id,
    path = tempdir(),
    overwrite = TRUE,
    timeout = getOption("readAOFM.timeout", 30),
    retries = getOption("readAOFM.retries", 1L),
    max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2),
    max_age = getOption("readAOFM.max_age", 7 * 24 * 60^2),
    max_files = getOption("readAOFM.max_files", 100L),
    max_cache_bytes = getOption(
      "readAOFM.max_cache_bytes",
      500 * 1024^2
    ),
    lock_timeout = getOption("readAOFM.lock_timeout", 10)) {
  row <- aofm_supported_table_row(table_id)
  if (
    length(overwrite) != 1L ||
      is.na(overwrite) ||
      !is.logical(overwrite)
  ) {
    stop("`overwrite` must be one non-missing logical value.", call. = FALSE)
  }
  aofm_validate_transport_bounds(timeout, retries, max_bytes, lock_timeout)
  cache_bounds <- list(
    max_age = max_age,
    max_files = max_files,
    max_cache_bytes = max_cache_bytes
  )
  if (
    any(!vapply(cache_bounds, is.numeric, logical(1))) ||
      any(vapply(cache_bounds, length, integer(1)) != 1L) ||
      anyNA(vapply(cache_bounds, as.numeric, numeric(1))) ||
      any(!is.finite(vapply(cache_bounds, as.numeric, numeric(1)))) ||
      max_age <= 0 ||
      max_age > 365 * 24 * 60^2 ||
      max_files <= 0 ||
      max_files != floor(max_files) ||
      max_files > 10000 ||
      max_cache_bytes <= 0 ||
      max_cache_bytes > 100 * 1024^3 ||
      max_bytes > max_cache_bytes
  ) {
    stop(
      "AOFM cache bounds must be numeric scalars within supported limits.",
      call. = FALSE
    )
  }
  max_files <- as.integer(max_files)
  paths <- aofm_cache_paths(path, row$id[[1L]])
  aofm_validate_official_url(row$file.path[[1L]])
  lock_owner <- aofm_acquire_lock(paths$lock, lock_timeout)
  on.exit(aofm_release_lock(paths$lock, lock_owner), add = TRUE)

  metadata <- aofm_read_cache_metadata(paths$metadata)
  previous_metadata <- metadata
  previous_valid <- !is.null(previous_metadata) &&
    is.na(aofm_cache_entry_status(
      previous_metadata,
      paths,
      row,
      max_bytes,
      Inf
    ))
  invalid_reason <- if (is.null(metadata)) {
    "cache metadata is missing"
  } else {
    aofm_cache_entry_status(metadata, paths, row, max_bytes, max_age)
  }
  valid_cache <- !isTRUE(overwrite) && is.na(invalid_reason)
  if (
    !is.null(metadata) &&
      !is.na(invalid_reason) &&
      !identical(invalid_reason, "cache age bound failed")
  ) {
    warning(
      "Invalid AOFM cache entry (", invalid_reason,
      "); downloading and repairing it.",
      call. = FALSE
    )
  }
  if (!valid_cache) {
    extension <- tolower(tools::file_ext(row$file.save[[1L]]))
    temporary <- tempfile(
      pattern = ".download-",
      tmpdir = paths$table_directory,
      fileext = paste0(".", extension)
    )
    on.exit(unlink(temporary, force = TRUE), add = TRUE)
    download_aofm_workbook(
      row$file.path[[1L]],
      temporary,
      timeout = timeout,
      retries = retries,
      max_bytes = max_bytes,
      lock_timeout = lock_timeout,
      official_only = TRUE
    )
    raw_bytes <- unname(file.info(temporary)$size)
    raw_sha256 <- digest::digest(
      temporary,
      algo = "sha256",
      file = TRUE,
      serialize = FALSE
    )
    cache_file <- paste0(raw_sha256, ".", extension)
    destination <- file.path(paths$table_directory, cache_file)
    promoted_destination <- FALSE
    if (file.exists(destination)) {
      resolved <- normalizePath(destination, winslash = "/", mustWork = TRUE)
      existing_sha256 <- if (
        startsWith(resolved, paste0(paths$table_directory, "/"))
      ) {
        digest::digest(
          destination,
          algo = "sha256",
          file = TRUE,
          serialize = FALSE
        )
      } else {
        ""
      }
      if (!identical(existing_sha256, raw_sha256)) {
        unlink(destination, force = TRUE)
      }
    }
    if (!file.exists(destination) && !file.rename(temporary, destination)) {
      stop(
        "Could not atomically promote the content-addressed AOFM workbook.",
        call. = FALSE
      )
    }
    promoted_destination <- !file.exists(temporary)
    retrieved_at <- as.POSIXct(Sys.time(), tz = "UTC")
    Sys.setFileTime(destination, retrieved_at)
    metadata <- list(
      schema_version = 1L,
      table_id = as.character(row$id[[1L]]),
      source_url = as.character(row$file.path[[1L]]),
      source_filename = as.character(row$file.save[[1L]]),
      cache_file = cache_file,
      raw_sha256 = raw_sha256,
      raw_bytes = raw_bytes,
      retrieved_at = retrieved_at
    )
    aofm_atomic_save_rds(metadata, paths$metadata)
    final_metadata <- aofm_read_cache_metadata(paths$metadata)
    final_reason <- aofm_cache_entry_status(
      final_metadata,
      paths,
      row,
      max_bytes,
      max_age
    )
    if (!is.na(final_reason)) {
      if (file.exists(paths$metadata)) {
        unlink(paths$metadata, force = TRUE)
      }
      if (
        !promoted_destination &&
          file.exists(temporary)
      ) {
        file.copy(temporary, destination, overwrite = TRUE)
      } else if (promoted_destination && file.exists(destination)) {
        unlink(destination, force = TRUE)
      }
      if (previous_valid) {
        aofm_atomic_save_rds(previous_metadata, paths$metadata)
      }
      stop(
        sprintf(
          "The stored AOFM cache pair failed final verification: %s.",
          final_reason
        ),
        call. = FALSE
      )
    }
    metadata <- final_metadata
  }

  destination <- normalizePath(
    file.path(paths$table_directory, metadata$cache_file),
    winslash = "/",
    mustWork = TRUE
  )
  aofm_prune_cache(
    paths,
    destination,
    max_age = max_age,
    max_files = max_files,
    max_cache_bytes = max_cache_bytes
  )
  aofm_download_metadata(destination, metadata, valid_cache)
}

#' Exact provenance for a local AOFM workbook
#'
#' Computes byte-level provenance without downloading or modifying the
#' workbook. It can inspect a packaged fixture, an arbitrary local workbook,
#' or a path returned by [download_aofm_file()].
#'
#' @param file_path A path to one existing local `.xls` or `.xlsx` workbook.
#'   The file is read to compute its byte count and SHA-256 digest.
#' @param table_id Optional parser-supported stable AOFM table ID. Supply it
#'   when checking a standalone local file; a managed-cache path can carry the
#'   table ID in its download metadata.
#' @returns A named list with `table_id`, `source_url`, `source_filename`,
#'   numeric `raw_bytes`, lowercase hexadecimal `raw_sha256`, UTC POSIXct
#'   `retrieved_at`, `package_version`, and logical `cache_hit`. For a
#'   standalone local file, `source_url` is `NA` and `retrieved_at` is the
#'   file's modification time; managed-cache provenance is retained only when
#'   its metadata and bytes still agree.
#'
#' @details
#' This function performs no network request, creates no cache, and has no
#' output side effect. Invalid paths, unsupported file extensions, malformed
#' managed-cache metadata, and unknown table IDs are reported as errors or as
#' unqualified local provenance rather than being silently treated as current
#' AOFM data.
#'
#' @seealso [download_aofm_file()] for verified managed retrieval and
#' [read_aofm_file()] for parsing a local workbook.
#' @examples
#' fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
#' if (nzchar(fixture)) {
#'   metadata <- aofm_file_metadata(fixture, table_id = "tb_issuance")
#'   metadata[c("table_id", "source_filename", "raw_bytes", "raw_sha256")]
#' }
#' @export
aofm_file_metadata <- function(file_path, table_id = NULL) {
  if (
    !is.character(file_path) ||
      length(file_path) != 1L ||
      is.na(file_path) ||
      !file.exists(file_path)
  ) {
    stop("`file_path` must identify one existing workbook.", call. = FALSE)
  }
  extension <- tolower(tools::file_ext(file_path))
  if (!extension %in% c("xls", "xlsx")) {
    stop("AOFM metadata requires an .xls or .xlsx workbook.", call. = FALSE)
  }
  inherited <- attr(file_path, "aofm_metadata")
  resolved_row <- if (!is.null(table_id)) {
    aofm_supported_table_row(table_id)
  } else {
    tryCatch(
      aofm_supported_table_row(inherited$table_id),
      error = function(error) NULL
    )
  }
  resolved_table <- if (is.null(resolved_row)) {
    NA_character_
  } else {
    resolved_row$id[[1L]]
  }
  raw_bytes <- unname(file.info(file_path)$size)
  raw_sha256 <- digest::digest(
    file_path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
  inherited_time <- suppressWarnings(as.POSIXct(
    if (is.list(inherited)) inherited$retrieved_at else NA,
    tz = "UTC"
  ))
  inherited_url_valid <- is.list(inherited) &&
    tryCatch(
      {
        aofm_validate_official_url(inherited$source_url)
        TRUE
      },
      error = function(error) FALSE
    )
  resolved_file <- normalizePath(
    file_path,
    winslash = "/",
    mustWork = TRUE
  )
  table_directory <- dirname(resolved_file)
  metadata_path <- file.path(table_directory, "current.rds")
  persisted <- if (
    is.list(inherited) &&
      identical(basename(table_directory), resolved_table) &&
      identical(basename(dirname(table_directory)), "data") &&
      identical(basename(dirname(dirname(table_directory))), ".readAOFM") &&
      identical(basename(resolved_file), inherited$cache_file) &&
      file.exists(metadata_path) &&
      !nzchar(Sys.readlink(metadata_path))
  ) {
    tryCatch(readRDS(metadata_path), error = function(error) NULL)
  } else {
    NULL
  }
  persisted_fields <- c(
    "schema_version", "table_id", "source_url", "source_filename",
    "cache_file", "raw_sha256", "raw_bytes", "retrieved_at"
  )
  persisted_matches <- is.list(persisted) &&
    !length(setdiff(persisted_fields, names(persisted))) &&
    all(vapply(persisted_fields, function(name) {
      identical(inherited[[name]], persisted[[name]])
    }, logical(1))) &&
    is.na(aofm_cache_entry_status(
      persisted,
      list(table_directory = table_directory),
      resolved_row,
      Inf,
      Inf
    ))
  inherited_valid <- is.list(inherited) &&
    !is.null(resolved_row) &&
    identical(inherited$schema_version, 1L) &&
    identical(as.character(inherited$table_id), resolved_table) &&
    identical(
      as.character(inherited$source_url),
      as.character(resolved_row$file.path[[1L]])
    ) &&
    identical(
      as.character(inherited$source_filename),
      as.character(resolved_row$file.save[[1L]])
    ) &&
    identical(as.character(inherited$raw_sha256), raw_sha256) &&
    identical(as.numeric(inherited$raw_bytes), as.numeric(raw_bytes)) &&
    inherited_url_valid &&
    persisted_matches &&
    length(inherited_time) == 1L &&
    !is.na(inherited_time) &&
    inherited_time <= Sys.time() + 60
  source_url <- if (inherited_valid) inherited$source_url else NA_character_
  source_filename <- if (inherited_valid) {
    inherited$source_filename
  } else {
    basename(file_path)
  }
  retrieved_at <- if (inherited_valid) {
    inherited_time
  } else {
    as.POSIXct(file.info(file_path)$mtime, tz = "UTC")
  }
  if (is.null(resolved_table) || !length(resolved_table)) {
    resolved_table <- NA_character_
  }
  if (is.null(source_url) || !length(source_url)) {
    source_url <- NA_character_
  }
  list(
    table_id = as.character(resolved_table),
    source_url = as.character(source_url),
    source_filename = source_filename,
    raw_bytes = raw_bytes,
    raw_sha256 = raw_sha256,
    retrieved_at = as.POSIXct(retrieved_at, tz = "UTC"),
    package_version = as.character(utils::packageVersion("readAOFM")),
    cache_hit = isTRUE(if (inherited_valid) inherited$cache_hit else FALSE)
  )
}

aofm_dispatch_parse <- function(file_path, table_id, reader, csv = FALSE) {
  switch(
    reader,
    read_eofy = aofm_parse_eofy_workbook(file_path, csv = csv),
    read_eom = aofm_parse_eom_workbook(
      file_path,
      aofm_table = table_id,
      csv = csv
    ),
    read_transactional = aofm_parse_transactional_workbook(
      file_path,
      aofm_table = table_id,
      csv = csv
    ),
    read_syndication = aofm_parse_syndication_workbook(
      file_path,
      aofm_table = table_id,
      csv = csv
    ),
    read_ownership = aofm_parse_ownership_workbook(
      file_path,
      aofm_table = table_id,
      csv = csv
    ),
    read_secondary = aofm_parse_secondary_workbook(
      file_path,
      aofm_table = table_id,
      csv = csv
    ),
    read_premium = aofm_parse_premium_workbook(
      file_path,
      aofm_table = table_id,
      csv = csv
    ),
    stop(
      sprintf("No local-file parser exists for AOFM table '%s'.", table_id),
      call. = FALSE
    )
  )
}

#' Parse a local AOFM workbook
#'
#' This function separates retrieval from parsing so callers can retain and
#' hash an immutable raw workbook before normalising its observations. It is
#' deterministic for a fixed local workbook and never contacts the AOFM
#' website.
#'
#' @param file_path Path to an existing local AOFM `.xls` or `.xlsx` workbook.
#'   The file is not copied or removed.
#' @param table_id A stable parser-supported `table_id` returned by
#'   [aofm_catalog()]. The ID selects the workbook-family parser and must match
#'   the local file's layout.
#' @param csv Logical scalar (default `FALSE`). When `TRUE`, also writes the
#'   parser's legacy CSV output below `output/` in the current working
#'   directory. Leave `FALSE` for a read-only parse.
#' @returns The same family-specific data-frame or named-list result as
#'   [read_aofm()], with an `aofm_metadata` attribute containing local
#'   byte-level provenance. Long-form results commonly contain identifier/date
#'   or period columns, `name`, and `value`; exact measure columns and list
#'   components follow the selected AOFM workbook family.
#'
#' @details
#' This local-file API performs no network request and does not use or populate
#' the managed `.readAOFM` cache. Use [download_aofm_file()] first when a
#' verified managed retrieval is desired. Unsupported/raw-only catalogue rows,
#' missing files, invalid IDs, and layouts that do not satisfy the selected
#' parser's contract throw errors. With `csv = TRUE`, the explicit `output/`
#' write is the parser's legacy side effect; it is separate from managed cache
#' storage.
#'
#' @seealso [download_aofm_file()] for managed retrieval,
#'   [aofm_file_metadata()] for standalone provenance, and [read_aofm()] for
#'   the legacy download-and-parse workflow.
#' @examples
#' fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
#' if (nzchar(fixture)) {
#'   issuance <- read_aofm_file(fixture, "tb_issuance")
#'   utils::head(issuance[, c("date_held", "name", "value")])
#'   attr(issuance, "aofm_metadata")[c("table_id", "raw_sha256")]
#' }
#' @export
read_aofm_file <- function(file_path, table_id, csv = FALSE) {
  row <- aofm_supported_table_row(table_id)

  if (!is.character(file_path) ||
      length(file_path) != 1L ||
      is.na(file_path) ||
      !nzchar(trimws(file_path))) {
    stop("`file_path` must be a single non-empty string.", call. = FALSE)
  }
  if (!file.exists(file_path)) {
    stop(sprintf("AOFM workbook does not exist at '%s'.", file_path), call. = FALSE)
  }

  parsed <- aofm_dispatch_parse(
    file_path = file_path,
    table_id = row$id[[1]],
    reader = row$fn[[1]],
    csv = csv
  )
  attr(parsed, "aofm_metadata") <- aofm_file_metadata(
    file_path,
    row$id[[1L]]
  )
  parsed
}
