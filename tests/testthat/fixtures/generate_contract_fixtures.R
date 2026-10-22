if (!requireNamespace("writexl", quietly = TRUE)) {
  stop("Install `writexl` to regenerate contract fixtures.")
}

fixture_directory <- if (basename(getwd()) == "fixtures") {
  getwd()
} else {
  file.path("tests", "testthat", "fixtures")
}

excel_serial <- function(date) {
  as.character(as.integer(as.Date(date) - as.Date("1899-12-30")))
}

write_raw_workbook <- function(name, sheets) {
  sheets <- lapply(sheets, function(sheet) {
    as.data.frame(sheet, stringsAsFactors = FALSE, check.names = FALSE)
  })
  writexl::write_xlsx(
    sheets,
    file.path(fixture_directory, name),
    col_names = FALSE
  )
}

summary_sheet <- rbind(
  c("Synthetic AOFM EOFY summary", "", "", "", "", ""),
  c("Portfolio", "Category", "Instrument", "Measure", "2025-06-30", "2026-06-30"),
  c("Debt", "AGS", "Treasury Bonds", "Face value", "900", "950"),
  c("Debt", "AGS", "Treasury Indexed Bonds", "Face value", "40", "45")
)
write_raw_workbook(
  "summary.xlsx",
  list(
    Notes = matrix("Synthetic summary notes", ncol = 1L),
    Portfolio = summary_sheet
  )
)

hierarchy_sheet <- function(title, first_date = "2025-12-31") {
  rbind(
    c(title, "", ""),
    c("Sector", "Commonwealth", "State"),
    c("Instrument", "Treasury Bond", "Treasury Bond"),
    c("Maturity", "2030-01-01", "2035-01-01"),
    c("Holder", "Resident", "Non-resident"),
    c(excel_serial(first_date), "100", "20"),
    c(excel_serial("2026-03-31"), "105", "22")
  )
}

write_raw_workbook(
  "ownership_public.xlsx",
  list(
    Borrowings = hierarchy_sheet("Public borrowing register"),
    Guarantees = hierarchy_sheet("Public guarantees")
  )
)
write_raw_workbook(
  "ownership_nonresident.xlsx",
  list(
    Notes = matrix("Synthetic ownership notes", ncol = 1L),
    Holdings = hierarchy_sheet("Non-resident holdings"),
    Share = hierarchy_sheet("Non-resident share"),
    Flow = hierarchy_sheet("Non-resident flow")
  )
)

secondary_sheet <- function(title, tib = FALSE) {
  prefix <- if (tib) {
    rbind(
      c(title, "", ""),
      c("Synthetic TIB note", "", ""),
      c("Percent of turnover", "", "")
    )
  } else {
    matrix(c(title, "", ""), nrow = 1L)
  }
  rbind(
    prefix,
    c("Period", "0-5 years", "5-10 years"),
    c(excel_serial("2025-12-31"), "12", "18"),
    c(excel_serial("2026-03-31"), "14", "20")
  )
}
write_raw_workbook(
  "tb_turnover.xlsx",
  list(
    Notes = matrix("Synthetic turnover notes", ncol = 1L),
    Tenor = secondary_sheet("TB turnover by tenor"),
    Investor = secondary_sheet("TB turnover by investor")
  )
)
write_raw_workbook(
  "tib_turnover.xlsx",
  list(
    Notes = matrix("Synthetic turnover notes", ncol = 1L),
    Tenor = secondary_sheet("TIB turnover by tenor", tib = TRUE),
    Investor = secondary_sheet("TIB turnover by investor", tib = TRUE)
  )
)

current_security_sheet <- function(title, security_prefix) {
  rbind(
    c(title, "", ""),
    c("Month", "AU0000SYN001", "AU0000SYN002"),
    c("", paste(security_prefix, "2030"), paste(security_prefix, "2035")),
    c("Jan-26", "100", "200"),
    c("Feb-26", "110", "210"),
    c("Mar-26", "120", "220")
  )
}

current_region_sheet <- function(title) {
  rbind(
    c(title, "", "", ""),
    c("", "", "", ""),
    c("", "Month", "Australia", "Asia"),
    c("", "Jan-26", "250", "50"),
    c("", "Feb-26", "260", "60"),
    c("", "Mar-26", "270", "70")
  )
}

current_counterparty_sheet <- function(title) {
  rbind(
    c(title, "", ""),
    c("", "", ""),
    c("Month", "Bank Customer", "Fund Manager"),
    c("Jan-26", "150", "150"),
    c("Feb-26", "160", "160"),
    c("Mar-26", "170", "170")
  )
}

write_raw_workbook(
  "tb_turnover_current.xlsx",
  list(
    Notes = matrix("Synthetic current turnover notes", ncol = 1L),
    Security = current_security_sheet("Current TB turnover by security", "TB"),
    Region = current_region_sheet("Current TB turnover by region"),
    Counterparty = current_counterparty_sheet(
      "Current TB turnover by counterparty"
    )
  )
)
write_raw_workbook(
  "tib_turnover_current.xlsx",
  list(
    Notes = matrix("Synthetic current turnover notes", ncol = 1L),
    Security = current_security_sheet(
      "Current TIB turnover by security",
      "TIB"
    ),
    Region = current_region_sheet("Current TIB turnover by region"),
    Counterparty = current_counterparty_sheet(
      "Current TIB turnover by counterparty"
    )
  )
)

premium_sheet <- function(title, shift = 0) {
  rbind(
    c(title, "", ""),
    c("Date", "TP5", "TP10"),
    c(excel_serial("2026-06-29"), as.character(0.8 + shift), as.character(1.2 + shift)),
    c(excel_serial("2026-06-30"), as.character(0.9 + shift), as.character(1.3 + shift))
  )
}
write_raw_workbook(
  "termpremium.xlsx",
  list(
    Notes = matrix("Synthetic term-premium notes", ncol = 1L),
    TermPremiumOLS = premium_sheet("OLS term premium"),
    TermPremiumBC = premium_sheet("Bias-corrected term premium", 0.1)
  )
)

transactional_sheet <- function(title, headers, values) {
  rbind(
    c(title, rep("", length(headers) - 1L)),
    headers,
    rep("", length(headers)),
    values[[1L]],
    values[[2L]]
  )
}

buyback_headers <- c(
  "Date held",
  "Tender Number/Buyback Method",
  "Maturity",
  "Coupon",
  "ISIN",
  "Amount Repurchased",
  "Amount of Offers",
  "Weighted Average Repurchase Yield",
  "Lowest Accepted Yield",
  "Highest Accepted Yield",
  "Lowest Offer",
  "Weighted Average Offer",
  "Secondary Market Mid Rate",
  "Number of Offers",
  "Number of Successful Offers",
  "Number of Offers Accepted in Full",
  "Settlement Proceeds",
  "Date Settled"
)

write_raw_workbook(
  "tb_buyback.xlsx",
  list(
    Transactions = transactional_sheet(
      "Synthetic Treasury Bond buyback transactions",
      buyback_headers,
      list(
        c(
          excel_serial("2026-05-01"), "RBA", excel_serial("2028-04-21"),
          "3.25", "AU0000SYN001", "100", "", "", "", "", "", "", "",
          "", "", "", "101.5", excel_serial("2026-05-05")
        ),
        c(
          excel_serial("2026-06-01"), "TBB1", excel_serial("2029-04-21"),
          "4.25", "AU0000SYN002", "120", "300", "4.10", "4.05", "4.15",
          "4.00", "4.12", "4.08", "8", "4", "2", "121.2",
          excel_serial("2026-06-05")
        )
      )
    ),
    Notes = matrix("Synthetic TB buyback notes", ncol = 1L)
  )
)

write_raw_workbook(
  "tib_buyback.xlsx",
  list(
    Transactions = transactional_sheet(
      "Synthetic Treasury Indexed Bond buyback transactions",
      buyback_headers,
      list(
        c(
          excel_serial("2026-05-01"), "Syndication",
          excel_serial("2030-08-20"), "2.50", "AU0000SYN003", "75", "150",
          "2.40", "", "", "", "", "", "", "", "", "76.1",
          excel_serial("2026-05-05")
        ),
        c(
          excel_serial("2026-06-01"), "TIBB1", excel_serial("2035-08-20"),
          "3.00", "AU0000SYN004", "80", "160", "2.55", "", "", "", "",
          "", "", "", "", "81.4", excel_serial("2026-06-05")
        )
      )
    ),
    Notes = matrix("Synthetic TIB buyback notes", ncol = 1L)
  )
)

write_raw_workbook(
  "retail.xlsx",
  list(
    Transactions = transactional_sheet(
      "Synthetic retail transactions",
      c("Settle Date", "Security Maturity Date", "Security", "Amount"),
      list(
        c(excel_serial("2026-06-01"), excel_serial("2030-06-21"), "TB 2030", "10"),
        c(excel_serial("2026-07-01"), excel_serial("2030-06-21"), "TB 2030", "12")
      )
    ),
    Notes = matrix("Synthetic retail notes", ncol = 1L)
  )
)
write_raw_workbook(
  "slf.xlsx",
  list(
    Notes = matrix("Synthetic SLF notes", ncol = 1L),
    Transactions = transactional_sheet(
      "Synthetic securities lending transactions",
      c("Start Date", "End Date", "Security Maturity Date", "Security", "Amount"),
      list(
        c(
          excel_serial("2026-06-01"), excel_serial("2026-06-08"),
          excel_serial("2035-06-21"), "TB 2035", "25"
        ),
        c(
          excel_serial("2026-07-01"), excel_serial("2026-07-08"),
          excel_serial("2035-06-21"), "TB 2035", "30"
        )
      )
    )
  )
)

write_raw_workbook(
  "tn_position_dealt.xlsx",
  c(
    list(Notes = matrix("Synthetic TN position notes", ncol = 1L)),
    stats::setNames(
      lapply(
        c("FaceValue", "MarketValue", "Delta", "Duration"),
        function(name) hierarchy_sheet(paste("TN", name))
      ),
      c("FaceValue", "MarketValue", "Delta", "Duration")
    )
  )
)
