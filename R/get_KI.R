#' getKI
#'
#' @param rel Reliabilität des Tests. Meistens wird hierfür Cronbachs Alpha verwendet.
#' @param z z-Wert. Bestimmt die Sicherheit des Konfidenzintervalls. Verwende z = 1.96 für das 5%-KI.
#' @param sd Standardabweichuung der Verteilung.
#'
#' @return Positiver Wert des Konfidenzintervalls.
#' @export
#'
#' @examples
#' # 5% Konfidenzintervall für einen IQ-Test mit Reliabilität von .92
#' get_KI(rel = .92, z = 1.96, sd = 15)

get_KI <- function(rel, z = 1.96, sd = 15) {

  sem <- sd * sqrt(1-rel)
  KI <- round(sem * z, 2)

  return(KI)

}
