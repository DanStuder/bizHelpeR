#' merger
#'
#' @param directory Ordner, für den die Dateien erstellt werden sollen
#'
#' @return Erstellt ein PDF aus dem Word-Dokument der Mappe und kombiniert und schneidet die anderen PDF-Dateien
#' @importFrom doconv docx2pdf
#' @importFrom pdftools pdf_text
#' @importFrom qpdf pdf_combine pdf_length pdf_subset
#' @importFrom stringi stri_detect_regex
#' @importFrom stringr str_replace_all
#' @importFrom tcltk tk_choose.dir
#' @export


merger <- function(directory = tcltk::tk_choose.dir()) {

  # Setze Directory (User kann im Browser anwählen)
  setwd(directory)

  modul <- basename(getwd())

  # Konstanten
  ## Liste der Dokumente, die später zusammengefügt werden sollen.
  FILENAMES <- c("Mappe.pdf",
                 "Ergebnisse.pdf",
                 "Rohdaten.pdf")
  ## Anzahl Seiten des physischen Fragebogens
  FB_LENGTH <- 5
  ## Name des Protokolls
  PROTOCOL <- "Protokoll.pdf"
  RMM <- "Rückmeldemappe.pdf"

  # Ersetze Leerschlag durch Underscore für Kompatibilität
  for(client in list.files()) {
    ## Zuerst bei den Ordnern pro Klient*in
    new_folder_name <- gsub(" ", "_", client)
    file.rename(from = client,
                to = new_folder_name)
  }

  # Hole die Namen der Klient*innen
  clients <- list.files()

  # Iteriere über jede Person...
  for (client in clients) {

    ## Wähle alle Dokumente aus
    files <- list.files(path = client)
    ## Iteriere über alle Dokumente
    for(file in files) {
      ## Ersetze Leerschlag durch Underscore für Kompatibilität
      ### Definiere alten und neuen Namen und ersetze
      old_name <- paste(client, file, sep = "/")
      new_name <- paste(client, gsub(" ", "_", file), sep = "/")
      file.rename(from = old_name, to = new_name)
    }

    # Finde docs und drucke zu PDF (falls es nicht bereits existiert)
    if(!any(grep(FILENAMES[1], list.files(client)))) {
      # Bennenne Dokumente
      doc_in_name <- paste(client, list.files(path = client, pattern = ".docx"), sep = "/")
      doc_out_name <- paste(client,
                            paste(client,
                                  FILENAMES[1],
                                  sep = "_"),
                            sep = "/")
      # Überprüfe, ob es im Klientennamen Umlaute hat
      ## Wenn es Umlaute hat, funktioniert die Konversion von .docx zu .pdf nicht
      ##  deshalb müssen die Dokumenten-Namen abgeändert und später wieder zurückgeändert werden
      umlaute <- stringi::stri_detect_regex(client, "[^ -~]")

      if(umlaute) {
        umlaut_name <- client                                     # speichere alten Namen
        ascii_name <- iconv(client, to = "ASCII//TRANSLIT")       # speichere neuen Namen
        file.rename(from = umlaut_name,                           # Ordner umbenennen
                    to = ascii_name)

        ## Nur das Word-file muss umbenannt werden, beim PDF ist es kein Problem
        umlaute_doc_in_name <- paste(ascii_name,
                                     list.files(ascii_name,
                                                ".docx"),
                                     sep = "/")                   # speichere alten Namen
        doc_in_name <- iconv(doc_in_name, to = "ASCII//TRANSLIT") # speichere neuen Namen
        doc_out_name <- paste(ascii_name,                         # Name für das Output-File
                              paste(client,
                                    FILENAMES[1],
                                    sep = "_"),
                              sep = "/")
        file.rename(from = umlaute_doc_in_name,                   # Dokument umbenennen
                    to = doc_in_name)
      }

      # Falls das File existiert (und richtig benannt wurde), dann erstelle es als PDF
      if(file.exists(doc_in_name)) {
        # Konversion
        doconv::docx2pdf(input = doc_in_name,
                         output = doc_out_name)
        if(umlaute) {
          # Name zurück zu Umlauten
          file.rename(from = doc_in_name,                ## Word-file
                      to = umlaute_doc_in_name)
          file.rename(from = ascii_name,                 ## Klienten-Ordner
                      to = umlaut_name)
        }

      } else {warning(paste(doc_in_name, "wurde nicht gefunden. Stelle sicher, dass das Dokument richtig benannt wurde."))}
    } else if(length(grep(FILENAMES[1], list.files(client))) > 1) {
      # Sollte eigentlich nicht möglich sein, aber falls mehr als 2 Doks mit
      # "Ergebnisse.pdf" gefunden werden, dann gib eine Warnung aus.
      warning(paste("Mehr als 1 bestehendes Dokument mit dem Namen",
                    client,
                    FILENAMES[2],
                    "gefunden."))
    }


    # Wenn Q-Level-Attest in den Dateien gefunden wird, füge es den Ergebnissen hinzu
    if(any(grepl("Q-LEVELAttest", files))) {
      # Definiere Dateinamen/-pfade
      ergebnisse <- paste(paste(client, client, sep = "/"), "Ergebnisse.pdf", sep = "_")
      ergebnisse2 <- paste(paste(client, client, sep = "/"), "Ergebnisse2.pdf", sep = "_")
      qlevel <- paste(client, "Q-LEVELAttest.pdf", sep = "/")

      # Kombiniere Ergebnisse + Q-Level und speichere es unter anderem Namen
      qpdf::pdf_combine(input = c(ergebnisse,
                                  qlevel),
                        output = ergebnisse2)
      # Entferne Ergebnisse & Q-Level und nenne Ergebnisse2 um
      file.remove(ergebnisse, qlevel)
      file.rename(from = ergebnisse2,
                  to = ergebnisse)
    }


    # Wenn ein Fragebogen gefunden wird, dann füge ihn den Rohdaten hinzu
    if(any(grepl("Fragebogen", files))) {
      fragebogen_in <- paste(paste(client,
                                   client,
                                   sep = "/"),
                             "Fragebogen.pdf",
                             sep = "_")
      fragebogen_out <- paste(paste(client,
                                    client,
                                    sep = "/"),
                              "Fragebogen_neu.pdf")

      # Der physische Fragebogen hat genau 5 Seiten. Wenn das PDF 6 Seiten hat,
      #   dann liegt das daran, dass im Scan noch eine leere Seite drin ist,
      #   die abgeschnitten werden kann.
      #   Wenn das PDF noch länger ist als 6 Seiten, dann handelt es sich um die digitale Version,
      #   bei der ebenfalls einige Seiten abgeschnitten werden müssen.
      fb_actual_length <- qpdf::pdf_length(input = fragebogen_in)

      if(fb_actual_length == 2*ceiling(FB_LENGTH/2)) {
        qpdf::pdf_subset(input = fragebogen_in,
                         pages = 1:FB_LENGTH,
                         output = fragebogen_out)
        file.rename(from = fragebogen_out,
                    to = fragebogen_in)
      } else if (fb_actual_length > 2*ceiling(FB_LENGTH/2)) {
        text <- fragebogen_in |>
          pdftools::pdf_text() |>
          stringr::str_replace_all("\\s", "") # Extrahiert den Text pro Seite

        qpdf::pdf_subset(input = fragebogen_in,
                         pages = nchar(text) != 0, # wähle alle Seiten, auf denen etwas steht
                         output = fragebogen_out)
        file.rename(from = fragebogen_out,
                    to = fragebogen_in)
      }

      raw_clean <- paste(paste(client, client, sep = "/"), FILENAMES[3], sep = "_")
      raw_temp <- paste(paste(client, client, sep = "/"),"temp", FILENAMES[3], sep = "_")

      qpdf::pdf_combine(input = c(raw_clean,
                                  fragebogen_in),
                        output = raw_temp)
      file.rename(from = raw_temp, to = raw_clean)
    }

    # Füge alles zusammen (Version für GEVER)
    all_in_names <- paste(paste(client, client, sep = "/"), FILENAMES, sep = "_")
    all_out_name <- paste(paste(client, client, sep = "/"),
                          "Modul", paste(modul, "pdf", sep = "."),
                          sep = "_")
    ## Bereite String vor, nach dem gesucht werden soll
    modul_name <- paste0("Modul_", modul, ".pdf")
    ## Suche nach dem String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(modul_name,
                  list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      qpdf::pdf_combine(input = all_in_names,
                        output = all_out_name)
    }

    # Separiere das Protokoll
    ### protocol_in_name <- paste(paste(client, client, sep = "/"), FILENAMES[1], sep = "_")
    mappe <- paste(paste(client, client, sep = "/"), FILENAMES[1], sep = "_")
    protocol_out_name <- paste(paste(client, client, sep = "/"), PROTOCOL, sep = "_")
    ### rmm_in_name <- paste(paste(client, client, sep = "/"), FILENAMES[1], sep = "_")
    rmm_out_name <- paste(paste(client, client, sep = "/"), "Rückmeldemappe.pdf", sep = "_")

    ## Zuerst muss überprüft werden, ob das Protokoll 1 oder 2 Seiten hat
    ##  Dafür wird gesucht, ob die 2. Seite mit "Testresultate" beginnt.
    ##  Wenn Ja, hat das Protokoll nur 1 Seite, sonst 2.
    startP2 <- pdftools::pdf_text(mappe)[2] |>
      startsWith("Testresultate")
    if(startP2) {pages <- 1} else {pages <- 2}


    ## Suche nach dem String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(PROTOCOL, list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      qpdf::pdf_subset(input = mappe,
                       pages = 1:pages,
                       output = protocol_out_name)
    }

    # Separiere die Mappe
    ## Suche nach den String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(RMM, list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      qpdf::pdf_subset(input = mappe,
                       pages = -(1:pages),
                       output = rmm_out_name)
    }

    # Entferne das Dokument "Mappe"
    file.remove(paste(client,
                      paste(client,
                            FILENAMES[1],
                            sep = "_"),
                      sep = "/"))

    # Entferne underscores für Lesbarkeit
    ## Iteriere über alle PDFs
    for(file in list.files(path = client)) {
      # Definiere alten und neuen Namen und ersetze
      old_name <- paste(client, file, sep = "/")
      new_name <- paste(client, gsub("_", " ", file), sep = "/")
      file.rename(from = old_name, to = new_name)

    }

  }

  print("Merge erfolgreich beendet.")

}
