## this prints the summary
setMethod("summary", "pva", function(object) {
    y <- summary(as(object, "dcmle"), fancyPVAmodel(object))
    y@coef <- object@summary
    show(y)
})

## this extracts mcmc info 
## and transforms it to original scale if desired
setMethod("as.mcmc.list", "pva", 
function(x, diagn_scale=FALSE, ...) {
    m <- as.mcmc.list(as(x,"dcmle"))
    if (diagn_scale) {
        x@model@transf(m)
    } else {
        m
    }
})

## coef method (takes into account fixed values)
setMethod("coef", "pva", function(object) {
    object@fullcoef
})

## need to define this as well
setMethod("vcov", "pva", function(object) {
    vc <- object@vcov
    fx <- object@model@fixed
    if (is.null(fx))
        return(vc)
    vn <- object@model@varnames
    rv <- matrix(NA, length(vn), length(vn))
    dimnames(rv) <- list(vn, vn)
    i <- !(vn %in% names(fx))
    rv[i,i] <- vc
    rv
})
setMethod("confint", "pva", function(object) {
    ci <- confint(as.mcmc.list(object, diagn_scale=FALSE))
    fx <- object@model@fixed
    if (is.null(fx))
        return(ci)
    vn <- object@model@varnames
    rv <- matrix(NA, length(vn), 2)
    dimnames(rv) <- list(vn, colnames(ci))
    i <- !(vn %in% names(fx))
    rv[i,] <- ci
    rv
})
