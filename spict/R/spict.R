#' @name fit.spict
#' @title Fit a continuous-time surplus production model to data.
#' @details Fits the model using the TMB package and returns a result report containing estimates of model parameters, random effects (biomass and fishing mortality), reference points (Fmsy, Bmsy, MSY) including uncertainties given as standard deviations.
#'
#' Fixed effects:
#' \itemize{
#'   \item{"logr"}{ Log of intrinsic growth rate.}
#'   \item{"logK"}{ Log of carrying capacity.}
#'   \item{"logq"}{ Log of catchability vector.}
#'   \item{"logsdf"}{ Log of standard deviation of fishing mortality process noise.}
#'   \item{"logsdb"}{ Log of standard deviation of biomass process noise.}
#' }
#'
#' Optional fixed effects (which are normally not estimated):
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
#'   \item{"logBmsy"}{ Log of the equilibrium biomass (Bmsy) when fished at Fmsy.}
#'   \item{"logFmsy"}{ Log of the fishing mortality (Fmsy) leading to the maximum sustainable yield.}
#'   \item{"MSY"}{ The yield when the biomass is at Bmsy and the fishing mortality is at Fmsy, i.e. the maximum sustainable yield.}
#' }
#'
#' The above parameter values can be extracted from the fit.spict() results using get.par().
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
    datin <- list(reportall=as.numeric(inp$reportall), dt=inp$dt, dtpredcinds=inp$dtpredcinds, dtpredcnsteps=inp$dtpredcnsteps, dtprediind=inp$dtprediind, indlastobs=inp$indlastobs, obsC=inp$obsC, ic=inp$ic, nc=inp$nc, I=inp$obsIin, ii=inp$iiin, iq=inp$iqin, ir=inp$ir, seasons=inp$seasons, seasonindex=inp$seasonindex, splinemat=inp$splinemat, ffac=inp$ffaceuler, indpred=inp$indpred, robflagc=inp$robflagc, robflagi=inp$robflagi, lamperti=inp$lamperti, euler=inp$euler, stochmsy=ifelse(inp$msytype=='s', 1, 0), dbg=dbg)
    pl <- inp$parlist
    for(i in 1:inp$nphases){
        if(inp$nphases>1) cat(paste('Estimating - phase',i,'\n'))
        obj <- TMB::MakeADFun(data=datin, parameters=pl, random=inp$RE, DLL=inp$scriptname, hessian=TRUE, map=inp$map[[i]])
        config(trace.optimize=0, DLL=inp$scriptname)
        verbose <- FALSE
        obj$env$tracemgc <- verbose
        obj$env$inner.control$trace <- verbose
        obj$env$silent <- ! verbose
        obj$fn(obj$par)
        if(dbg<1){
            opt <- try(nlminb(obj$par, obj$fn, obj$gr))
            pl <- obj$env$parList(opt$par)
        }
    }
    rep <- list()
    if(dbg<1){
        if(class(opt)!='try-error'){
            # Calculate SD report
            if(inp$do.sd.report){
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
                if(!failflag){
                    rep$inp <- inp
                    if(inp$reportall){
                        #  - Calculate statistics -
                        rep$stats <- list()
                        K <- get.par('logK', rep, exp=TRUE)[2]
                        #r <- get.par('logr', rep, exp=TRUE)[2]
                        n <- get.par('logn', rep, exp=TRUE)[2]
                        p <- n-1
                        Best <- get.par('logB', rep, exp=TRUE)
                        Bests <- Best[rep$inp$indest, 2]
                        # R-square
                        #Pest <- get.par('P', rep)
                        #B <- Best[-inp$ns, 2]
                        #inds <- unique(c(inp$ic[1:inp$nobsC], unlist(inp$ii)))
                        #gr <- r*(1-(B[inds]/K)^p) # Pella-Tomlinson production
                        #grobs <- Pest[inds, 2]/inp$dt[inds]/B[inds]
                        #ssqobs <- sum((grobs - mean(grobs))^2)
                        #ssqres <- sum((grobs - gr)^2)
                        #rep$stats$pseudoRsq <- 1 - ssqres/ssqobs
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
            stop('Could not fit model, try changing the initial parameter guess in inp$ini. Error msg:', opt)
        }
    }
    if(!is.null(rep)) class(rep) <- "spictcls"
    return(rep)
}