FROM rocker/r-ver:4.3.1

# Set working directory
WORKDIR /app

# Install system dependencies (needed for plumber, dplyr, httr, etc.)
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('plumber','dplyr'), repos='https://cloud.r-project.org')"

# Copy project files
COPY . .

# Expose API port
EXPOSE 8000

# Run the Plumber API
CMD ["Rscript", "run_api.r"]
