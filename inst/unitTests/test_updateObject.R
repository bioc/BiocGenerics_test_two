###

test_updateObject_list <- function()
{
    setClass("A",
             representation(x="numeric"), prototype(x=1:10),
             where=.GlobalEnv)
    a <- new("A")
    l <- list(a,a)
    checkTrue(identical(l, updateObject(l)))

    setMethod("updateObject", "A",
              function(object, ..., verbose=FALSE) {
                  if (verbose) message("updateObject object = 'A'")
                  object@x <- -object@x
                  object
              },
              where=.GlobalEnv)

    obj <- updateObject(l)
    checkTrue(identical(lapply(l, function(elt) { elt@x <- -elt@x; elt }),
                        obj))
    removeMethod("updateObject", "A", where=.GlobalEnv)
    removeClass("A", where=.GlobalEnv)
}

test_updateObject_env <- function()
{
    opts <- options()
    options(warn=-1)
    e <- new.env()
    e$x=1
    e$.x=1
    obj <- updateObject(e)
    checkTrue(identical(e,obj))         # modifies environment

    lockEnvironment(e)
    obj <- updateObject(e)              # copies environment
    checkTrue(identical(lapply(ls(e, all=TRUE), function(x) x),
                        lapply(ls(obj, all=TRUE), function(x) x)))
    checkTrue(!identical(e, obj))       # different environments

    e <- new.env()
    e$x=1
    e$.x=1
    lockBinding("x", e)
    checkException(updateObject(e), silent=TRUE)

    lockEnvironment(e)
    obj <- updateObject(e)
    checkTrue(TRUE==bindingIsLocked("x", obj)) # R bug, 14 May, 2006, fixed
    checkTrue(FALSE==bindingIsLocked(".x", obj))
    options(opts)
}

test_updateObject_defaults <- function()
{
    x <- 1:10
    checkTrue(identical(x, updateObject(x)))
    checkTrue(identical(1:10, updateObjectTo(x, 10:1)))
    x <- as.numeric(1:10)
    checkTrue(identical(as.integer(1:10), updateObjectTo(x, integer())))
    checkTrue(!identical(as.numeric(1:10), updateObjectTo(x, integer())))
}

test_updateObject_S4 <- function()
{
    setClass("A",
             representation=representation(
               x="numeric"),
             prototype=list(x=1:5),
             where=.GlobalEnv)
    .__a__ <- new("A")
    setClass("A",
             representation=representation(
               x="numeric",
               y="character"),
             where=.GlobalEnv)
    checkException(validObject(.__a__), silent=TRUE)      # now out-of-date
    .__a__@x <- 1:5
    a <- updateObject(.__a__)
    checkTrue(validObject(a))
    checkIdentical(1:5, a@x)
    removeClass("A", where=.GlobalEnv)
}

test_updateObject_setClass <- function()
{
    setClass("A",
             representation(x="numeric"),
             prototype=prototype(x=1:10),
             where=.GlobalEnv)
    a <- new("A")
    checkTrue(identical(a,updateObject(a)))
    a1 <- new("A",x=10:1)
    checkTrue(identical(a, updateObjectTo(a, a1)))

    setClass("B",
             representation(x="numeric"),
             where=.GlobalEnv)
    b <- new("B")
    checkException(updateObjectTo(a, b), silent=TRUE)

    setAs("A", "B", function(from) {
        b <- new("B")
        b@x <- from@x
        b
    }, where=.GlobalEnv)
    obj <- updateObjectTo(a,b)
    checkTrue(class(obj)=="B")
    checkIdentical(obj@x, a@x)
    removeMethod("coerce", c("A","B"), where=.GlobalEnv)
    removeClass("B", where=.GlobalEnv)
    removeClass("A", where=.GlobalEnv)
}
