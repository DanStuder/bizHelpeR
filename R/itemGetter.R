#' itemGetter
#'
#' @param data Datensatz als data.frame im wide-format. colnames müssen die Itemnamen sein.
#' @param scale Name der Skala, die aus dem Datensatz geholt werden soll.
#'
#' @return Vektor mit den Itemnamen der Skala
#'
#' @importFrom dplyr filter select
#'
#' @export

itemGetter <- function(data, scale) {

  names <- data |>
    dplyr::filter(`Konstrukt Version 11` %in% scale) |>
    dplyr::select(Label) |>
    unlist() |>
    unname()

  return(names)

}
