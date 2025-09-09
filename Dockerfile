FROM rocker/r-ver:4.3.1

# Set working directory
WORKDIR /app

# Install system dependencies for R packages
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Force install packages into system library
RUN R -e "install.packages(c('plumber','dplyr'), repos='https://cloud.r-project.org', lib='/usr/local/lib/R/site-library')"

# Verify plumber is installed
RUN R -e "library(plumber); library(dplyr); sessionInfo()"

# Copy project files
COPY . .

# Expose API port
EXPOSE 8000

# Run the Plumber API
CMD ["Rscript", "run_api.r"]
