#' itemEasyness
#'
#' @param data Datensatz als data.frame im wide-format. colnames müssen die Itemnamen sein.
#' @param min Kleinster möglicher Wert auf der Antwort-Skala
#' @param max Grösster möglicher Wert auf der Antwort-Skala
#'
#' @return Datensatz mit zwei Spalten: Itemname und Item-Einfachheit
#'
#' @importFrom tibble add_row
#' @export

itemEasyness <- function(data, min = 1, max = 4) {

  if (min < 1 || (max - min) < 2 ) {
    stop("Diese Funktion ist für deinen Datensatz nicht geeignet.")
  }

  output <- data.frame(items = character(),
                       easyness = numeric())

  for(item in names(data)) {
    summe <- sum(data[[item]] - 1)
    maximum <- nrow(data) * (max - min)
    easy <- round((summe / maximum) * 100, 2)
    output <- output |>
      tibble::add_row(items = item,
                      easyness = easy)
  }

  return(output)

}
