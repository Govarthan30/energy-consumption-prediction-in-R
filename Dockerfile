FROM rocker/r-ver:4.3.1

WORKDIR /app

# Install packages
RUN R -e "install.packages(c('plumber','dplyr'), repos='https://cloud.r-project.org')"

# Copy all project files into container
COPY . .

EXPOSE 8000

# Run API
CMD ["Rscript", "run_api.r"]
