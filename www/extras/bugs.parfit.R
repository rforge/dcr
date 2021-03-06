bugs.parfit <-
function(cl, data, params, model, inits=NULL, 
n.chains = 3, seed,
program=c("winbugs", "openbugs"), ...) ## only mcmc.list format is supported
{
    if (is.environment(data)) {
        warnings("'data' was environment: it was coerced into a list")
        data <- as.list(data)
    }
    if (missing(seed))
        stop("'seed' must be provided")
    ## if all seed are the same
    if (length(unique(seed)) != n.chains)
        stop("provide 'seed' for each chain")
    if (!inherits(cl, "cluster"))
        stop("'cl' must be a 'cluster' object")
    trace <- getOption("dcoptions")$verbose
    if (n.chains == 1)
        stop("no need for parallel computing with 1 chain")
    if (length(unique(seed)) < n.chains)
        stop("'seed' must have 'n.chains' unique values")
    if (!is.null(list(...)$format))
        if (list(...)$format == "bugs")
            stop("only 'mcmc.list' format is supported for parallel parallel computations")
    ## not case sensitive evaluation of program arg
    program <- match.arg(tolower(program), c("winbugs", "openbugs"))
    ## retrieves n.clones
    n.clones <- dclone:::nclones.list(data)
    ## removes n.clones attr from each element of data
    data <- lapply(data, function(z) {
        attr(z, "n.clones") <- NULL
        z
    })

    ## write model
    if (is.function(model) || inherits(model, "custommodel")) {
        if (is.function(model))
            model <- match.fun(model)
        ## write model only if SOCK cluster (shared memory)
        if (inherits(cl, "SOCKcluster")) {
            model <- write.jags.model(model)
            on.exit(try(clean.jags.model(model)))
        }
    }

    if (is.null(inits))
        inits <- lapply(1:n.chains, function(i) NULL)
    if (is.function(inits))
        inits <- lapply(1:n.chains, function(i) inits)
    ## common data to cluster
    cldata <- list(data=data, params=params, model=model, inits=inits, 
        seed=seed, program=program)
    ## parallel function to evaluate by snowWrapper
    bugsparallel <- function(i, ...)   {
        cldata <- pullDcloneEnv("cldata", type = "model")
        bugs.fit(data=cldata$data, params=cldata$params, 
            model=cldata$model, 
            inits=cldata$inits[[i]], n.chains=1, 
            seed=cldata$seed[i], 
            program=cldata$program, format="mcmc.list", ...)
    }
    if (trace) {
        cat("\nParallel computation in progress\n\n")
        flush.console()
    }
    ## parallel computations
    balancing <- if (getOption("dcoptions")$LB)
        "load" else "none"
    dir <- if (inherits(cl, "SOCKcluster"))
        getwd() else NULL
    mcmc <- parDosa(cl, 1:n.chains, bugsparallel, cldata, 
        lib="dclone", 
        balancing=balancing, size=1, 
        rng.type=getOption("dcoptions")$RNG, cleanup=TRUE, dir=dir, 
        unload=FALSE, ...)
    ## binding the chains
    res <- as.mcmc.list(lapply(mcmc, as.mcmc))

    ## adding n.clones attribute, and class attr if mcmc.list
    if (!is.null(n.clones) && n.clones > 1) {
        attr(res, "n.clones") <- n.clones
        class(res) <- c("mcmc.list.dc", class(res))
    }
    res
}
