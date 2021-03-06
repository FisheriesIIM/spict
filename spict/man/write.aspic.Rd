% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/aspic.R
\name{write.aspic}
\alias{write.aspic}
\title{Takes a SPiCT input list and writes it as an Aspic input file.}
\usage{
write.aspic(input, filename = "spictout.a7inp")
}
\arguments{
\item{input}{List of input variables or the output of a simulation using sim.spict().}

\item{filename}{Name of the file to write.}
}
\value{
Noting.
}
\description{
Takes a SPiCT input list and writes it as an Aspic input file.
}
\details{
TBA
}
\examples{
data(pol)
sim <- (pol$albacore)
write.aspic(sim)
}

