# Testing code for the JGCRIutils scripts in 'logging.R'

context("logging")

test_that("functions handle bad input", {
  expect_error(openlog())
  expect_error(openlog("test", loglevel = TRUE))
  expect_error(openlog("test", loglevel = TRUE))
  expect_error(openlog("test", append = 1))
  expect_error(openlog("test", sink = 1))

  expect_error(printlog("test", level = TRUE))
  expect_error(printlog("test", ts = 1))
  expect_error(printlog("test", cr = 1))

  # printlog and closelog should generate warnings if called with no open log
  if(exists(".loginfo", envir = .GlobalEnv)) rm(".loginfo", envir = .GlobalEnv)
  expect_warning(printlog("hi"))
  expect_warning(closelog())
})

test_that("openlog handles special cases", {
  # Re-opening a log file should generate a warning
  LOGFILE <- openlog("test", sink = FALSE)
  expect_warning(openlog("test", sink = FALSE))
  closelog()

  # Appending
  oldsize <- file.size(LOGFILE)
  openlog("test", sink = FALSE, append = TRUE)
  closelog()
  expect_more_than(file.size(LOGFILE), oldsize)

  # Custom logfile
  tf <- tempfile()
  openlog("test", logfile = tf, sink = FALSE)
  closelog()
  expect_true(file.exists(tf))
})

test_that("Basic logging works correctly", {
  LOGFILE <- openlog("test", sink = FALSE)
  expect_is(LOGFILE, "character")
  expect_true(file.exists(LOGFILE))
  oldsize <- file.size(LOGFILE)
  expect_true(printlog("Line 1"))
  expect_more_than(file.size(LOGFILE), oldsize)
  oldsize <- file.size(LOGFILE)
  expect_true(closelog())
})

test_that("logging handles special cases", {

  # suppressing sessionInfo data
  LOGFILE <- openlog("test", sink = FALSE)
  closelog()
  oldsize <- file.size(LOGFILE)

  openlog("test", sink = FALSE)
  closelog(sessionInfo = FALSE)
  expect_less_than(file.size(LOGFILE), oldsize)

  # sink works correctly?
  capture.output({
    openlog("test", sink = TRUE)
    print("hi")
    closelog(sessionInfo = FALSE)
  })
  expect_equal(length(readLines(LOGFILE)), 3)
})

test_that("Priority levels work correctly", {
  LOGFILE <- openlog("test", loglevel = 0, sink = FALSE)

  size0 <- file.size(LOGFILE)
  printlog("Line 1")
  size1 <- file.size(LOGFILE)
  expect_more_than(size1, size0)
  printlog("Line 2", level = -1)
  size2 <- file.size(LOGFILE)
  expect_equal(size2, size1)
  printlog("Line 1", level = 1)
  expect_more_than(file.size(LOGFILE), size2)

  closelog()
})
