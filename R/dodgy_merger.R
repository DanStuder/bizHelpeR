#' dodgy merger
#'
#' @param directory Ordner, für den die Dateien erstellt werden sollen
#'
#' @return Erstellt ein PDF aus dem Word-Dokument der Mappe und kombiniert und schneidet die anderen PDF-Dateien
# #' @importFrom pdftools pdf_text
# #' @importFrom qpdf pdf_combine pdf_length pdf_subset
#' @importFrom purrr pluck
#' @importFrom readr read_lines
#' @importFrom stringi stri_detect_regex
#' @importFrom stringr str_detect str_replace_all str_replace str_split
#' @importFrom tcltk tk_choose.dir
#' @export


dodgy_merger <- function(directory = tcltk::tk_choose.dir(), ist_override = FALSE) {

  # Dokumentation der PDF-XChange Tools CLI:
  # https://help.pdf-xchange.com/pdfxt10/

  # Helferfunktionen
  ## Warten, bis alle PDFs konvertiert sind
  wait_for_files_stable <- function(paths, timeout = 180, poll = 0.5, stable_n = 3) {
    t0 <- Sys.time()
    ok_counts <- setNames(rep(0L, length(paths)), paths)
    last_size <- setNames(rep(NA_real_, length(paths)), paths)

    while (any(ok_counts < stable_n)) {
      if (as.numeric(difftime(Sys.time(), t0, units = "secs")) > timeout) {
        stop("Timeout: Dateien wurden nicht stabil fertig geschrieben.")
      }

      exists <- file.exists(paths)
      size <- ifelse(exists, file.info(paths)$size, NA_real_)

      same <- exists & !is.na(last_size) & (size == last_size) & size > 0
      ok_counts[same] <- ok_counts[same] + 1L
      ok_counts[!same] <- 0L

      last_size <- size
      Sys.sleep(poll)
    }
    invisible(TRUE)
  }

  ## PDF in .txt konvertieren
  pdf2txt <- function(pdf_in) {
    pdfxt_exe <- "C:/Program Files/Tracker Software/PDF Tools/PDFXTools.exe"
    settings  <- "\\\\MBA.erz.be.ch\\DATA-MBA\\UserHomes\\mp5c\\Z_Systems\\RedirectedFolders\\Desktop\\Projekte\\Merger\\settings.pdtex"

    if (!file.exists(pdfxt_exe)) stop("PDFXTools.exe nicht gefunden: ", pdfxt_exe)
    if (!file.exists(settings))  stop("settings.pdtex nicht gefunden: ", settings)
    if (!file.exists(pdf_in))    stop("PDF nicht gefunden: ", pdf_in)

    args <- c(
      "/ImportTools", settings,
      "/RunTool:showui=no;showprog=no;showrep=no", "pdfToTXT", pdf_in
    )

    # Auf Windows: args einzeln quoten, damit Spaces/UNC sicher sind. [web:124]
    out <- system2(command = pdfxt_exe,
                   args = shQuote(args, type = "cmd"),
                   stdout = TRUE,
                   stderr = TRUE)

    invisible(out)
  }

  ## PDFs zusammenfügen
  # "C:/Program Files/Tracker Software/PDF Tools/PDFXTools.exe" /ImportTools "\\MBA.erz.be.ch\DATA-MBA\UserHomes\mp5c\Z_Systems\RedirectedFolders\Desktop\Projekte\Merger\settings.pdtex" /RunTool:showui=no;showprog=no;showrep=no;showprompt=no splitMergePDF "\\MBA.erz.be.ch\DATA-MBA\UserHomes\mp5c\Z_Systems\RedirectedFolders\Desktop\Projekte\Merger\A\Crystal Paglialonga\Crystal Paglialonga Ergebnisse.pdf" "\\MBA.erz.be.ch\DATA-MBA\UserHomes\mp5c\Z_Systems\RedirectedFolders\Desktop\Projekte\Merger\A\Crystal Paglialonga\Crystal Paglialonga Rohdaten.pdf" /Output:folder="\\MBA.erz.be.ch\DATA-MBA\UserHomes\mp5c\Z_Systems\RedirectedFolders\Desktop\Projekte\Merger\A\Crystal Paglialonga";filename="Crystal Paglialonga full.pdf";overwrite=yes;showfiles=no

  pdfMerge <- function(pdf_in,
                       pdf_out = NULL,
                       overwrite = TRUE) {
    pdfxt_exe <- "C:/Program Files/Tracker Software/PDF Tools/PDFXTools.exe"
    settings  <- "\\\\MBA.erz.be.ch\\DATA-MBA\\UserHomes\\mp5c\\Z_Systems\\RedirectedFolders\\Desktop\\Projekte\\Merger\\settings.pdtex"

    if (!file.exists(pdfxt_exe)) stop("PDFXTools.exe nicht gefunden: ", pdfxt_exe)
    if (!file.exists(settings))  stop("settings.pdtex nicht gefunden: ", settings)

    if (length(pdf_in) < 2) stop("Bitte mindestens 2 PDFs angeben.")
    if (!all(file.exists(pdf_in))) {
      missing <- pdf_in[!file.exists(pdf_in)]
      stop("Folgende PDFs wurden nicht gefunden:\n", paste(missing, collapse = "\n"))
    }

    # Default: überschreibe das erste PDF
    if (is.null(pdf_out)) pdf_out <- pdf_in[[1]]

    out_folder <- dirname(pdf_out)
    out_name   <- basename(pdf_out)  # output wird durch folder + filename definiert [web:191]
    dir.create(out_folder, recursive = TRUE, showWarnings = FALSE)

    output_opt <- paste0(
      "/Output:folder=", shQuote(out_folder, type = "cmd"),
      ";filename=", shQuote(out_name, type = "cmd"),
      ";overwrite=", if (isTRUE(overwrite)) "yes" else "no",
      ";showfiles=no"
    )

    args <- c(
      "/ImportTools", settings,
      "/RunTool:showui=no;showprog=no;showrep=no;showprompt=no", "splitMergePDF",
      pdf_in,
      output_opt
    )

    out <- system2(
      command = pdfxt_exe,
      args    = shQuote(args, type = "cmd"),
      stdout  = TRUE,
      stderr  = TRUE
    )

    invisible(list(
      output_pdf = file.path(out_folder, out_name),
      stdout_stderr = out
    ))
  }

  pdfExtract <- function(pdf_in,
                         pages_case = c("p1", "p2", "p1-2", "p2-end", "p3-end"),
                         pdf_out = NULL) {
    pdfxt_exe <- "C:/Program Files/Tracker Software/PDF Tools/PDFXTools.exe"
    tool_id = "extractPages"

    pages_case <- match.arg(pages_case)

    # Ordner, wo deine verschiedenen settings liegen:
    settings_dir <- "\\\\MBA.erz.be.ch\\DATA-MBA\\UserHomes\\mp5c\\Z_Systems\\RedirectedFolders\\Desktop\\Projekte\\Merger"

    # Neue Fälle hinzufügen
    # Leider kann man die zu extrahierenden Seiten nicht über die CLI direkt steuern
    # Stattdessen muss man das PDF Tools Programm öffnen, das Werkzeug "Seiten extrahieren" anwählen
    # eine Datei auswählen und die Seiten einstellen. Anschliessend bei folgendem Code die Endung
    # anpassen auf die enstprechende Einstellung und dann den Code im Terminal (cmd) ausführen.
    # "C:/Program Files/Tracker Software/PDF Tools/PDFXTools.exe" /ExportTools "\\MBA.erz.be.ch\DATA-MBA\UserHomes\mp5c\Z_Systems\RedirectedFolders\Desktop\Projekte\Merger\settings_p3-end.pdtex"

    settings_map <- c(
      "p1"    = "settings_p1.pdtex",
      "p2"    = "settings_p2.pdtex",
      "p1-2"  = "settings_p1-2.pdtex",
      "p2-end"= "settings_p2-end.pdtex",
      "p3-end"= "settings_p3-end.pdtex"
    )

    settings <- file.path(settings_dir, unname(settings_map[[pages_case]]))

    if (!file.exists(pdfxt_exe)) stop("PDFXTools.exe nicht gefunden: ", pdfxt_exe)
    if (!file.exists(settings))  stop("settings.pdtex nicht gefunden für case '", pages_case, "': ", settings)
    if (!file.exists(pdf_in))    stop("PDF nicht gefunden: ", pdf_in)

    if (is.null(pdf_out)) {
      pdf_out <- file.path(
        dirname(pdf_in),
        paste0(tools::file_path_sans_ext(basename(pdf_in)), " (", pages_case, ").pdf")
      )
    }

    out_folder <- dirname(pdf_out)
    out_name   <- basename(pdf_out)  # basename/dirname wie in base R dokumentiert [web:191]
    dir.create(out_folder, recursive = TRUE, showWarnings = FALSE)

    output_opt <- paste0(
      "/Output:folder=", shQuote(out_folder, type = "cmd"),
      ";filename=", shQuote(out_name, type = "cmd"),
      ";overwrite=yes;showfiles=no"
    )

    args <- c(
      "/ImportTools", settings,
      "/RunTool:showui=no;showprog=no;showrep=no;showprompt=no", tool_id,
      pdf_in,
      output_opt
    )

    out <- system2(
      command = pdfxt_exe,
      args    = shQuote(args, type = "cmd"),
      stdout  = TRUE,
      stderr  = TRUE
    )

    invisible(list(output_pdf = file.path(out_folder, out_name), stdout_stderr = out, settings_used = settings))
  }

  # Setze Directory (User kann im Browser anwählen)
  setwd(directory)

  modul <- basename(getwd())

  # Konstanten
  ## Liste der Dokumente, die später zusammengefügt werden sollen.
  FILENAMES <- c("Mappe.pdf",
                 "Ergebnisse.pdf",
                 "Rohdaten.pdf")

  FB_LENGTH <- 5 # Anzahl Seiten des physischen Fragebogens
  PROTOCOL <- "Protokoll.pdf"
  RMM <- "Rückmeldemappe.pdf"

  # Konvertiere word in pdf
  ## Alle mappen finden
  mappen_docm <- list.files(
    path = getwd(),
    pattern = "Mappe\\.docm$",
    recursive = TRUE,
    full.names = TRUE
  )

  # Output-Namen
  mappen_pdf <- sub("\\.docm$", ".pdf", mappen_docm)

  # Welche PDFs existieren schon?
  pdf_exists <- file.exists(mappen_pdf)  # gleicher Index wie mappen_docm

  # Nur die DOCMs behalten, die noch kein PDF haben
  mappen_docm_todo <- mappen_docm[!pdf_exists]
  mappen_pdf_todo  <- mappen_pdf[!pdf_exists]

  # Nur diese konvertieren
  if (length(mappen_docm_todo) > 0) {
    dodgy_word2pdf(inputs = mappen_docm_todo)

    wait_for_files_stable(mappen_pdf_todo, timeout = 300)
  }

  # Hole die Namen der Klient*innen
  clients <- list.files()

  # Iteriere über jede Person...
  for (client in clients) {

    # Testen, ob IST 5 enthalten und Konfidenzintervall aktiviert ist
    ## Inhalt der Ergebnisse lesen
    ergebnisse_pfad <- list.files(path = client,
                                  pattern = "Ergebnisse\\.pdf$",
                                  full.names = TRUE)

    #### Weg mit richtiger Funktion
    # ergebnisse_inhalt <- ergebnisse_pfad |>
    #   pdftools::pdf_text() |>
    #   stringr::str_split(pattern = "\n") |>
    #   unlist()
    #
    #### Weg mit eigener Funktion (ohne pdftools)
    ergebnisse_pfad |>
      pdf2txt()

    ergebnisse_inhalt <- ergebnisse_pfad |>
      stringr::str_replace(".pdf$", ".txt") |>
      readr::read_lines()

    file.remove(ergebnisse_pfad |>
                  stringr::str_replace(".pdf$", ".txt"))

    ## Prüfen ob IST 5 enthalten ist
    contains_ist5 <- ergebnisse_inhalt |>
      stringr::str_detect("Intelligenz-Struktur-Test 5") |>
      any()
    ## Prüfen ob Konfidenzintervalle angegeben werden
    has_ci <- ergebnisse_inhalt |>
      stringr::str_detect("Vertrauensintervall \\(Basis: Konsistenz, Wahrscheinlichkeit: (95%|90%)\\)") |>
      any()
    ## Wenn IST 5, aber keine KI (und kein Override), dann User warnen
    if (contains_ist5 & !has_ci & !ist_override) {warning(paste("Bei Klient/in", client, "wurde der IST 5 in den Ergebnissen erkannt, aber keine Vertrauensintervalle. Bitte gehe im HTS auf den IST der Person > Report > beim Profil im Dropdown 'Konfidenzintervall' anwählen.\nFalls diese Warnung fehlerhaft ist, bitte im Funktionsaufruf das Argument `ist_override` auf `TRUE` setzen."))}

    # Wenn Q-Level-Attest in den Dateien gefunden wird, füge es den Ergebnissen hinzu
    if(any(grepl("Q-LEVELAttest", list.files(path = client)))) {
      # Definiere Dateinamen/-pfade
      ergebnisse2 <- paste(paste(client, client, sep = "/"), "Ergebnisse2.pdf", sep = "_")
      qlevel <- paste(client, "Q-LEVELAttest.pdf", sep = "/")

      # Kombiniere Ergebnisse + Q-Level und speichere es unter anderem Namen
      # qpdf::pdf_combine(input = c(ergebnisse_pfad,
      #                             qlevel),
      #                   output = ergebnisse2)
      pdfMerge(pdf_in = c(ergebnisse_pfad,
                          qlevel),
               pdf_out = ergebnisse)
      # Entferne Ergebnisse & Q-Level und nenne Ergebnisse2 um
      ## Nicht nötig bei der eigenen Funktion `pdfMerge`
      # file.remove(ergebnisse_pfad, qlevel)
      # file.rename(from = ergebnisse2,
      #             to = ergebnisse_pfad)
    }


    # Wenn ein Fragebogen gefunden wird, dann füge ihn den Rohdaten hinzu
    if(any(grepl("Fragebogen", list.files(path = client)))) {
      fragebogen_in <- list.files(path = client,
                                  pattern = "Fragebogen\\.pdf$",
                                  full.names = TRUE)
      fragebogen_out <- fragebogen_in |>
        stringr::str_replace("Fragebogen", "Fragebogen_neu")


      rohdaten <- list.files(path = client,
                             pattern = "Rohdaten\\.pdf$",
                             full.names = TRUE)
      rohdaten_temp <- rohdaten |>
        stringr::str_replace("Rohdaten", "Rohdaten_temp")

      # qpdf::pdf_combine(input = c(rohdaten,
      #                             fragebogen_in),
      #                   output = rohdaten_temp)
      pdfMerge(pdf_in = c(rohdaten,
                          fragebogen_in),
               pdf_out = rohdaten)
      # Dateien umbenennen
      ## Nicht nötig bei der eigenen Funktion `pdfMerge`
      # file.rename(from = rohdaten_temp, to = rohdaten)
    }

    # Füge alles zusammen (Version für GEVER)
    all_in_names <- paste(paste(client, client, sep = "/"), FILENAMES, sep = " ")
    all_out_name <- paste(paste(client, client, sep = "/"),
                          "Modul", paste(modul, "pdf", sep = "."),
                          sep = " ")
    ## Bereite String vor, nach dem gesucht werden soll
    modul_name <- paste0("Modul ", modul, ".pdf")
    ## Suche nach dem String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(modul_name,
                  list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      # qpdf::pdf_combine(input = all_in_names,
      #                   output = all_out_name)
      pdfMerge(pdf_in = all_in_names,
               pdf_out = all_out_name)
    }

    # Separiere das Protokoll
    mappe <- list.files(path = client,
                        pattern = "Mappe\\.pdf$",
                        full.names = TRUE)
    protocol_out_name <- paste(paste(client, client, sep = "/"), PROTOCOL, sep = " ")
    rmm_out_name <- paste(paste(client, client, sep = "/"), RMM, sep = " ")

    ## Zuerst muss überprüft werden, ob das Protokoll 1 oder 2 Seiten hat
    ##  Dafür wird gesucht, ob die 2. Seite mit "Testresultate" beginnt.
    ##  Wenn Ja, hat das Protokoll nur 1 Seite, sonst 2.
    # startP2 <- pdftools::pdf_text(mappe)[2] |>
    #   startsWith("Testresultate")

    # Seite 2 extrahieren
    ## Zuerst Name für Output Datei erstellen
    mappe_p2 <- mappe |>
      stringr::str_replace(".pdf", "_p2.pdf")
    ## Extraktion Seite 2
    pdfExtract(mappe, "p2", mappe_p2)
    ## Seite 2 in .txt umwandeln
    pdf2txt(mappe_p2)
    mappe_p2_text <- mappe_p2 |>
      stringr::str_replace(".pdf$", ".txt")
    ## Seite einlesen
    startP2 <- mappe_p2_text |>
      readr::read_lines() |>
      purrr::pluck(2) |>
      stringr::str_detect("Testresultate")
    # if(startP2) {pages <- 1} else {pages <- 2} # Version für qpdf
    if(startP2) { # Version für eigenen Extraktor
      pages_protocol <- "p1"
      pages_rmm <- "p2-end"
    } else {
      pages_protocol <- "p1-2"
      pages_rmm <- "p3-end"
    }

    ## Suche nach dem String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(PROTOCOL, list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      # qpdf::pdf_subset(input = mappe,
      #                  pages = 1:pages,
      #                  output = protocol_out_name)
      pdfExtract(mappe, pages_protocol, protocol_out_name)
    }

    # Separiere die Mappe
    ## Suche nach dem String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(RMM, list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      # qpdf::pdf_subset(input = mappe,
      #                  pages = -(1:pages),
      #                  output = rmm_out_name)
      pdfExtract(mappe, pages_rmm, rmm_out_name)
    }

    # Entferne das Dokument "Mappe"
    file.remove(mappe, mappe_p2, mappe_p2_text)

  }

  print("Merge erfolgreich beendet.")

}
