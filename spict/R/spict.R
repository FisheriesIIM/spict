# Stochastic surplus Production model in Continuous-Time (SPiCT)
#    Copyright (C) 2015  Martin Waever Pedersen, mawp@dtu.dk or wpsgodd@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


#' @name fit.spict
#' @title Fit a continuous-time surplus production model to data.
#' @details Fits the model using the TMB package and returns a result report containing estimates of model parameters, random effects (biomass and fishing mortality), reference points (Fmsy, Bmsy, MSY) including uncertainties given as standard deviations.
#'
#' Fixed effects:
#' \itemize{
#'   \item{"logm"}{ Log of maximum sustainable yield.}
#'   \item{"logK"}{ Log of carrying capacity.}
#'   \item{"logq"}{ Log of catchability vector.}
#'   \item{"logsdf"}{ Log of standard deviation of fishing mortality process noise.}
#'   \item{"logsdb"}{ Log of standard deviation of biomass process noise.}
#' }
#'
#' Optional parameters (which are normally not estimated):
#' \itemize{
#'   \item{"phi"}{ Used when inp$nseasons > 1 to specify the cyclic B spline representing seasonal variation.}
#'   \item{"logalpha"}{ Proportionality factor for the observation noise of the indices and the biomass process noise: sdi = exp(logalpha)*sdb. (normally set to logalpha=0)}
#'   \item{"logbeta"}{ Proportionality factor for the observation noise of the catches and the fishing mortality process noise: sdc = exp(logbeta)*sdf. (this is often difficult to estimate and can result in divergence of the optimisation. Normally set to logbeta=0)}
#'   \item{"logn"}{ Parameter determining the shape of the production curve as in the generalised form of Pella & Tomlinson (1969). Default: log(2).}
#' }
#'
#' Random effects:
#' \itemize{
#'   \item{"logB"}{ Log of the biomass process given by the continuous-time stochastic Schaefer equation: dB_t = r*B_t*(1-(B_t/K)^n)*dt + sdb*dW_t, where dW_t is Brownian motion.}
#'   \item{"logF"}{ Log of the fishing mortality process given by: F_t = D_s*G_t, where D_s is a cyclic B spline and dG_t = sigma_F * dV, with dV being Brownian motion.}
#' }
#'
#' Derived parameters:
#' \itemize{
#'   \item{"logr"}{ Log of intrinsic growth rate (r = 4m/K).}
#'   \item{"logBmsy"}{ Log of the equilibrium biomass (Bmsy) when fished at Fmsy.}
#'   \item{"logFmsy"}{ Log of the fishing mortality (Fmsy) leading to the maximum sustainable yield.}
#'   \item{"MSY"}{ The yield when the biomass is at Bmsy and the fishing mortality is at Fmsy, i.e. the maximum sustainable yield.}
#' }
#'
#' The above parameter values can be extracted from the fit.spict() results using get.par().
#'
#' Model assumptions
#' \itemize{
#'   \item{"1"}{The intrinsic growth rate (r) represents a combination of natural mortality, growth, and recruitment.}
#'   \item{"2"}{The biomass B_t refers to the exploitable part of the stock. Estimates in absolute numbers (K, Bmsy, etc.) should be interpreted in light of this.}
#'   \item{"3"}{The stock is closed to migration.}
#'   \item{"4"}{Age and size-distribution are stable in time.}
#'   \item{"5"}{Constant catchability of the gear used to gather information for the biomass index.}
#' }
#' @param inp List of input variables as output by check.inp.
#' @param dbg Debugging option. Will print out runtime information useful for debugging if set to 1. Will print even more if set to 2.
#' @return A result report containing estimates of model parameters, random effects (biomass and fishing mortality), reference points (Fmsy, Bmsy, MSY) including uncertainties given as standard deviations.
#' @export
#' @examples
#' data(pol)
#' rep <- fit.spict(pol$albacore)
#' summary(rep)
#' plot(rep)
#' @import TMB
fit.spict <- function(inp, dbg=0){
    # Check input list
    inp <- check.inp(inp)
    datin <- make.datin(inp, dbg)
    pl <- inp$parlist
    # Cycle through phases
    for(i in 1:inp$nphases){
        if(inp$nphases>1) cat(paste('Estimating - phase',i,'\n'))
        # Create TMB object
        obj <- make.obj(datin, pl, inp, phase=i)
        if(dbg<1){
            # Do estimation
            if(inp$optimiser == 'nlminb'){
                opt <- try(nlminb(obj$par, obj$fn, obj$gr))
                if(class(opt)!='try-error'){
                    pl <- obj$env$parList(opt$par)
                }
            }
            if(inp$optimiser == 'optim'){
                opt <- try(optim(par=obj$par, fn=obj$fn, gr=obj$gr, method='BFGS'))
                if(class(opt)!='try-error'){
                    opt$objective <- opt$value
                    pl <- obj$env$parList(opt$par)
                }
            }
        }
    }
    rep <- list()
    rep$inp <- inp
    if(dbg<1){
        if(class(opt)!='try-error'){
            if(inp$do.sd.report){
                # Calculate SD report
                rep <- try(TMB::sdreport(obj))
                failflag <- class(rep)=='try-error'
                if(failflag){
                    cat('WARNING: Could not calculate sdreport.\n')
                    rep <- list()
                    rep$sderr <- 1
                    rep$par.fixed <- opt$par
                    rep$cov.fixed <- matrix(NA, length(opt$par), length(opt$par))
                    rep$report <- obj$report()
                }
                rep$obj <- obj
                if(!failflag){
                    rep$inp <- inp
                    if(inp$reportall){
                        #  - Calculate Prager's statistics -
                        if(!'stats' %in% names(rep)) rep$stats <- list()
                        K <- get.par('logK', rep, exp=TRUE)[2]
                        Bests <- get.par('logB', rep, exp=TRUE)[rep$inp$indest, 2]
                        Bmsy <- get.par('logBmsy', rep, exp=TRUE)[2]
                        if(!any(is.na(Bests)) & !is.na(Bmsy)){
                            Bdiff <- Bmsy - Bests
                            # Prager's nearness
                            if(any(diff(sign(Bdiff))!=0)){
                                rep$stats$nearness <- 1
                            } else {
                                rep$stats$nearness <- 1 - min(abs(Bdiff))/Bmsy
                            }
                            # Prager's coverage
                            rep$stats$coverage <- min(c(2, (min(c(K, max(Bests))) - min(Bests))/Bmsy))
                        }
                        # - Built-in OSAR -
                        if(!inp$osar.method == 'none'){
                            rep <- calc.osa.resid(rep)
                        }
                    }
                }
            }
            rep$pl <- obj$env$parList(opt$par)
            obj$fn()
            rep$Cp <- obj$report()$Cp
            rep$report <- obj$report()
            rep$inp <- inp
            rep$opt <- opt
        } else {
            cat('obj$par:\n')
            print(obj$par)
            cat('obj$fn:\n')
            print(obj$fn())
            cat('obj$gr:\n')
            print(obj$gr())
            stop('Could not fit model, try changing the initial parameter guess in inp$ini. Error msg:', opt)
        }
    }
    if(!is.null(rep)) class(rep) <- "spictcls"
    return(rep)
}


#' @name make.datin
#' @title Create data list.
#' @param inp List of input variables as output by check.inp.
#' @param dbg Debugging option. Will print out runtime information useful for debugging if set to 1. 
#' @return List to be used as data input to TMB.
make.datin <- function(inp, dbg=0){
    datin <- list(reportall=as.numeric(inp$reportall),
                  dt=inp$dt,
                  dtpredcinds=inp$dtpredcinds,
                  dtpredcnsteps=inp$dtpredcnsteps,
                  dtprediind=inp$dtprediind,
                  indlastobs=inp$indlastobs,
                  obssrt=inp$obssrt,
                  isc=inp$isc,
                  isi=inp$isi,
                  nobsC=inp$nobsC,
                  nobsI=sum(inp$nobsI),
                  ic=inp$ic,
                  nc=inp$nc,
                  ii=inp$iiin,
                  iq=inp$iqin,
                  ir=inp$ir,
                  seasons=inp$seasons,
                  seasonindex=inp$seasonindex,
                  splinemat=inp$splinemat,
                  splinematfine=inp$splinematfine,
                  omega=inp$omega,
                  seasontype=inp$seasontype,
                  ffacvec=inp$ffacvec,
                  fconvec=inp$fconvec,
                  indpred=inp$indpred,
                  robflagc=inp$robflagc,
                  robflagi=inp$robflagi,
                  stochmsy=ifelse(inp$msytype=='s', 1, 0),
                  priorr=inp$priors$logr,
                  priorn=inp$priors$logn,
                  priorK=inp$priors$logK,
                  priorm=inp$priors$logm,
                  priorq=inp$priors$logq,
                  priorbkfrac=inp$priors$logbkfrac,
                  priorB=inp$priors$logB,
                  priorF=inp$priors$logF,
                  simple=inp$simple,
                  dbg=dbg)
    return(datin)
}


#' @name make.obj
#' @title Create TMB obj.
#' @param datin Data list.
#' @param pl Parameter list.
#' @param inp List of input variables as output by check.inp.
#' @param phase Estimation phase, integer.
#' @return List to be used as data input to TMB.
#' @import TMB
make.obj <- function(datin, pl, inp, phase=1){
    obj <- TMB::MakeADFun(data=datin, parameters=pl, random=inp$RE, DLL=inp$scriptname, hessian=TRUE, map=inp$map[[phase]])
    TMB:::config(trace.optimize=0, DLL=inp$scriptname)
    verbose <- FALSE
    obj$env$tracemgc <- verbose
    obj$env$inner.control$trace <- verbose
    obj$env$silent <- ! verbose
    obj$fn(obj$par)
    return(obj)
}
