#' Word zu PDF mit PDF-XChange Tools
#'
#' Konvertiert .docx/.docm zu PDF. Benötigt PDF-XChange Tools installiert.
#'
#' @param input Pfad zu einer oder mehreren zu konvertierenden Dateien
#' @seealso [PDF-Tools V6 CLI-Dokumentation](https://help.pdf-xchange.com/pdfxt6/index.html?command-line-options_t.html)
#' @export
word2pdf_dodgy <- function(inputs) {

  input_path <- inputs |>
    shQuote(type = "cmd") |>
    paste(collapse = " ")

  # Package‑interne .pdftex Config laden
  tools_config <- normalizePath(system.file("extdata", "convertSetting.pdftex", package = "bizHelpeR"), winslash = "\\", mustWork = TRUE)
  tools_config_q <- shQuote(tools_config, type = "cmd")

  prefix <- r'("C:\Program Files\Tracker Software\PDF Tools\PDFXTools.exe")'
  middle <- r'("C:\Program Files\Tracker Software\PDF Tools\PDFXTools.exe" /RunTool:showui=no;showprog=no;showrep=no filesToPDF)'

  string <- paste(
    prefix,
    "/ImportSettings:showui=no",
    tools_config_q, " ",
    middle,
    input_path
  )

  # 1) String in Zwischenablage
  clipr::write_clip(string)

  Sys.sleep(0.4)

  # 2) Startmenü öffnen (Windows-Taste)
  KeyboardSimulator::keybd.press("win")
  Sys.sleep(0.4)

  # 3) "cmd" tippen und Enter
  KeyboardSimulator::keybd.type_string("cmd")
  Sys.sleep(0.2)
  KeyboardSimulator::keybd.press("Enter")

  # 4) Warten bis Terminal im Fokus ist, dann Ctrl+Shift+V
  Sys.sleep(2)
  KeyboardSimulator::keybd.press("Ctrl+Shift+v")

  Sys.sleep(1)
  KeyboardSimulator::keybd.press("Enter")

  Sys.sleep(1)                              # warten bis Paste durch ist
  KeyboardSimulator::keybd.press("Alt+F4")    # Fenster schliessen
}
