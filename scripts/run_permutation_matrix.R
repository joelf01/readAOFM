args <- commandArgs(trailingOnly = TRUE)
out_csv <- if (length(args) >= 1) args[[1]] else "/tmp/readAOFM-permutation-test-live-v2.csv"

options(readxl.show_progress = FALSE)
pkgload::load_all(quiet = TRUE)

securities <- c(NA_character_, sort(unique(stats::na.omit(aofm_index$p.security))))
types <- c(NA_character_, sort(unique(stats::na.omit(aofm_index$p.type))))

grid <- expand.grid(
  security = securities,
  type = types,
  csv = c(FALSE, TRUE),
  stringsAsFactors = FALSE
)

run_dir <- file.path(tempdir(), "readAOFM-matrix-v2")
dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
old_wd <- setwd(run_dir)
on.exit(setwd(old_wd), add = TRUE)

call_read_aofm <- function(security, type, csv) {
  security_arg <- if (is.na(security)) NULL else security
  type_arg <- if (is.na(type)) NULL else type

  suppressMessages(
    suppressWarnings(
      read_aofm(security = security_arg, type = type_arg, csv = csv)
    )
  )
}

results <- lapply(seq_len(nrow(grid)), function(i) {
  security <- grid$security[[i]]
  type <- grid$type[[i]]
  csv <- grid$csv[[i]]

  out <- tryCatch(
    {
      value <- call_read_aofm(security, type, csv)
      list(
        status = "success",
        class = paste(class(value), collapse = ","),
        size = if (is.data.frame(value)) nrow(value) else length(value),
        message = NA_character_
      )
    },
    error = function(e) {
      list(
        status = "error",
        class = NA_character_,
        size = NA_integer_,
        message = conditionMessage(e)
      )
    }
  )

  data.frame(
    security = if (is.na(security)) NA_character_ else security,
    type = if (is.na(type)) NA_character_ else type,
    csv = csv,
    status = out$status,
    class = out$class,
    size = out$size,
    message = out$message,
    stringsAsFactors = FALSE
  )
})

results <- do.call(rbind, results)
write.csv(results, out_csv, row.names = FALSE)

supported <- unique(
  subset(
    aofm_index,
    fn != "no function exists" & !is.na(p.security) & !is.na(p.type),
    select = c(id, p.security, p.type)
  )
)

pair_summary <- do.call(
  rbind,
  lapply(seq_len(nrow(supported)), function(i) {
    rows <- subset(
      results,
      security == supported$p.security[[i]] & type == supported$p.type[[i]]
    )

    data.frame(
      id = supported$id[[i]],
      security = supported$p.security[[i]],
      type = supported$p.type[[i]],
      success_both_csv_modes = nrow(rows) == 2 && all(rows$status == "success"),
      csv_false_status = rows$status[rows$csv == FALSE][1],
      csv_true_status = rows$status[rows$csv == TRUE][1],
      csv_false_message = rows$message[rows$csv == FALSE][1],
      csv_true_message = rows$message[rows$csv == TRUE][1],
      stringsAsFactors = FALSE
    )
  })
)

cat("TOTAL_CASES", nrow(results), "\n")
cat("TOTAL_SUCCESSES", sum(results$status == "success"), "\n")
cat("TOTAL_ERRORS", sum(results$status == "error"), "\n")
cat("SUPPORTED_PAIRS", nrow(pair_summary), "\n")
cat("SUPPORTED_PAIRS_SUCCESS_BOTH", sum(pair_summary$success_both_csv_modes), "\n")

failing <- subset(pair_summary, !success_both_csv_modes)
if (nrow(failing) > 0) {
  cat("FAILING_SUPPORTED_PAIRS\n")
  print(
    failing[, c("id", "csv_false_status", "csv_true_status", "csv_false_message", "csv_true_message")],
    row.names = FALSE
  )
} else {
  cat("FAILING_SUPPORTED_PAIRS none\n")
}

cat("RESULTS_CSV", out_csv, "\n")
