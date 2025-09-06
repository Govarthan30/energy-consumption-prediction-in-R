FROM rocker/r-ver:4.3.1

# Install required R packages
RUN R -e "install.packages(c('plumber','dplyr'))"

# Copy API code
COPY energy.R /app/energy.R

# Expose port
EXPOSE 8000

# Run plumber
CMD ["R", "-e", "pr <- plumber::plumb('/app/energy.R'); pr$run(host='0.0.0.0', port=8000)"]
