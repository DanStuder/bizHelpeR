#' Remove empty pages
#'
#' Diese Funktion findet und entfernt leere Seiten in einem PDF-Dokument.
#' Dieser Prozess funktioniert aber nur für Dokumente mit Text;
#' d.h. Bilder werden nicht erkannt.
#'
#' @param input Name des Input-PDFs
#' @param output Name des Output-PDFs
#'
#' @return Gibt den Pfad des Output-PDFs an
#' @export


remove_empty_pages <- function(input, output) {

  # Sub-Function to check if a page is empty
  is_empty_page <- function(pdf_file, page_number) {
    text <- pdftools::pdf_text(pdf_file)[page_number]
    text <- stringr::str_replace_all(text, "\\s", "")  # Remove white spaces
    return(nchar(text) == 0)
  }

  num_pages <- pdftools::pdf_info(input)$pages

  non_empty_pages <- sapply(1:num_pages, function(page) {
    !is_empty_page(input, page)
  })

  pdftools::pdf_subset(input, non_empty_pages, output = output)
}
