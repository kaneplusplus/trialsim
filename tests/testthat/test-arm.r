library(purrr)

# Generate enrollment based on a poisson distribution with rate parameter 0.8
# then create all trial combinations with 3 responders.
arm_enroll(10, partial(rpois, n = 1, lambda = 0.8)) %>% 
  arm_bin_combn(3)

# Generate enrollment based on a poisson distribution with rate parameter 0.8
# then sample n trials
arm_enroll(10) %>% 
  arm_bin_resample(3, size = 2)
