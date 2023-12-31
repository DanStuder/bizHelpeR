% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scale_fill_biz.R
\name{scale_fill_biz}
\alias{scale_fill_biz}
\title{Fill scale constructor}
\usage{
scale_fill_biz(palette = "BIZ", discrete = TRUE, reverse = FALSE, ...)
}
\arguments{
\item{palette}{Farbpalette, die verwendet werden soll}

\item{discrete}{Boolean, indiziert ob color aesthetic diskret ist oder nicht}

\item{reverse}{Boolean, der die Reihenfolge der Farbpalette umkehrt}

\item{...}{Weitere Argumente, die an discrete_scale()
oder scale_fill_gradientn() weitergeschickt werden}
}
\value{
Farben aus dem CI, die verwendet werden sollen (ersetzt scale_fill_manual())
}
\description{
Fill scale constructor
}
