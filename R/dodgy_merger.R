#' merger
#'
#' @param directory Ordner, für den die Dateien erstellt werden sollen
#'
#' @return Erstellt ein PDF aus dem Word-Dokument der Mappe und kombiniert und schneidet die anderen PDF-Dateien
#' @importFrom pdftools pdf_text
#' @importFrom qpdf pdf_combine pdf_length pdf_subset
#' @importFrom stringi stri_detect_regex
#' @importFrom stringr str_detect str_replace_all str_split
#' @importFrom tcltk tk_choose.dir
#' @export


dodgy_merger <- function(directory = tcltk::tk_choose.dir(), ist_override = FALSE) {

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
    word2pdf_dodgy(inputs = mappen_docm_todo)

    wait_for_files_stable(mappen_pdf_todo, timeout = 300)
  }


  ###### Ab jetzt wird pro Klient*in separat gearbeitet
  # Hole die Namen der Klient*innen
  clients <- list.files()

  # Iteriere über jede Person...
  for (client in clients) {

    # Testen, ob IST 5 enthalten und Konfidenzintervall aktiviert ist
    ## Inhalt der Ergebnisse lesen
    ergebnisse_pfad <- list.files(path = client,
                                  pattern = "Ergebnisse\\.pdf$",
                                  full.names = TRUE)

    ergebnisse_inhalt <- ergebnisse_pfad |>
      pdftools::pdf_text() |>
      stringr::str_split(pattern = "\n") |>
      unlist()
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
      qpdf::pdf_combine(input = c(ergebnisse_pfad,
                                  qlevel),
                        output = ergebnisse2)
      # Entferne Ergebnisse & Q-Level und nenne Ergebnisse2 um
      file.remove(ergebnisse_pfad, qlevel)
      file.rename(from = ergebnisse2,
                  to = ergebnisse_pfad)
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

      qpdf::pdf_combine(input = c(rohdaten,
                                  fragebogen_in),
                        output = rohdaten_temp)
      file.rename(from = rohdaten_temp, to = rohdaten)
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
      qpdf::pdf_combine(input = all_in_names,
                        output = all_out_name)
    }

    # Separiere das Protokoll
    mappe <- list.files(path = client,
                        pattern = "Mappe\\.pdf$",
                        full.names = TRUE)
    protocol_out_name <- paste(paste(client, client, sep = "/"), PROTOCOL, sep = " ")
    rmm_out_name <- paste(paste(client, client, sep = "/"), "Rückmeldemappe.pdf", sep = " ")

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
    file.remove(mappe)

  }

  print("Merge erfolgreich beendet.")

}
