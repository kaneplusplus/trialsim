
#' @importFrom crayon red
copy_closure <- function(closure) {
  if (!is.function(closure)) {
    stop(red("Argument is not a closure."))
  }
  ret <- closure
  environment(ret) <- 
    as.environment(as.list(environment(closure), all.names = TRUE))
  parent.env(environment(ret)) <- parent.env(environment(closure))
  ret
}

#' Resample Trial Enrollment and Binary Outcomes
#'
#' @param resps the number of responses per arm.
#' @param size the size of each arm.
#' @param name the name of each arm.
#' @param num_samples the number of resamples to draw.
#' @param sampler function to sample enrollment. Default 1 enrollment per
#' period.
#' @importFrom crayon red
#' @importFrom doRNG %dorng%
#' @importFrom foreach foreach getDoParWorkers getDoParName
#' @importFrom itertools isplitVector
#' @export
bin_trial_resample <- function(resps, size, name, num_samples,
  sampler = lapply(seq_along(resps), function(x) function() 1)) {

  if (is.null(getDoParName())) {
    registerDoSEQ()
  }

  if (!isTRUE(all(c(length(resps) == length(size), 
                    length(size) == length(name))))) {
    stop(red("Parameters resps, size, and name must have the same length."))
  }
  if (length(sampler) != length(resps)) {
    stop(red("You must specify one sampler per arm."))
  }

  it <- NULL
  i <- NULL
  j <- NULL
  foreach(it = isplitVector(seq_len(num_samples), 
          chunks = round(getDoParWorkers())), .combine = bind_rows) %dorng% {

    foreach(i = it, .combine = bind_rows) %do% {
      # copy the resampler in case it maintains state.
      sampler_copy <- sapply(sampler, copy_closure)
      foreach(j = seq_along(resps), .combine = bind_rows) %do% {
        arm <- arm_bin_resample(arm_enroll(size[j], 
                                           sampler = sampler_copy[[j]]), 
                                           resps[j])
        arm$name <- name[j]
        arm$sim <- i
        arm
      }
    }
  }
}
