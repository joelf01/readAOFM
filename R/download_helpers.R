aofm_catalog_overrides <- function() {
  configured <- getOption("readAOFM.url_overrides", NULL)
  defaults <- stats::setNames(
    as.character(aofm_index$file.path),
    as.character(aofm_index$id)
  )

  if (is.null(configured)) {
    return(defaults)
  }
  configured_names <- names(configured)
  if (
    !is.character(configured) ||
      is.null(configured_names) ||
      anyNA(configured) ||
      anyNA(configured_names) ||
      any(!nzchar(trimws(configured))) ||
      any(!nzchar(trimws(configured_names))) ||
      anyDuplicated(configured_names) ||
      any(!configured_names %in% names(defaults))
  ) {
    stop(
      paste0(
        "`options(readAOFM.url_overrides = ...)` must be a uniquely named ",
        "character vector; supported override names must be catalogue table IDs."
      ),
      call. = FALSE
    )
  }
  for (name in configured_names) {
    aofm_validate_official_url(
      configured[[name]],
      sprintf("AOFM URL override '%s'", name)
    )
  }

  defaults[configured_names] <- configured
  defaults
}

aofm_turnover_history_urls <- function() {
  c(
    tb_turnover = paste0(
      "https://www.aofm.gov.au/sites/default/files/2025-05-02/",
      "turnover_-_treasury_bonds.xlsx"
    ),
    tib_turnover = paste0(
      "https://www.aofm.gov.au/sites/default/files/2025-05-02/",
      "turnover_-_treasury_indexed_bonds.xlsx"
    )
  )
}

aofm_apply_catalog_overrides <- function(catalog) {
  overrides <- aofm_catalog_overrides()
  matched <- match(catalog$id, names(overrides))
  replace <- !is.na(matched)
  catalog$file.path[replace] <- unname(overrides[matched[replace]])
  catalog
}

aofm_table_row <- function(aofm_table) {
  row <- aofm_index[aofm_index$id == aofm_table, , drop = FALSE]

  if (nrow(row) != 1L) {
    stop(sprintf("Could not resolve a unique table row for '%s'.", aofm_table), call. = FALSE)
  }

  aofm_apply_catalog_overrides(row)
}

aofm_validate_transport_bounds <- function(
    timeout, retries, max_bytes, lock_timeout = 10) {
  values <- list(
    timeout = timeout,
    retries = retries,
    max_bytes = max_bytes,
    lock_timeout = lock_timeout
  )
  if (any(!vapply(values, is.numeric, logical(1)))) {
    stop("Transport bounds must be numeric.", call. = FALSE)
  }
  if (any(vapply(values, length, integer(1)) != 1L)) {
    stop("Transport bounds must be scalar.", call. = FALSE)
  }
  numeric_values <- vapply(values, as.numeric, numeric(1))
  if (anyNA(numeric_values) || any(!is.finite(numeric_values))) {
    stop("Transport bounds must be finite numbers.", call. = FALSE)
  }
  if (
    timeout <= 0 ||
      max_bytes <= 0 ||
      lock_timeout <= 0 ||
      retries < 0 ||
      retries != floor(retries) ||
      timeout > 300 ||
      retries > 5 ||
      max_bytes > 1024^3 ||
      lock_timeout > 300
  ) {
    stop(
      "Timeouts and byte bounds must be positive; retries must be a non-negative integer.",
      call. = FALSE
    )
  }
  invisible(NULL)
}

aofm_validate_official_url <- function(url, context = "AOFM URL") {
  if (
    !is.character(url) ||
      length(url) != 1L ||
      is.na(url) ||
      !nzchar(trimws(url))
  ) {
    stop(sprintf("%s must be one non-empty URL.", context), call. = FALSE)
  }
  parsed <- tryCatch(
    curl::curl_parse_url(url),
    error = function(error) {
      stop(
        sprintf("%s is invalid: %s", context, conditionMessage(error)),
        call. = FALSE
      )
    }
  )
  if (
    !identical(tolower(parsed$scheme), "https") ||
      !tolower(parsed$host) %in% c("www.aofm.gov.au", "aofm.gov.au") ||
      (!is.null(parsed$port) && !identical(parsed$port, "443")) ||
      !is.null(parsed$user) ||
      !is.null(parsed$password)
  ) {
    stop(
      sprintf("%s must use official AOFM HTTPS infrastructure.", context),
      call. = FALSE
    )
  }
  invisible(url)
}

aofm_acquire_lock <- function(path, timeout = 10) {
  started <- Sys.time()
  repeat {
    if (dir.create(path, recursive = FALSE, showWarnings = FALSE)) {
      owner_path <- file.path(path, "owner.rds")
      owner <- list(
        token = basename(tempfile(pattern = "aofm-lock-owner-")),
        pid = Sys.getpid(),
        host = unname(Sys.info()[["nodename"]]),
        created_at = as.POSIXct(Sys.time(), tz = "UTC")
      )
      stored <- tryCatch(
        {
          saveRDS(owner, owner_path, version = 3)
          TRUE
        },
        error = function(error) FALSE
      )
      if (!stored) {
        unlink(path, recursive = TRUE, force = TRUE)
        stop("Could not record the AOFM cache lock owner.", call. = FALSE)
      }
      return(invisible(owner))
    }
    info <- file.info(path)
    age <- as.numeric(difftime(Sys.time(), info$mtime, units = "secs"))
    if (!is.na(age) && age > max(60, timeout * 5)) {
      owner <- tryCatch(
        readRDS(file.path(path, "owner.rds")),
        error = function(error) NULL
      )
      local_host <- unname(Sys.info()[["nodename"]])
      owner_pid <- suppressWarnings(as.integer(owner$pid))
      owner_is_local <- is.list(owner) &&
        identical(as.character(owner$host), local_host) &&
        length(owner_pid) == 1L &&
        !is.na(owner_pid) &&
        owner_pid > 0L
      owner_alive <- if (owner_is_local && .Platform$OS.type == "windows") {
        # tools::pskill() always calls TerminateProcess on Windows, including
        # for signal 0. Fail closed instead of probing and killing the owner.
        TRUE
      } else if (owner_is_local) {
        tryCatch(
          isTRUE(tools::pskill(owner_pid, signal = 0L)),
          error = function(error) FALSE
        )
      } else {
        TRUE
      }
      if (owner_is_local && !owner_alive) {
        unlink(path, recursive = TRUE, force = TRUE)
        next
      }
    }
    if (as.numeric(difftime(Sys.time(), started, units = "secs")) >= timeout) {
      stop("Timed out waiting for an AOFM cache lock.", call. = FALSE)
    }
    Sys.sleep(0.05)
  }
}

aofm_release_lock <- function(path, owner) {
  if (
    !dir.exists(path) ||
      !is.list(owner) ||
      !is.character(owner$token) ||
      length(owner$token) != 1L ||
      is.na(owner$token) ||
      !nzchar(owner$token)
  ) {
    return(invisible(FALSE))
  }
  current <- tryCatch(
    readRDS(file.path(path, "owner.rds")),
    error = function(error) NULL
  )
  if (
    !is.list(current) ||
      !identical(current$token, owner$token)
  ) {
    return(invisible(FALSE))
  }
  unlink(path, recursive = TRUE, force = TRUE)
  invisible(!dir.exists(path))
}

aofm_retry_after <- function(response, now = Sys.time(), maximum = 5) {
  if (!is.list(response) || is.null(response$headers)) {
    return(NA_real_)
  }
  headers <- response$headers
  if (is.raw(headers)) headers <- rawToChar(headers)
  headers <- paste(as.character(headers), collapse = "\n")
  match <- regexec(
    "(?im)^retry-after[[:space:]]*:[[:space:]]*([^\\r\\n]+)",
    headers,
    perl = TRUE
  )
  captured <- regmatches(headers, match)[[1L]]
  if (length(captured) < 2L) return(NA_real_)
  value <- trimws(captured[[2L]])
  seconds <- suppressWarnings(as.numeric(value))
  if (is.na(seconds)) {
    retry_at <- tryCatch(curl::parse_date(value), error = function(error) NA)
    seconds <- as.numeric(difftime(retry_at, now, units = "secs"))
  }
  if (is.na(seconds) || !is.finite(seconds) || seconds < 0) {
    return(NA_real_)
  }
  min(seconds, maximum)
}

aofm_retry_delay <- function(response, attempt, maximum = 5) {
  header_delay <- aofm_retry_after(response, maximum = maximum)
  backoff <- min(0.25 * (2 ^ (attempt - 1L)), maximum)
  if (is.na(header_delay)) backoff else max(backoff, header_delay)
}

aofm_response_header <- function(response, name) {
  if (!is.list(response) || is.null(response$headers)) return(NA_character_)
  headers <- response$headers
  if (is.raw(headers)) headers <- rawToChar(headers)
  headers <- paste(as.character(headers), collapse = "\n")
  match <- regexec(
    paste0(
      "(?im)^",
      gsub("-", "[-]", name, fixed = TRUE),
      "[[:space:]]*:[[:space:]]*([^\\r\\n]+)"
    ),
    headers,
    perl = TRUE
  )
  captured <- regmatches(headers, match)[[1L]]
  if (length(captured) < 2L) NA_character_ else trimws(captured[[2L]])
}

aofm_absolute_redirect_url <- function(location, current_url) {
  if (
    !is.character(location) ||
      length(location) != 1L ||
      is.na(location) ||
      !nzchar(trimws(location))
  ) {
    stop("AOFM redirect response omitted its Location URL.", call. = FALSE)
  }
  location <- trimws(location)
  if (grepl("^https?://", location, ignore.case = TRUE)) return(location)
  parsed <- curl::curl_parse_url(current_url)
  authority <- paste0(
    parsed$scheme,
    "://",
    parsed$host,
    if (!is.null(parsed$port)) paste0(":", parsed$port) else ""
  )
  if (startsWith(location, "/")) return(paste0(authority, location))
  base_path <- sub("[?#].*$", "", parsed$path)
  base_path <- sub("[^/]*$", "", base_path)
  paste0(authority, base_path, location)
}

aofm_sleep <- function(seconds) {
  Sys.sleep(seconds)
}

download_aofm_workbook <- function(
    url,
    destfile,
    timeout = getOption("readAOFM.timeout", 30),
    retries = getOption("readAOFM.retries", 1L),
    max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2),
    lock_timeout = getOption("readAOFM.lock_timeout", 10),
    official_only = FALSE) {
  if (!is.character(url) || length(url) != 1L || is.na(url) || !nzchar(url)) {
    stop("`url` must be a single non-empty string.", call. = FALSE)
  }

  if (!is.character(destfile) || length(destfile) != 1L || is.na(destfile) || !nzchar(destfile)) {
    stop("`destfile` must be a single non-empty string.", call. = FALSE)
  }

  ext <- tolower(tools::file_ext(destfile))
  if (!ext %in% c("xls", "xlsx")) {
    stop("`destfile` must end in .xls or .xlsx.", call. = FALSE)
  }

  dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(dirname(destfile))) {
    stop(sprintf("Could not create download directory '%s'.", dirname(destfile)), call. = FALSE)
  }

  aofm_validate_transport_bounds(timeout, retries, max_bytes, lock_timeout)
  timeout <- as.numeric(timeout)
  retries <- as.integer(retries)
  max_bytes <- as.numeric(max_bytes)
  if (isTRUE(official_only)) aofm_validate_official_url(url)

  lock <- paste0(destfile, ".lock")
  lock_owner <- aofm_acquire_lock(lock, lock_timeout)
  on.exit(aofm_release_lock(lock, lock_owner), add = TRUE)

  temporary <- tempfile(
    pattern = paste0(".", basename(destfile), "-"),
    tmpdir = dirname(destfile),
    fileext = ".part"
  )
  on.exit(unlink(temporary, force = TRUE), add = TRUE)

  response <- NULL
  last_error <- NULL
  for (attempt in seq_len(retries + 1L)) {
    request_url <- url
    redirects <- 0L
    repeat {
      unlink(temporary, force = TRUE)
      handle <- curl::new_handle(
        followlocation = FALSE,
        connecttimeout = min(timeout, 10),
        timeout = timeout,
        maxfilesize_large = max_bytes,
        protocols_str = "https",
        redir_protocols_str = "https",
        useragent = paste0("readAOFM/", utils::packageVersion("readAOFM"))
      )
      response <- tryCatch(
        curl::curl_fetch_disk(request_url, temporary, handle = handle),
        error = function(e) {
          last_error <<- conditionMessage(e)
          NULL
        }
      )
      if (is.null(response)) break
      status <- if (
        is.list(response) &&
          is.numeric(response$status_code) &&
          length(response$status_code) == 1L
      ) {
        as.integer(response$status_code)
      } else {
        NA_integer_
      }
      if (!is.na(status) && status >= 300L && status < 400L) {
        redirects <- redirects + 1L
        if (redirects > 10L) {
          stop("AOFM download exceeded ten redirects.", call. = FALSE)
        }
        request_url <- aofm_absolute_redirect_url(
          aofm_response_header(response, "Location"),
          request_url
        )
        if (isTRUE(official_only)) {
          aofm_validate_official_url(request_url, "AOFM redirect target")
        }
        next
      }
      break
    }

    status <- if (
      is.list(response) &&
        is.numeric(response$status_code) &&
        length(response$status_code) == 1L
    ) {
      as.integer(response$status_code)
    } else {
      NA_integer_
    }
    retryable <- is.null(response) ||
      (!is.na(status) && status %in% c(408L, 425L, 429L, 500L, 502L, 503L, 504L))
    if (!retryable) {
      break
    }
    if (attempt <= retries) {
      aofm_sleep(aofm_retry_delay(response, attempt))
    }
  }

  if (is.null(response)) {
    stop(
      sprintf(
        "Failed to download workbook from '%s' after %d attempt(s): %s",
        url,
        retries + 1L,
        if (is.null(last_error)) "unknown download error" else last_error
      ),
      call. = FALSE
    )
  }

  if (
    isTRUE(official_only) &&
      (
        !is.list(response) ||
          !is.numeric(response$status_code) ||
          length(response$status_code) != 1L ||
          is.na(response$status_code) ||
          !is.finite(response$status_code) ||
          !is.character(response$url) ||
          length(response$url) != 1L ||
          is.na(response$url) ||
          !nzchar(response$url)
      )
  ) {
    stop(
      "Official AOFM transport did not attest a final URL and status.",
      call. = FALSE
    )
  }
  if (
    is.list(response) &&
      !is.null(response$status_code) &&
      (response$status_code < 200L || response$status_code >= 300L)
  ) {
    stop(
      sprintf(
        "Failed to download workbook from '%s' (HTTP %s).",
        url,
        response$status_code
      ),
      call. = FALSE
    )
  }
  if (isTRUE(official_only)) {
    aofm_validate_official_url(response$url, "AOFM redirect target")
  }

  content_type <- tolower(if (is.list(response) && !is.null(response$type)) response$type else "")
  if (nzchar(content_type) && grepl("^(text/|application/xhtml\\+xml|application/xml|text/html)", content_type)) {
    stop(
      sprintf(
        "Download from '%s' returned '%s' instead of a workbook.",
        url,
        response$type
      ),
      call. = FALSE
    )
  }

  info <- file.info(temporary)
  if (
    !file.exists(temporary) ||
      is.na(info$size) ||
      info$size <= 0 ||
      info$size > max_bytes
  ) {
    stop(sprintf("Download from '%s' produced an empty file.", url), call. = FALSE)
  }

  signature <- readBin(temporary, what = "raw", n = 8L)
  if (ext == "xlsx") {
    if (length(signature) < 2L || !identical(signature[1:2], charToRaw("PK"))) {
      stop(
        sprintf("Download from '%s' did not look like a valid .xlsx workbook.", url),
        call. = FALSE
      )
    }
  } else if (ext == "xls") {
    expected <- as.raw(c(0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1))
    if (length(signature) < length(expected) || !identical(signature[seq_along(expected)], expected)) {
      stop(
        sprintf("Download from '%s' did not look like a valid .xls workbook.", url),
        call. = FALSE
      )
    }
  }

  staged_sha256 <- digest::digest(
    temporary,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
  backup <- NULL
  if (file.exists(destfile)) {
    backup <- tempfile(
      pattern = paste0(".", basename(destfile), "-backup-"),
      tmpdir = dirname(destfile)
    )
    if (!file.rename(destfile, backup)) {
      stop(
        sprintf("Could not stage the existing workbook at '%s'.", destfile),
        call. = FALSE
      )
    }
    on.exit(unlink(backup, force = TRUE), add = TRUE)
  }
  if (!file.rename(temporary, destfile)) {
    if (!is.null(backup) && file.exists(backup)) {
      file.rename(backup, destfile)
    }
    stop(sprintf("Could not atomically install downloaded workbook at '%s'.", destfile), call. = FALSE)
  }
  restore_previous <- function() {
    unlink(destfile, force = TRUE)
    if (
      !is.null(backup) &&
        file.exists(backup) &&
        !file.rename(backup, destfile)
    ) {
      stop(
        "The new workbook failed verification and the prior workbook could not be restored.",
        call. = FALSE
      )
    }
    invisible(NULL)
  }
  installed_sha256 <- tryCatch(
    digest::digest(
      destfile,
      algo = "sha256",
      file = TRUE,
      serialize = FALSE
    ),
    error = function(error) {
      restore_previous()
      stop(
        paste0(
          "Could not complete final SHA-256 verification of the installed ",
          "AOFM workbook: ",
          conditionMessage(error)
        ),
        call. = FALSE
      )
    }
  )
  if (!identical(installed_sha256, staged_sha256)) {
    restore_previous()
    stop("The installed AOFM workbook failed final SHA-256 verification.", call. = FALSE)
  }

  invisible(destfile)
}

download_aofm_table_workbook <- function(
    aofm_table,
    timeout = getOption("readAOFM.timeout", 30),
    retries = getOption("readAOFM.retries", 1L),
    max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)) {
  row <- aofm_table_row(aofm_table)
  file_name <- row$file.save[[1]]
  ext <- tools::file_ext(file_name)

  if (!nzchar(ext)) {
    stop(sprintf("Could not determine a workbook extension for '%s'.", aofm_table), call. = FALSE)
  }

  tmp <- tempfile(fileext = paste0(".", ext))
  download_aofm_workbook(
    row$file.path[[1]],
    tmp,
    timeout = timeout,
    retries = retries,
    max_bytes = max_bytes,
    official_only = TRUE
  )
  attr(tmp, "aofm_source") <- aofm_workbook_source(
    tmp,
    table_id = row$id[[1]],
    source_url = row$file.path[[1]],
    role = "current"
  )
  tmp
}

aofm_workbook_source <- function(path, table_id, source_url, role) {
  if (!file.exists(path)) {
    stop("Cannot record provenance for a missing AOFM workbook.", call. = FALSE)
  }
  aofm_validate_official_url(source_url)
  if (
    !is.character(role) ||
      length(role) != 1L ||
      is.na(role) ||
      !role %in% c("historical", "current")
  ) {
    stop("AOFM workbook source role must be historical or current.", call. = FALSE)
  }
  retrieved_at <- as.POSIXct(file.info(path)$mtime, tz = "UTC")
  list(
    schema_version = 1L,
    table_id = as.character(table_id),
    role = role,
    source_url = as.character(source_url),
    source_filename = basename(utils::URLdecode(source_url)),
    raw_sha256 = digest::digest(
      path,
      algo = "sha256",
      file = TRUE,
      serialize = FALSE
    ),
    raw_bytes = unname(file.info(path)$size),
    retrieved_at = retrieved_at
  )
}
