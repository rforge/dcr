svabu <-
function (formula, data, zeroinfl=TRUE, area=1, N.max=NULL, inits,
    link.det = "logit", link.zif = "logit",
    model = TRUE, x = FALSE, 
#    distr = c("P", "NB"), 
    ...)
{
#    distr <- match.arg(distr)
    ## parsing the formula
    if (missing(data))
        data <- NULL
#    out <- svisitFormula(formula, data, n=sys.nframe()-1) ## parent frame
    out <- svisitFormula(formula, data, n=0) ## global environment
    out$call = match.call()
#    out$y <- NULL

    ## quick and dirty interface to sitespecific evaluation of phi
#    Q <- zeroinfl
#    if (!is.logical(zeroinfl))
#        zeroinfl <- TRUE

    Y <- out$y
    X <- out$x$sta
    Z <- out$x$det
    Q <- out$x$zif
    Xlevels <- out$levels
    if (!zeroinfl && !is.null(Q)) {
        warning("'zeroinfl = FALSE': zero inflation part in formula ignored")
        Q <- NULL
    }
    ## check variables
    if (length(Y) < 1)
        stop("empty model")
    if (all(Y > 0) && zeroinfl)
        warning("dependent variable has no 0 value, zero-inflated model might not be adequate")
    if (!any(Y > 1))
        warning("dependent variable does not contain any count > 1")
    if (!isTRUE(all.equal(as.vector(Y), as.integer(round(Y + 0.001)))))
        stop("invalid dependent variable, non-integer values")
    Y <- as.integer(round(Y + 0.001))
    if (any(Y < 0)) 
        stop("invalid dependent variable, negative counts")
    if (length(Y) != NROW(X)) 
        stop("invalid dependent variable, not a vector")
    if (setequal(colnames(Z), colnames(X))) 
        stop("at least one covariate should be separate for occupancy and detection parts of the formula")
    if (all(union(colnames(X), colnames(Z))[-1] %in% names(unlist(Xlevels))))
        stop("model must include at least one continuous covariate")
    ## link functions
    links <- c("logit", "probit", "cloglog")
    link.det <- match.arg(link.det, links)
    link.zif <- match.arg(link.zif, links)
    ## handling area argument
    if (!(length(area) %in% c(1, length(Y))))
        stop("invalid length for 'area' argument")
    if (any(area == 0))
        stop("'area' cannot be 0")

#return(list(Y=Y,X=X,Z=Z,Q=Q))

    ## fit
#    if (distr == "P") {
        fit <- svabu.fit(Y, X, Z, Q, zeroinfl=zeroinfl, area, N.max, inits, 
            link.det, link.zif, ...)
        sclass <- "svabu_p"
#    }
#    if (distr == "NB") {
#        stop("NB not yet implemented")
#        fit <- svabu_nb.fit(Y, X, Z, Q, zeroinfl=zeroinfl, area, N.max, inits, 
#            link.det, link.zif, ...)
#        sclass <- "svabu_nb"
#    }
    ## return value
    out <- c(fit, out)
    if (!model) 
        out$model <- NULL
    if (!x) 
        out$x <- NULL
    class(out) <- c(sclass, "svabu", "svisit")
    return(out)
}

