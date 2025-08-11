#' Color scale constructor v2
#'
#' @param palette Farbpalette, die verwendet werden soll
#'
#' @return Farben aus dem CI, die verwendet werden sollen (ersetzt scale_color_manual())
#' @importFrom ggplot2 scale_color_manual
#' @export

scale_color_biz2 <- function(palette = NULL) {
  if (is.null(palette)) {palette <- "LB"}

  colors <- bizHelpeR::biz_colors(palette) |>
    as.vector()

  ggplot2::scale_color_manual(
    values = colors
  )
}

