#' Replace all NA
#'
#' @param data Datensatz, in dem ALLE NA ersetzt werden sollen.
#' @param replace_with Wert, der statt NA eingesetzt werden soll
#'
#' @return Datensatz mit den ersetzten Werten
#' @export
#'
#' @examples
#' airquality |>
#'   repl_all_na(replace_with = 0) |>
#'   print()

repl_all_na <- function(data, replace_with = 0) {
  data[is.na(data)] <- replace_with
  return(data)
}
