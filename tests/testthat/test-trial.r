library(purrr)

resps <- c(8, 0, 1, 1, 6, 2)
size <- c(19, 10, 26, 8, 14, 7)
name <- c("NSCLC", "CRC (vemu)", "CRC (vemu+cetu)", "Bile Duct", "ECD or LCH", 
          "ATC")

# Sample 1 enrollee per period.
bin_trial_resample(resps, size, name, 1)

# Assume that the enrollment rate is inversely proportional to the 
# number enrolled.
lambda <- size / max(size)

# Create a poisson sampler for each arm. 
sampler <- lapply(lambda, function(l) partial(rpois, n = 1, lambda = {{l}}))

# Use the sampler to change the enrollement duration.
bin_trial_resample(resps, size, name, 1, sampler = sampler)
