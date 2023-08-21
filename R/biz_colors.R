#' biz_colors
#'
#' @param palette Farbpalette, die verwendet werden soll
#' @param ... Namen der Farben, die aus der Farbpalette ausgewählt werden sollen
#'
#' @return Vektor mit ausgewählten Farben
#' @export

biz_colors <- function(palette = c("BIZ", "BSB", "LB"), ...) {
  cols <- c(...)

  if (is.null(cols))
    return (paletti[[palette]])

  paletti[[palette]][cols]
}
