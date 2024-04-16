#' phCorr
#'
#' Funktion zur Berechnung der par-whole-corrected Trennschärfe. Diese Funktion berechnet die Trennschärfe eines Items,
#' indem sie die Werte dieses Items vorher aus dem Score der Skala ausschliesst und reduziert somit den eigenen Bias.
#'
#' @param data Datensatz als data.frame im wide-format. colnames müssen die Itemnamen sein.
#'
#' @return Datensatz mit zwei Spalten: Itemname und phc-Trennschärfe
#'
#' @importFrom stats na.omit cor
#'
#' @export

phCorr <- function(data) {

  phc_selectivity <- data.frame(Item = character(),
                                Selectivity = numeric())

  for (item in colnames(data)) {

    data_omit <- na.omit(data)

    phc <- data_omit |>
      select(-as.character(item)) |>
      rowSums(na.rm = T) |>
      cor(data_omit[[item]]) |>
      round(2)

    phc_selectivity <- phc_selectivity |>
      tibble::add_row(Item = item,
                      Selectivity = phc)
  }

  return(phc_selectivity)

}
