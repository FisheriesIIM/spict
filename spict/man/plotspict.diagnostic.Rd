% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/plotting.R
\name{plotspict.diagnostic}
\alias{plotspict.diagnostic}
\title{Plot model diagnostic (data, residuals, and more)}
\usage{
plotspict.diagnostic(rep, lag.max = 4, qlegend = TRUE, plot.data = TRUE,
  mfcol = FALSE)
}
\arguments{
\item{rep}{A result report as generated by running fit.spict.}

\item{lag.max}{Maximum lag to use in acf calculations.}

\item{qlegend}{If TRUE plot a legend showing quarter of year information.}

\item{plot.data}{If TRUE plot data in the top row (this option is only applied if osa residuals have been calculated).}

\item{mfcol}{If TRUE plot plots columnwise (FALSE => rowwise).}
}
\value{
Nothing.
}
\description{
Plot model diagnostic (data, residuals, and more)
}
\examples{
data(pol)
rep <- fit.spict(pol$albacore)
rep <- calc.osa.resid(rep)
plotspict.diagnostic(rep)
}

