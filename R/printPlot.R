#' printPlot
#'
#' Convenience-function, um die Plots aufzurufen
#' Per Default ist der Datensatz "norm_data" ausgewählt
#' Zudem die Spalte "Histo", man könnte aber auch einen anderen
#' Datensatz und eine andere Spalte wählen
#' Man kann bei row_id entweder eine Zahl eingeben (Zeile)
#' oder das Konstrukt, das man ansehen will
#'
#' @param data Datensatz, aus dem der Plot angezeigt werden soll
#' @param plot_col Spalte aus dem Datensatz, in dem die Plots gespeichert sind. Der Plot muss in eine Funktion gewrapped sein, damit das tibble mit `View(tbl)` geöffnet werden kann.
#' @param row_id Zeilenindex oder Name der Skala (muss in der Spalte "Skala" sein)
#' @return Plot (bzw. Funktion), der in der Zelle gespeichert war
#'
#' @export
#'
#' @examples
#' library(ggplot2)
#'
#' norm_data <- data.frame(
#'   Skala = c("A", "B"),
#'   Q1 = c(4, 6),
#'   Q2 = c(5, 7),
#'   Q3 = c(6, 8)
#' ) |>
#'   dplyr::mutate(
#'     RW = purrr::map(Skala, ~ if (.x == "A") rnorm(30, mean = 5) else rnorm(30, mean = 7)),
#'     Histo = purrr::pmap(
#'       .l = list(Skala = Skala, RW = RW, Q1 = Q1, Q2 = Q2, Q3 = Q3),
#'       .f = function(Skala, RW, Q1, Q2, Q3) {
#'
#'       # WICHTIG: innerhalb der Funktion .f den ggplot nochmals in eine function`()` wrappen!
#'         function() {
#'         ggplot(data.frame(RW = RW), aes(x = RW)) +
#'           geom_histogram(bins = 10) +
#'           geom_vline(xintercept = Q1, color = "red", linetype = "dashed") +
#'           geom_vline(xintercept = Q2, color = "blue", linetype = "dotted") +
#'           geom_vline(xintercept = Q3, color = "red", linetype = "dashed") +
#'           ggtitle(Skala)
#'         }
#'       }
#'     )
#'   )
#'
#' # Beispiel: Plot anzeigen mit Zeilenindex
#' printPlot(1, "Histo", norm_data)
#'
#' # Beispiel: Plot anzeigen mit Skalennamen
#' printPlot("B", "Histo", norm_data)

printPlot <- function(row_id, plot_col, data) {
  # Check if row_id is numeric (row index) or character (match Skala)
  if (is.numeric(row_id)) {
    row_idx <- row_id
  } else if (is.character(row_id)) {
    # Match in Skala column
    row_idx <- which(data$Skala == row_id)
    if (length(row_idx) == 0) {
      stop(paste0("No row found matching Skala = '", row_id, "'"))
    }
  } else {
    stop("row_id must be either numeric or character")
  }

  # Extract the plot function
  plot_fun <- data[[plot_col]][[row_idx]]

  if (!is.function(plot_fun)) {
    stop(paste0("The element in column '", plot_col, "' at row ", row_idx, " is not a function."))
  }

  # Call and print the plot
  print(plot_fun())
}
