% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/report.R
\name{make.report}
\alias{make.report}
\title{Creates a pdf file containing the summary output and result plots}
\usage{
make.report(rep, reporttitle = "", reportfile = "report.tex",
  summaryoutfile = "summaryout.txt", keep.figurefiles = FALSE,
  keep.txtfiles = FALSE)
}
\arguments{
\item{rep}{A valid result from fit.spict with OSA residuals.}

\item{reporttitle}{This character string will be printed as the first line of the report.}

\item{reportfile}{The generated tex code will be stored in this file.}

\item{summaryoutfile}{Output of the summary will be stored in this file as plain text.}

\item{keep.figurefiles}{If TRUE generated figure files will not be cleaned up.}

\item{keep.txtfiles}{If TRUE generated txt files will not be cleaned up.}
}
\value{
Nothing.
}
\description{
Creates a pdf file containing the summary output and result plots
}
\details{
This function probably requires that you are running linux and that you have latex functions installed (pdflatex).
}

