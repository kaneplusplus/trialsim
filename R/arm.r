
#' Enroll an Arm for a Specified Number of Patients
#' 
#' @param size the enrollment size of the arm
#' @param sampler function to sample enrollment. Default 1 enrollment per 
#' period.
#' @param init_period the initial period. Default 0.
#' @importFrom tibble tibble
#' @export
arm_enroll <- function(size, sampler = function() 1, init_period = 0L) {
  period <- init_period
  ret <- tibble(period = integer(), enrolled = integer())  
  while(sum(ret$enrolled) < size) {
    period <- period + 1L
    new_row <- tibble(
      period = period,
      enrolled = sampler())
    
    if (new_row$enrolled > 0) {
      ret <- rbind(ret, new_row)
    }
  }
  if (sum(ret$enrolled) > size) {
    ret$enrolled[nrow(ret)] <- size - sum(ret$enrolled[-nrow(ret)])
  }
  ret
}

#' Create Retrorepective Binary Response Samples
#' 
#' @param arm the enrollment arm data.frame.
#' @param resps the number of responses.
#' @param size the number of trials to sample. Default 1.
#' @importFrom dplyr bind_rows
#' @importFrom foreach foreach %do%
#' @export
arm_bin_resample <- function(arm, resps, size = 1) {
  x <- sum(arm$enrolled)
  j <- NULL
  foreach (j = seq_len(size), .combine = bind_rows) %do% {
    a <- arm
    resp_enrollees <- sample.int(sum(a$enrolled), resps)
    a$enroll_num <- Map(seq_len, a$enrolled)
    for (i in seq_len(nrow(a))[-1]) {
      a$enroll_num[[i]] <- a$enroll_num[[i]] + max(a$enroll_num[[i-1]])
    }
    a$response <- unlist(Map(
      function(en) {
        sum(!is.na(match(en, resp_enrollees)))
      }, a$enroll_num))
    a <- a[,-3]
    a$sim <- j
    a
  }
}

#' Create Retrospective Response Combinations
#'
#' @param arm the enrollment arm data.frame.
#' @param resps the number of responses.
#' @importFrom foreach foreach %dopar% getDoParName registerDoSEQ 
#' getDoParWorkers
#' @importFrom itertools isplitVector
#' @importFrom dplyr bind_rows
#' @importFrom utils combn
#' @export
arm_bin_combn <- function(arm, resps) {
  if (is.null(getDoParName())) {
    registerDoSEQ()
  }
  x <- sum(arm$enrolled)
  ro <- combn(x, resps)
  arm$enroll_num <- Map(seq_len, arm$enrolled)
  for (i in seq_len(nrow(arm))[-1]) {
    arm$enroll_num[[i]] <- arm$enroll_num[[i]] + max(arm$enroll_num[[i-1]])
  }
  it <- NULL
  foreach(it = isplitVector(seq_len(ncol(ro)), 
                            chunks = round(getDoParWorkers())),
          .combine = bind_rows) %dopar% {

    foreach(i = it, .combine = bind_rows) %do% {
      arm$response <- unlist(Map(
        function(en) {
          sum(!is.na(match(en, ro[,i])))
        }, arm$enroll_num))
      arm$sim <- i
      arm[,-3]
    }
  }
}
