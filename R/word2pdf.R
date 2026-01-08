#' Word zu PDF mit PDF-XChange Tools
#'
#' Konvertiert .docx/.docm zu PDF. Benötigt PDF-XChange Tools installiert.
#'
#' @param input Pfad zur .docx/.docm Datei
#' @return Pfad zur erstellten PDF
#' @seealso [PDF-Tools V6 CLI-Dokumentation](https://help.pdf-xchange.com/pdfxt6/index.html?command-line-options_t.html)
#' @export
word2pdf <- function(input) {

  pdfxtools_path <- "C:\\Program Files\\Tracker Software\\PDF Tools\\PDFXTools.exe"

  if (!file.exists(pdfxtools_path)) {
    stop("PDFXTools.exe nicht gefunden unter: ", pdfxtools_path)
  }

  # Checks: Einzelne Datei, DOCX/DOCM
  if (length(input) != 1) {
    stop("Nur eine einzelne Datei als Input. Anzahl: ", length(input))
  }

  if (!file.exists(input)) {
    stop("Input-Datei nicht gefunden: ", input)
  }

  if (dir.exists(input)) {
    stop("Input ist ein Ordner, keine Datei: ", input)
  }

  ext <- tolower(tools::file_ext(input))
  if (!ext %in% c("docx", "docm")) {
    stop("Nur .docx oder .docm unterstützt. Gefunden: .", ext)
  }

  input <- normalizePath(input, winslash = "\\", mustWork = TRUE)

  # Package‑interne .pdftex Config laden
  tools_config <- system.file("extdata", "convertSetting.pdftex", package = "bizHelpeR")

  if (tools_config == "") {
    stop("Interne Tools-Konfiguration nicht gefunden!")
  }

  # 1. Settings importieren (headless)
  import_args <- c("/ImportTools:showui=no", shQuote(tools_config))
  import_res <- suppressWarnings(
    system2(pdfxtools_path, args = import_args, stdout = TRUE, stderr = TRUE)
  )

  # 2. Konvertierung ausführen
  cmd_args <- c("/RunTool:showui=no;showprog=no;showrep=no",
                "pdft.tool.filesToPDF",
                shQuote(input))

  res <- system2(pdfxtools_path, args = cmd_args, stdout = TRUE, stderr = TRUE)

  # Output‑PDF prüfen
  output_pdf <- gsub("\\.docx?$", ".pdf", input, ignore.case = TRUE)

  if (!file.exists(output_pdf)) {
    stop("Konvertierung fehlgeschlagen!\nOutput: ", paste(res, collapse = "\n"))
  }
}
