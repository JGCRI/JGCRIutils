# JGCRIutils logging functions

# -----------------------------------------------------------------------------
#' Open a new logfile
#'
#' @param scriptname Name of script (and thus logfile)
#' @param loglevel Minimum priority level (numeric, optional)
#' @param logfile Override default logfile (character, optional)
#' @param append Append to logfile? (logical, optional)
#' @param sink Sink to logfile? (logical, optional)
#' @return Invisible success (TRUE) or failure (FALSE)
#' @details Open a new logfile. Note that if \code{sink} is TRUE, all
#' screen output will be captured (via \code{\link{base::sink}}).
#' Re-opening a logfile will erase the previous output unless \code{append}
#' is TRUE. Finally, messages will only appear in the logfile if their
#' \code{level} exceeds \code{loglevel}.
#' @export
#' @seealso \code{\link{printlog}} \code{\link{closelog}}
openlog <- function(scriptname, loglevel = -Inf, logfile = NULL,
                    append = FALSE, sink = TRUE) {

  # Create logfile name and remove if already present and not appending
  if(is.null(logfile)) {
    logfile <- file.path(outputdir(scriptname), paste0(scriptname, ".log.txt"))
  }
  if(file.exists(logfile) & !append) {
    file.remove(logfile)
  }

  # If log info already exists, close the previous file
  if(exists(".loginfo", envir = .GlobalEnv)) {
    closelog()
  }

  # Create a (hidden) variable in the global environment to store log info
  loginfo <- list(loglevel = loglevel,
                  logfile = logfile,
                  scriptname = scriptname,
                  sink = sink,
                  sink.number = sink.number())
  assign(".loginfo", loginfo, envir = .GlobalEnv)

  if(sink) {
    sink(logfile, split = TRUE, append = append)
  }

  printlog("Opening", logfile)
} # openlog

# -----------------------------------------------------------------------------
#' Time-stamped output function
#'
#' @param msg One or more messages to log (optional)
#' @param level Priority level (numeric, optional)
#' @param ts Print preceding timestamp? (logical, optional)
#' @param cr Print trailing newline? (logical, optional)
#' @return Invisible success (TRUE) or failure (FALSE)
#' @details Logs a message, which may consist of one or more printable objects
#' @export
#' @seealso \code{\link{openlog}} \code{\link{closelog}}
printlog <- function(msg = "", ..., level = 0, ts = TRUE, cr = TRUE) {

  # Make sure there's an open log file available to close
  if(exists(".loginfo", envir = .GlobalEnv)) {
    loginfo <- get(".loginfo", envir = .GlobalEnv)
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
#' @return Invisible success (TRUE) or failure (FALSE)
#' @details Close current logfile
#' @export
#' @seealso \code{\link{openlog}} \code{\link{printlog}}
closelog <- function() {

  # Make sure there's an open log file available to close
  if(exists(".loginfo", envir = .GlobalEnv)) {
    loginfo <- get(".loginfo", envir = .GlobalEnv)
  } else {
    warning("No log file to close")
    return(FALSE)
  }

  printlog("Closing", loginfo$logfile)

  # Print sessionInfo() to file
  sink(loginfo$logfile, append = TRUE)
  print(sessionInfo())
  sink()

  # Remove sink, if applicable, and the log info file
  if(loginfo$sink) sink()
  try(rm(".loginfo", envir = .GlobalEnv), silent = TRUE)

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
  odir <- "./output/"   # TODO: should probably make this customizable
  if(scriptfolder)
    odir <- file.path(odir, sub(".R$", "", scriptname))
  if(!file.exists(odir))
    try(dir.create(odir, recursive = TRUE))
  odir
} # outputdir