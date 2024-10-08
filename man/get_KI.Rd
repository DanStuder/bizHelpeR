% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_KI.R
\name{get_KI}
\alias{get_KI}
\title{getKI}
\usage{
get_KI(rel, z = 1.96, sd = 15)
}
\arguments{
\item{rel}{Reliabilität des Tests. Meistens wird hierfür Cronbachs Alpha verwendet.}

\item{z}{z-Wert. Bestimmt die Sicherheit des Konfidenzintervalls. Verwende z = 1.96 für das 5\%-KI.}

\item{sd}{Standardabweichuung der Verteilung.}
}
\value{
Positiver Wert des Konfidenzintervalls.
}
\description{
getKI
}
\examples{
# 5\% Konfidenzintervall für einen IQ-Test mit Reliabilität von .92
get_KI(rel = .92, z = 1.96, sd = 15)
}
