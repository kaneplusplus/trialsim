
#' Sample Enrollment over a Fixed Period
#'
#' @param size the number of enrollees per arm.
#' @param max_duration the maximum of the trial. Default 'max(size)'.
#' @param multi_enroll_period can there be multiple enrollees in a period?
#' Default TRUE.
#' @importFrom crayon red
#' @export
fixed_duration_sampler <- function(size, max_duration = max(size),
                                   multi_enroll_period = TRUE) {
  lapply(size,
    function(s) {
      fixed_duration_single_sampler(s, max_duration, multi_enroll_period)
    })
}

# Mutable closure that samples a specified number of enrollments (size)
# for a specified duration, and returns them sequentially.
fixed_duration_single_sampler <- function(size, duration, multi_enroll_period) {
  et <- sample.int(duration, size, replace = !multi_enroll_period)
  enrollment <- rep(0, duration)
  for (e in et) {
    enrollment[e] <- enrollment[e] + 1
  }
  e_it <- 1
  function() {
    if (e_it > length(enrollment)) {
      stop(red("No more enrollments."))
    }
    e_it <<- e_it + 1
    enrollment[e_it - 1]
  }
}

#' Sample Enrollment from a Poisson Distribution
#'
#' @param lambda the poisson rate parameter (one per arm).
#' @importFrom stats rpois
#' @importFrom purrr partial 
#' @export
poisson_sampler <- function(lambda) {
  lapply(lambda, function(l) partial(rpois, n = 1, lambda = l, .lazy = FALSE))
}
