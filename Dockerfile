# Use prebuilt R image with Plumber installed
FROM rocker/plumber:latest

# Set working directory inside container
WORKDIR /app

# Copy your API code into the container
COPY energy.R ./energy.R

# If you need dplyr, install it here (optional, takes less time than plumber)
RUN R -e "install.packages('dplyr', repos='https://cloud.r-project.org')"

# Expose the port the API will run on
EXPOSE 8000

# Run the Plumber API
CMD ["R", "-e", "pr <- plumber::plumb('energy.R'); pr$run(host='0.0.0.0', port=8000)"]
