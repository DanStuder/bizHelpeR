#' Color scale constructor
#'
#' @param palette Farbpalette, die verwendet werden soll
#' @param discrete Boolean, indiziert ob color aesthetic diskret ist oder nicht
#' @param reverse Boolean, der die Reihenfolge der Farbpalette umkehrt
#' @param ... Weitere Argumente, die an discrete_scale()
#'            oder scale_color_gradientn() weitergeschickt werden
#'
#' @return Farben aus dem CI, die verwendet werden sollen (ersetzt scale_color_manual())
#' @importFrom ggplot2 scale_color_gradientn discrete_scale
#' @export

scale_color_biz <- function(palette = "BIZ", discrete = TRUE, reverse = FALSE, ...) {
  pal <- biz_pal(palette = palette, reverse = reverse)

  if (discrete) {
    ggplot2::discrete_scale("colour", paste0("biz_", palette), palette = pal, ...)
  } else {
    ggplot2::scale_color_gradientn(colours = pal(256), ...)
  }
}
