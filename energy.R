# =====================================================
# Energy Consumption Forecasting API with Graph Data
# =====================================================

library(plumber)
library(dplyr)

# -----------------------------------------------------
# Step 0: Enable CORS
# -----------------------------------------------------
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  } else {
    forward()
  }
}

# -----------------------------------------------------
# Step 1: Synthetic Dataset
# -----------------------------------------------------
set.seed(123)

n <- 5000
energy_data <- data.frame(
  DateTime = seq.POSIXt(
    from = as.POSIXct("2023-01-01 00:00"),
    by   = "hour",
    length.out = n
  ),
  Temperature = round(runif(n, min=10, max=40), 1),
  Humidity    = round(runif(n, min=20, max=90), 1),
  WindSpeed   = round(runif(n, min=0, max=20), 1),
  SolarRadiation = round(runif(n, min=0, max=1000), 1)
)

energy_data$Consumption <- round(
  50 +
    0.8 * energy_data$Temperature -
    0.3 * energy_data$Humidity +
    0.5 * energy_data$SolarRadiation/100 +
    5 * sin(2*pi*as.numeric(format(energy_data$DateTime, "%H"))/24) +
    rnorm(n, mean=0, sd=5), 1
)

# -----------------------------------------------------
# Step 2: Train Models
# -----------------------------------------------------
model_linear <- lm(Consumption ~ Temperature + Humidity + WindSpeed + SolarRadiation,
                   data = energy_data)

model_nonlinear <- nls(
  Consumption ~ a * exp(b * Temperature) + c * Humidity + d * SolarRadiation/100,
  data = energy_data,
  start = list(a = 1, b = 0.01, c = 1, d = 1)
)

# Add predictions for training set
energy_data$Pred_Linear <- predict(model_linear, newdata = energy_data)
energy_data$Pred_Nonlinear <- predict(model_nonlinear, newdata = energy_data)

# -----------------------------------------------------
# Step 3: API Endpoints
# -----------------------------------------------------

#* @apiTitle Energy Forecast API
#* @apiDescription Predict energy consumption and return graph data

#* Predict Energy Consumption
#* @param temp:numeric Temperature in °C
#* @param humidity:numeric Humidity in %
#* @param wind:numeric Wind speed in km/h
#* @param solar:numeric Solar radiation in W/m²
#* @post /predict
function(temp, humidity, wind, solar) {
  input <- data.frame(
    Temperature = as.numeric(temp),
    Humidity = as.numeric(humidity),
    WindSpeed = as.numeric(wind),
    SolarRadiation = as.numeric(solar)
  )
  
  pred_linear <- predict(model_linear, newdata = input)
  pred_nonlinear <- predict(model_nonlinear, newdata = input)
  
  list(
    linear_prediction = round(pred_linear, 2),
    nonlinear_prediction = round(pred_nonlinear, 2)
  )
}

# -----------------------------------------------------
# Step 4: Graph Data APIs
# -----------------------------------------------------

#* Return Accuracy Metrics (MAPE, MBE, Accuracy %)
#* @get /accuracy
function() {
  mape <- function(actual, predicted) mean(abs((actual - predicted) / actual)) * 100
  mbe  <- function(actual, predicted) mean(predicted - actual)
  
  list(
    linear = list(
      MAPE = round(mape(energy_data$Consumption, energy_data$Pred_Linear), 2),
      MBE = round(mbe(energy_data$Consumption, energy_data$Pred_Linear), 2),
      Accuracy = round(100 - mape(energy_data$Consumption, energy_data$Pred_Linear), 2)
    ),
    nonlinear = list(
      MAPE = round(mape(energy_data$Consumption, energy_data$Pred_Nonlinear), 2),
      MBE = round(mbe(energy_data$Consumption, energy_data$Pred_Nonlinear), 2),
      Accuracy = round(100 - mape(energy_data$Consumption, energy_data$Pred_Nonlinear), 2)
    )
  )
}

#* Return Graph Data: Actual vs Predicted
#* @get /graphdata
function() {
  # Send last 100 points for performance
  df <- tail(energy_data, 100) %>%
    mutate(Date = as.character(DateTime)) %>%
    select(Date, Consumption, Pred_Linear, Pred_Nonlinear)
  
  return(df)
}

#* Return Feature vs Consumption (for plotting)
#* @get /featuregraph
function() {
  # Relationship between Temperature and Consumption
  df <- energy_data %>%
    group_by(Temperature) %>%
    summarise(Avg_Consumption = mean(Consumption)) %>%
    arrange(Temperature)
  
  return(df)
}
