% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/plotting.R
\name{plotspict.prodrate}
\alias{plotspict.prodrate}
\title{Plot production rate as a function of biomass.}
\usage{
plotspict.prodrate(rep)
}
\arguments{
\item{rep}{A result report as generated by running fit.spict.}
}
\value{
Nothing.
}
\description{
Plot production rate as a function of biomass.
}
\details{
OBSOLETE!
}
\examples{
data(pol)
rep <- fit.spict(pol$albacore)
plotspict.prodrate(rep)
}

