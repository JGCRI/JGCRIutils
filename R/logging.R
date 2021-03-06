# JGCRIutils logging functions

PKG.ENV <- new.env()    # environment in which to store logging info
LOGINFO <- ".loginfo"   # name of storage variable

# -----------------------------------------------------------------------------
#' Open a new logfile
#'
#' @param scriptname Name of script (and thus logfile)
#' @param loglevel Minimum priority level (numeric, optional)
#' @param logfile Override default logfile (character or \code{\link{connection}}, optional)
#' @param append Append to logfile? (logical, optional)
#' @param sink Send all console output to logfile? (logical, optional)
#' @return Invisible fully-qualified name of log file
#' @details Open a new logfile. If \code{sink} is TRUE (the default), all
#' screen output will be captured (via \code{\link{sink}}).
#' Re-opening a logfile will erase the previous output unless \code{append}
#' is TRUE. Note that messages will only appear in the logfile if their
#' \code{level} exceeds \code{loglevel}; this allows you to easily change
#' the amount of detail being logged.
#' @examples
#' logfile <- openlog("test")
#' printlog("message")
#' print("This will also appear in the logfile, as sink is TRUE")
#' closelog()
#' readLines(logfile)
#' @export
#' @seealso \code{\link{printlog}} \code{\link{closelog}}
openlog <- function(scriptname, loglevel = -Inf, logfile = NULL,
                    append = FALSE, sink = TRUE) {

  # Sanity checks
  assert_that(is.character(scriptname))
  assert_that(is.numeric(loglevel))
  assert_that(is.logical(append))
  assert_that(is.logical(sink))

  # Get logfile name; remove file if already present and not appending
  if(is.null(logfile)) {
    logfile <- file.path(outputdir(scriptname), paste0(scriptname, ".log.txt"))
  }
  if(file.exists(logfile) & !append) {
    file.remove(logfile)
  }

  # If log info already exists, close the previous file
  if(exists(LOGINFO, envir = PKG.ENV)) {
    warning("Closing previous log file")
    closelog()
  }

  # Create a (hidden) variable in the package environment to store log info
  loginfo <- list(loglevel = loglevel,
                  logfile = logfile,
                  scriptname = scriptname,
                  sink = sink,
                  sink.number = sink.number())
  assign(LOGINFO, loginfo, envir = PKG.ENV)

  if(sink) {
    sink(logfile, split = TRUE, append = append)
  }

  printlog("Opening", logfile, level = Inf)
  invisible(logfile)
} # openlog

# -----------------------------------------------------------------------------
#' Time-stamped output function
#'
#' @param msg A message to log (optional)
#' @param ... Additional items to log (optional)
#' @param level Priority level (numeric, optional)
#' @param ts Print preceding timestamp? (logical, optional)
#' @param cr Print trailing newline? (logical, optional)
#' @return Invisible success (TRUE) or failure (FALSE)
#' @details Logs a message, which may consist of one or more printable objects
#' @examples
#' logfile <- openlog("test")
#' printlog("message")
#' printlog(1, "plus", 1, "equals", 3)
#' closelog()
#' readLines(logfile)
#'
#' logfile <- openlog("test", loglevel = 1)
#' printlog("This message will not appear", level = 0)
#' printlog("This message will appear", level = 1)
#' closelog(sessionInfo = FALSE)
#' readLines(logfile)
#' @export
#' @seealso \code{\link{openlog}} \code{\link{closelog}}
printlog <- function(msg = "", ..., level = 0, ts = TRUE, cr = TRUE) {

  # Sanity checks
  assert_that(is.numeric(level))
  assert_that(is.logical(ts))
  assert_that(is.logical(cr))

  # Make sure there's an open log file available to close
  if(exists(LOGINFO, envir = PKG.ENV)) {
    loginfo <- get(LOGINFO, envir = PKG.ENV)
  } else {
    warning("No log file available")
    return(FALSE)
  }

  # Messages are only printed if their level exceeds the log's level
  if(level >= loginfo$loglevel) {
    if(loginfo$sink) { # If capturing everything, output to screen
      file <- stdout()
    } else {  # otherwise, file
      file <- loginfo$logfile
    }

    if(ts) cat(date(), " ", file = file, append = TRUE)
    cat(msg, ..., file = file, append = TRUE)
    if(cr) cat("\n", file = file, append = TRUE)
  }

  invisible(TRUE)
} # printlog

# -----------------------------------------------------------------------------
#' Close current logfile
#'
#' @param sessionInfo Print \code{\link{sessionInfo}} output? (logical, optional)
#' @return Invisible success (TRUE) or failure (FALSE)
#' @details Close current logfile
#' @export
#' @seealso \code{\link{openlog}} \code{\link{printlog}}
closelog <- function(sessionInfo = TRUE) {

  # Make sure there's an open log file available to close
  if(exists(LOGINFO, envir = PKG.ENV)) {
    loginfo <- get(LOGINFO, envir = PKG.ENV)
  } else {
    warning("No log file to close")
    return(FALSE)
  }

  printlog("Closing", loginfo$logfile, level = Inf)

  # Print sessionInfo() to file
  if(sessionInfo) try({
    sink(loginfo$logfile, append = TRUE)
    cat("-------\n")
    print(sessionInfo())
    sink()
  })

  # Remove sink, if applicable, and the log info file
  if(loginfo$sink & sink.number()) sink()
  try(rm(list = LOGINFO, envir = PKG.ENV), silent = TRUE)

  invisible(TRUE)
} # closelog

# -----------------------------------------------------------------------------
#' Return output directory
#'
#' @param scriptname Name of script (or output folder name)
#' @param scriptfolder Script-specific output folder? (logical, optional)
#' @return Output directory
#' @details Return output directory (perhaps inside a script-specific folder)
#' If caller specifies `scriptfolder=FALSE`, return OUTPUT_DIR
#' If caller specifies `scriptfolder=TRUE` (default), return OUTPUT_DIR/SCRIPTNAME
#' @keywords internal
outputdir <- function(scriptname, scriptfolder = TRUE) {

  # Sanity checks
  assert_that(is.character(scriptname))
  assert_that(is.logical(scriptfolder))

  odir <- "./output"   # TODO: should probably make this customizable
  if(scriptfolder)
    odir <- file.path(odir, sub(".R$", "", scriptname))
  if(!file.exists(odir))
    try(dir.create(odir, recursive = TRUE))
  odir
} # outputdir
