# Use official R image
FROM rocker/r-ver:4.3.1

# Set working directory inside container
WORKDIR /app

# Install required R packages
RUN R -e "install.packages(c('plumber','dplyr'), repos='https://cloud.r-project.org')"

# Copy API code into container
COPY energy.R ./energy.R

# Expose the port the API will run on
EXPOSE 8000

# Run the Plumber API
CMD ["R", "-e", "pr <- plumber::plumb('energy.R'); pr$run(host='0.0.0.0', port=8000)"]
