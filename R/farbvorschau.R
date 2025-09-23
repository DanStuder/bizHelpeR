#' Farbenvorschau plotten
#'
#' Diese Funktion zeigt eine Farbpalette als Kacheln an und erlaubt als Input
#' Vektoren, Listen oder Data Frames mit HEX- oder RGB-Farben (auch mit Alphakanal).
#' Farben werden validiert und nicht passende Werte werden ignoriert.
#'
#' @param colors Vektor, Liste oder Data Frame mit Farbwerten.
#'  - Falls Data Frame, kann mit \code{rgb_cols} die RGB-Spalten angegeben werden.
#'  - Unterstützt HEX-Codes (z.B. \code{"#RRGGBB"} oder \code{"#RRGGBBAA"}).
#'  - RGB als drei Spalten mit Werten 0 bis 255 möglich.
#' @param rgb_cols Optional. Charaktervektor mit Namen der RGB-Spalten (z.B. \code{c("r","g","b")}),
#'  wenn \code{colors} ein Data Frame mit RGB-Werten ist.
#'
#' @return Ein ggplot2-Plot mit der Farbpalette als Kacheln.
#'
#' @import ggplot2
#'
#' @examples
#' farbvorschau(c("#00000040", "#a9bcc5FF", "#7d9aa9CC"))
#' df_rgb <- data.frame(r = c(169, 125, 213), g = c(188, 154, 239), b = c(197, 169, 249))
#' farbvorschau(df_rgb, rgb_cols = c("r", "g", "b"))
#'
#' @export
farbvorschau <- function(colors, rgb_cols = NULL) {
  is_hex_alpha <- function(x) grepl("^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{4})$", x)

  if (is.data.frame(colors) && !is.null(rgb_cols)) {
    rgb_vals <- colors[, rgb_cols]
    rgb_to_hex <- function(r, g, b) {
      sprintf("#%02X%02X%02X", r, g, b)
    }
    cols_hex <- apply(rgb_vals, 1, function(z) rgb_to_hex(z[1], z[2], z[3]))
  } else if (is.data.frame(colors)) {
    cols_hex <- as.character(colors[[1]])
  } else if (is.list(colors)) {
    cols_hex <- unlist(colors)
  } else {
    cols_hex <- colors
  }

  valid_colors <- vapply(cols_hex, is_hex_alpha, logical(1))
  if (!all(valid_colors)) {
    warning("Nicht alle Farben sind g\u00fcltige HEX-Codes (inkl. Alpha) und werden ignoriert:")
    print(cols_hex[!valid_colors])
    cols_hex <- cols_hex[valid_colors]
  }

  if (length(cols_hex) == 0) {
    stop("Keine g\u00fcltigen Farben zum Plotten gefunden.")
  }

  df <- data.frame(color = cols_hex, x = seq_along(cols_hex))

  ggplot(df, aes(x = factor(x), y = 1, fill = color)) +
    geom_tile(color = NA) +           # Kein Rahmen
    scale_fill_identity() +
    theme_void() +
    theme(legend.position = "none") +
    labs(title = "Farbenvorschau")
}
