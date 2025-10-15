#' Einfaches Dropdown mit Tcl/Tk
#'
#' Zeigt ein modales Dropdown (ttkcombobox) mit vorgegebenen Werten an und gibt
#' die getroffene Auswahl als Zeichenkette zurück; die Ausführung blockiert,
#' bis der Dialog geschlossen wird.
#'
#' @param values Ein Vektor mit Auswahlwerten; Duplikate werden mit `unique()` entfernt.
#' @param title Fenstertitel für den Dialog (Standard: "Auswahl").
#' @param okButton Beschriftung des Bestätigungs-Buttons (Standard: "OK").
#' @param width Ziel- und Mindestbreite des Fensters in Pixeln (Standard: 300).
#' @param height Ziel- und Mindesthöhe des Fensters in Pixeln (Standard: 150).
#'
#' @details
#' Die Funktion erzeugt ein kleines Dialogfenster mit einer schreibgeschützten
#' Combobox und einem OK-Button; nach Bestätigung wird das Fenster zerstört und
#' der selektierte Wert zurückgegeben.
#' Die Größe wird mit `tkwm.minsize()` begrenzt und per `wm geometry` gesetzt;
#' die Geometrie wird nach dem Initial-Layout via `after idle` angewandt.
#' Voraussetzung ist eine funktionsfähige Tcl/Tk-Umgebung (`capabilities("tcltk")`).
#'
#' @returns
#' Ein String mit dem ausgewählten Wert; bei Abbruch (Fensterkreuz) `NULL` (invisible).
#'
#' @examples
#' \dontrun{
#' wahl <- uiDropdown(LETTERS[1:5], title = "Wähle eine Person")
#' if (!is.null(wahl)) message("Gewählt: ", wahl)
#'
#' # Eigene Größe:
#' wahl2 <- uiDropdown(month.name, title = "Monat", width = 420, height = 220)
#' }
#'
#' @importFrom tcltk tktoplevel tkwm.title tclVar ttkcombobox tkpack tcl tkbutton tkbind tkwait.window tkwm.minsize tkdestroy
#' @export

uiDropdown <- function(values,
                       title = "Auswahl",
                       okButton = "OK",
                       width = 300,
                       height = 150) {

  tt <- tktoplevel()
  tkwm.title(tt, title)

  vals <- unique(values)
  sel_var  <- tclVar(vals[1])   # aktuelle Auswahl
  done_var <- tclVar("0")       # "0"=warte, "1"=OK, "cancel"=abgebrochen

  cb <- ttkcombobox(tt, textvariable = sel_var, values = vals, state = "readonly")
  tkpack(cb, padx = 12, pady = 12, fill = "x")

  ok_cmd <- function() {
    tclvalue(done_var) <- "1"
    tkdestroy(tt)
  }
  tkbutton(tt, text = okButton, command = ok_cmd) |> tkpack(pady = 8)

  # Mindest- und Zielgröße setzen
  tkwm.minsize(tt, as.integer(width), as.integer(height))
  tcl("after","idle", function() tkwm.geometry(tt, sprintf("%dx%d", width, height)))

  # Optional modal/fokus:
  # tkfocus(tt); tkgrab.set(tt)

  # Schließen über Fensterkreuz: als "cancel" markieren
  tkbind(tt, "<Destroy>", function() {
    if (as.character(tclvalue(done_var)) != "1") tclvalue(done_var) <- "cancel"
  })

  # Blockierend warten bis Fenster zerstört
  tkwait.window(tt)

  status <- as.character(tclvalue(done_var))
  if (identical(status, "1")) {
    return(as.character(tclvalue(sel_var)))
  } else {
    return(invisible(NULL))
  }
}

