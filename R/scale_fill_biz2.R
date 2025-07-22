#' Fill scale constructor v2
#'
#' @param palette Farbpalette, die verwendet werden soll
#'
#' @return Farben aus dem CI, die verwendet werden sollen (ersetzt scale_fill_manual())
#' @importFrom ggplot2 scale_fill_manual
#' @export

scale_fill_biz2 <- function(palette = NULL) {

  if (is.null(palette)) {palette <- "LB"}

  colors <- bizHelpeR::biz_colors("LB") |>
    as.vector()

  ggplot2::scale_fill_manual(
    values = colors
  )
}
