#' date_formatter
#'
#' @param data Datensatz, in dem die Datums-Spalten formatiert werden sollen.
#' @param ... Spalten mit Daten, welche formatiert werden sollen. Kann im tidy-format aufgelistet werden.
#'
#' @return Datensatz mit bereinigten Datums-Spalten im ISO-Format
#' @importFrom dplyr across case_when mutate
#'
#' @export
#'
#' @examples
#' df <- data.frame(
#' date1 = c("01.01.2020", "02.02.2021", "44212", "3", NA),
#' date2 = c("05.06.2019", "06.07.2022", "44250", "4", NA),
#' other_col = c("abc", "def", "ghi", "jkl", "mno")
#' )
#'
#' df_formatted <- date_formatter(df, date1, date2)
#' print(df_formatted)

date_formatter <- function(data, ...) {
  data |>
    dplyr::mutate(dplyr::across(
      c(...),
      ~ dplyr::case_when(
        nchar(as.character(.)) == 10 ~ as.Date(., format = "%d.%m.%Y"),
        nchar(as.character(.)) == 1 ~ NA,
        .default = as.Date(as.numeric(.), origin = "1899-12-30")
      ),
      .names = "{.col}"
    )) |>
    suppressWarnings()
}
