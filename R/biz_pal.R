#' Funktion, die allfällige Abstufungen zwischen den gegebenen Farben auffüllt
#'
#' @param palette Farbpalette, die verwendet werden soll
#' @param reverse Boolean, der die Reihenfolge der Farbpalette umkehrt
#' @param ... Weitere Argumente, die an colorRampPalette() weitergegeben werden
#'
#' @return Funktion, die in weiteren Funktionen verwendet wird.
#' @importFrom grDevices colorRampPalette
#' @export

biz_pal <- function(palette = "BIZ", reverse = FALSE, ...) {
  pal <- biz_palette[[palette]]

  if (reverse) pal <- rev(pal)

  grDevices::colorRampPalette(pal, ...)
}
