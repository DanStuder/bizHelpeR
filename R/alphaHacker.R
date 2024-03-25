#' alphaHacker
#'
#' @param data Datensatz, der analysiert werden soll. Alle enthaltenen Items gehen in die Analyse mit ein.
#' @param min_items Definiert die Mindestanzahl Items, welche für die Berechnung von alpha verwendet werden soll.
#' @param n_out Definiert, wie viele Kombinationen ausgegeben werden sollen.
#'
#' @return Dataframe mit dem höchsten alpha-Wert. Beinhaltet den verwendeten Datensatz + das alpha.
#' @importFrom dplyr all_of arrange desc mutate select
#' @importFrom purrr map
#' @importFrom psych alpha
#' @importFrom tibble tibble
#' @importFrom utils combn
#' @importFrom varhandle check.numeric
#'
#' @export
#'
#' @examples
#' data <- psych::bfi[1:10]
#' alphaHacker(data, min_items = 5, n_out = 3)


alphaHacker  <- function(data, min_items = NULL, n_out = 1) {

  # Fehler abfangen
  ## Testet, ob alle Spalten numerisch sind und ändert sie zu numerisch, wenn nicht.
  change <- sapply(data, function(x) all(varhandle::check.numeric(x, na.rm = TRUE)))
  data[change] <- lapply(data[change], as.numeric)
  ## Gibt Warnung über Änderung der Spalten aus
  if (! all(change)) {
    changed_names <- change[change == TRUE] |> names()
    warning(cat("Nicht-numerische Spalten gefunden im Datensatz. Folgende Spalten wurden für die Berechnung reformatiert: ",
                changed_names, sep = ", "))
  }

  # Extrahiere Spaltennamen
  col_names <- sort(colnames(data))

  # Setze min_items als 1, wenn nicht spezifiziert
  if (is.null(min_items)) {
    min_items <- 2
  } else if(min_items > length(col_names) -1) {
    stop("Definierte minimale Anzahl Items ist gleich gross oder grösser als die Anzahl Spalten im Datensatz -1.")
  }

  if (!is.numeric(min_items)) {stop("min_items muss eine ganze Zahl sein!")}
  if (!is.numeric(n_out)) {stop("n_out muss eine ganze Zahl sein!")}



  # Generiere Kombinationen
  combinations <- lapply(seq(min_items, length(col_names)), function(k) {
    utils::combn(col_names, k, simplify = FALSE)
  })

  # Kombinationen als Vektor
  combinations <- unlist(combinations, recursive = FALSE)



  # Loopt über jede Kombination und erstellt ein dataframe
  #   Dann erstellt es ein dataframe, welches die kleinen dataframes als Zeilenwerte hat
  #   Anschliessend wird die Spalte umbenannt
  #   Zuletzt wird über jede Kombination geloopt und das alpha berechnet
  #     und in einer neuen Spalte gespeichert

  datasets <- purrr::map(combinations, ~data |> dplyr::select(dplyr::all_of(.x))) |>
    tibble::tibble() |>
    `colnames<-`("items") |>
    dplyr::mutate(alpha = purrr::map(items, ~try(psych::alpha(.x, check.keys = T),
                                                 silent = T)$total$raw_alpha) |>
                    unlist()) |>
    suppressWarnings()

  # Aus allen Zeilen wird diejenige ausgewählt, welche das höchste Alpha aufweist
  best_combis <- datasets |>
    dplyr::arrange(dplyr::desc(alpha)) |>
    utils::head(n_out)

  return(best_combis)

}
