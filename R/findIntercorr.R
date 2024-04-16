#' findIntercorr
#'
#' Findet aus einem data.frame mit 2 Spalten alle einzigartigen Kombinationen,
#' wobei c("a", "b") als identisch zu c("b", "a") gewertet wird.
#'
#' @param data data.frame mit 2 Spalten von Itemkombinationen.
#'
#' @return data.frame mit 2 Spalten von Itemkombinationen
#'
#' @importFrom dplyr distinct filter mutate
#' @importFrom tidyr separate
#'
#' @export

findIntercorr <- function(data) {

  if(!all(sapply(data, is.numeric))) {
    stop("Nicht alle Variablen sind numerisch. Bitte kontrolliere den Datensatz.")
  }

  combinations <- base::which(data > .5, arr.ind = T) |>
    as.data.frame() |>
    dplyr::filter(row != col) |> arrange(row, col) |>
    mutate(combis = ifelse(row < col, paste(row, col, sep = ","),
                           paste(col, row, sep = ","))) |>
    dplyr::distinct(combis) |>
    tidyr::separate(combis, into = c("row", "col"), sep = ",") |>
    dplyr::mutate(row = as.numeric(row),
                  col = as.numeric(col))

  for (col in 1:2) {
    for (row in 1:nrow(combinations)) {
      combinations[row, col] <- names(data)[as.numeric(combinations[row, col])]
    }
  }

  final <- combinations |>
    dplyr::filter(row != "score",
                  col != "score")

  return(final)

}
