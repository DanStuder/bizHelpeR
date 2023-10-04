#' pdfMergeR
#'
#' @param modul Name des Moduls, falls abweichend vom gewählten Ordner
#' @param directory Ordner, für den die Dateien erstellt werden sollen
#'
#' @return Erstellt ein PDF aus dem Word-Dokument der Mappe und kombiniert und schneidet die anderen PDF-Dateien
#' @importFrom doconv docx2pdf
#' @importFrom qpdf pdf_combine pdf_length pdf_subset
#' @importFrom tcltk tk_choose.dir
#' @export


pdfMergeR <- function(directory = tcltk::tk_choose.dir(), modul = NULL) {

  start_time <- Sys.time()

  # Setze Directory (User kann im Browser anwählen)
  setwd(directory)

  modul <- basename(getwd())

  # Liste der Dokumente, die später zusammengefügt werden sollen.
  FILENAMES <- c("Mappe.pdf",
                 "Ergebnisse.pdf",
                 "Rohdaten.pdf")

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

    # Ersetze Leerschlag durch Underscore für Kompatibilität
    ## Dann bei den PDFs im Ordner
    ### Wähle alle PDFs aus
    files <- list.files(path = client)
    ### Iteriere über alle PDFs
    for(file in files) {
      #### Definiere alten und neuen Namen und ersetze
      old_name <- paste(client, file, sep = "/")
      new_name <- paste(client, gsub(" ", "_", file), sep = "/")
      file.rename(from = old_name, to = new_name)

    }

    # Finde docs und drucke zu PDF (falls es nicht bereits existiert)
    if(!any(grep(FILENAMES[1], list.files(client)))) {
      doc_in_name <- paste(client, list.files(path = client, pattern = ".docx"), sep = "/")
      doc_out_name <- paste(client,
                            paste(client,
                                  FILENAMES[1],
                                  sep = "_"),
                            sep = "/")
      # Falls das File existiert (und richtig benannt wurde), dann erstelle es als PDF
      if(file.exists(doc_in_name)) {
        doconv::docx2pdf(input = doc_in_name,
                         output = doc_out_name)
      } else {warning(paste(doc_in_name, "wurde nicht gefunden. Stelle sicher, dass das Dokument richtig benannt wurde."))}
    } else if(grep(FILENAMES[1], list.files(client)) > 1) {
      # Sollte eigentlich nicht möglich sein, aber falls mehr als 2 Doks mit
      # "Ergebnisse.pdf" gefunden werden, dann gib eine Warnung aus.
      warning(paste("Mehr als 1 bestehendes Dokument mit dem Namen",
                    client,
                    FILENAMES[2],
                    "gefunden."))
    }

    # Füge alles zusammen (Version für GEVER)
    all_in_names <- paste(paste(client, client, sep = "/"), FILENAMES, sep = "_")
    ## bei Modul VLGK muss noch der Fragebogen angehängt werden
    if(modul == "VLGK") {
      fragebogen_in <- paste(paste(client,
                                   client,
                                   sep = "/"),
                             "Fragebogen.pdf",
                             sep = "_")
      fragebogen_out <- paste(paste(client,
                                    client,
                                    sep = "/"),
                              "Fragebogen.pdf")

      # Fragebogen hat genau 5 Seiten. Wenn das PDF länger ist,
      # dann liegt das daran, dass im Scan noch eine leere Seite drin ist,
      # die abgeschnitten werden kann
      FB_LENGTH <- 5 # Konstante, die verändert werden kann/muss,
      # wenn der FB verändert wird.
      if(qpdf::pdf_length(input = fragebogen_in) > FB_LENGTH) {
        qpdf::pdf_subset(input = fragebogen_in,
                             pages = 1:5,
                             output = fragebogen_out)
        file.remove(fragebogen_in)
        file.rename(from = fragebogen_out,
                    to = fragebogen_in)
      }
      all_in_names <- c(all_in_names,
                        fragebogen_in)
    }
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
    protocol_in_name <- paste(paste(client, client, sep = "/"), FILENAMES[1], sep = "_")
    protocol_out_name <- paste(paste(client, client, sep = "/"), "Protokoll.pdf", sep = "_")

    ## Bereite String vor, nach dem gesucht werden soll
    PROTOCOL <- "Protokoll.pdf"

    ## Suche nach dem String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(PROTOCOL, list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      qpdf::pdf_subset(input = protocol_in_name,
                           pages = 1,
                           output = protocol_out_name)
    }

    # Separiere die Rückmeldemappe
    rmm_in_name <- paste(paste(client, client, sep = "/"), FILENAMES[1], sep = "_")
    rmm_out_name <- paste(paste(client, client, sep = "/"), "Rückmeldemappe.pdf", sep = "_")

    ## Bereite Strings vor, nach denen gesucht werden soll
    RMM <- "Rückmeldemappe.pdf"

    ## Suche nach den String (-> prüfe, ob Dokument schon existiert)
    if(!any(grepl(RMM, list.files(client)))) {
      # Wenn es noch nicht existiert, dann erstelle das Dokument
      qpdf::pdf_subset(input = rmm_in_name,
                           pages = -1,
                           output = rmm_out_name)
    }

    # Entferne das Dokument "Mappe"
    file.remove(paste(client,
                      paste(client,
                            FILENAMES[1],
                            sep = "_"),
                      sep = "/"))

    # Entferne underscores für Lesbarkeit
    ## Wähle alle PDFs aus
    files <- list.files(path = client, pattern = ".pdf")

    ## Iteriere über alle PDFs
    for(file in files) {
      # Definiere alten und neuen Namen und ersetze
      old_name <- paste(client, file, sep = "/")
      new_name <- paste(client, gsub("_", " ", file), sep = "/")
      file.rename(from = old_name, to = new_name)

    }

  }

  # Erfolgs-Nachricht
  end_time <- Sys.time()

  print(paste("Prozess abgeschlossen in",
              round(end_time - start_time,
                    digits = 1),
              "Sekunden"))

}
