# Use R 4.3.1 base image
FROM rocker/r-ver:4.3.1

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libicu-dev \
    libgit2-dev \
    libmagick++-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required R packages globally
RUN R -e "install.packages(c('plumber','dplyr','ggplot2','caret','jsonlite'), repos='https://cloud.r-project.org')"

# Copy project files into container
COPY . .

# Expose API port
EXPOSE 8000

# Ensure R knows where to find installed packages
ENV R_LIBS_SITE=/usr/local/lib/R/site-library

# Run the Plumber API
CMD ["Rscript", "run_api.r"]
