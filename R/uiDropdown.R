#' Einfaches Dropdown mit Tcl/Tk
#'
#' Zeigt ein modales Dropdown (ttkcombobox) mit vorgegebenen Werten an und speichert
#' die getroffene Auswahl unter einem angegebenen Variablennamen in der Globalenv.
#'
#' Diese Funktion erstellt ein kleines Tcl/Tk-Fenster mit einer schreibgeschützten
#' Combobox und einem OK-Button; nach Klick wird der ausgewählte Wert in
#' `.GlobalEnv` mit dem Namen aus `outputVariable` abgelegt und das Fenster geschlossen.
#'
#' @param values Ein Vektor mit Auswahlwerten.
#' @param title Fenstertitel für das Auswahl-Dialogfenster.
#' @param outputVariable Zeichenkette mit dem Namen der global zu setzenden Variable.
#' @param okButton Beschriftung des Bestätigungs-Buttons. Standard ist "OK".
#'
#' @details
#' Voraussetzung ist eine R-Installation mit Tcl/Tk-Unterstützung (`capabilities("tcltk")`).
#' Das Widget ist schreibgeschützt (`state = "readonly"`) und zeigt die Werte von `values` an.
#' Die Auswahl wird als Zeichenkette in `.GlobalEnv` gespeichert; das erleichtert einfache Workflows,
#' ist aber für Paket-APIs weniger empfehlenswert (siehe Value/Since).
#'
#' @returns
#' Invisibly `NULL`. Die eigentliche „Rückgabe“ erfolgt als Seiteneffekt, indem
#' `outputVariable` in `.GlobalEnv` gesetzt wird.
#'
#' @section Seiteneffekte:
#' Setzt `assign(outputVariable, auswahl, envir = .GlobalEnv)` und zerstört das Dialogfenster via `tkdestroy()`.
#'
#' @examples
#' \dontrun{
#' # Minimalbeispiel
#' uiDropdown(values = LETTERS[1:5],
#'            title = "Wähle einen Buchstaben",
#'            outputVariable = "buchstabe")
#' buchstabe  # ausgewählte Option als Zeichenkette
#'
#' # Mit Daten aus einer Spalte:
#' df <- data.frame(kat = c("A","B","A","C"))
#' uiDropdown(values = df$kat,
#'            title = "Kategorie wählen",
#'            outputVariable = "kat_auswahl")
#' subset_df <- subset(df, kat == kat_auswahl)
#' }
#'
#'
#' @importFrom tcltk tktoplevel tkwm.title tclVar ttkcombobox tkpack tclvalue tkbutton tkdestroy
#' @export
uiDropdown <- function(values, title, outputVariable, okButton = "OK") {
  tt <- tktoplevel()
  tkwm.title(tt, title)
  v <- tclVar(values[1])
  cb <- ttkcombobox(tt, textvariable = v, values = values, state = "readonly")
  tkpack(cb, padx = 10, pady = 10)

  tkbutton(tt, text = okButton, command = function() {
    auswahl <- tclvalue(v)
    assign(outputVariable, auswahl, envir = .GlobalEnv)
    tkdestroy(tt)
  }) |> tkpack(pady = 5)

  invisible(NULL)
}
