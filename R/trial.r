
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
trial_bin_resample <- function(resps, size, name, num_samples,
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

  foreach(it = isplitVector(seq_len(num_samples), 
          chunks = round(getDoParWorkers())), .combine = bind_rows) %dorng% {

    foreach(i = it, .combine = bind_rows) %do% {
      foreach(j = seq_along(resps), .combine = bind_rows) %do% {
        arm <- arm_bin_resample(arm_enroll(size[j], sampler = sampler[[j]]), 
                                resps[j])
        arm$name <- name[j]
        arm$sim <- i
        arm
      }
    }
  }
}
