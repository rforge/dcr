listDcExamples <- 
function() 
{
    read.table(paste(getOption("dcmle.href"), "/index.txt", sep=""))
}

sourceDcExample <- 
function(topic, assign.global=TRUE) 
{
    dcel <- listDcExamples()
    href <- paste(getOption("dcmle.href"), "/",
        dcel[,"href"], "/", dcel[,"topic"], ".R", sep="")
    TOPIC <- dcel[,"topic"]
    if (missing(topic))
        return(TOPIC)
    e <- new.env()
    eval(parse(href[TOPIC==topic]), e)
    if (assign.global)
        assign(topic, e[[topic]], envir=.GlobalEnv)
    invisible(e[[topic]])
}

dcExample <- 
function(topic, n.clones=NULL, ...) 
{
    x <- sourceDcExample(topic, assign.global=FALSE)
    rval <- if (!is.null(n.clones))
        dcmle(x, n.clones=n.clones, ...) else NULL
    spacer <- paste(rep("=", nchar(topic) + 32), collapse="")
    cat("\n", spacer, "\n    Data Cloning Example: \"", 
        topic, "\"\n", spacer, "\n", sep="")
    cat("\n\n< Structure of the Data/Model Template >\n\n")
    str(x)
    cat("\n")
    if (!is.null(rval)) {
        cat("\n< Summary of the Fitted MLE Object >\n\n")
        heading <- paste("Summary of the \"", topic, "\" example", sep="")
        getMethod("summary","dcMle")(rval, heading)
    }
    invisible(rval)
}