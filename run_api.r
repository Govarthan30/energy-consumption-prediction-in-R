library(plumber)

# Load plumber router from energy_api.R
pr <- plumb("energy.R")
pr$run(host = "0.0.0.0", port = 8000)
