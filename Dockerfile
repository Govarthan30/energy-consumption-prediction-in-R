FROM rocker/r-ver:4.3.1

# Set working directory
WORKDIR /app

# Install system dependencies needed for plumber + dplyr
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages (force system library path)
RUN R -e "install.packages(c('remotes'), repos='https://cloud.r-project.org', lib='/usr/local/lib/R/site-library')" \
 && R -e "remotes::install_cran(c('plumber','dplyr'), lib='/usr/local/lib/R/site-library')"

# Copy project files
COPY . .

# Expose API port
EXPOSE 8000

# Run the Plumber API
CMD ["Rscript", "run_api.r"]
