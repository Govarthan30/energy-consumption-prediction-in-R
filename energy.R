# =====================================================
# Energy Consumption Forecasting API - Single Script
# =====================================================

# ------------------------------
# 1. Load Libraries
# ------------------------------
library(plumber)
library(dplyr)
library(ggplot2)
library(caret)

# ------------------------------
# 2. Enable CORS
# ------------------------------
#* @filter cors
function(req, res){
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  if(req$REQUEST_METHOD == "OPTIONS"){
    res$status <- 200
    return(list())
  } else {
    forward()
  }
}

# ------------------------------
# 3. Load Real-World Dataset
# ------------------------------
# Replace with your downloaded Kaggle dataset path
real_data <- read.csv("household_power_consumption.csv", sep=";", na.strings="?")

# Convert date/time and filter complete rows
real_data$DateTime <- as.POSIXct(paste(real_data$Date, real_data$Time), format="%d/%m/%Y %H:%M:%S")
real_data <- real_data[complete.cases(real_data), ]

# Select relevant columns
# If dataset doesn't have these columns, you may simulate them
if(!all(c("Temperature","Humidity","WindSpeed","SolarRadiation") %in% colnames(real_data))){
  set.seed(123)
  n <- nrow(real_data)
  real_data$Temperature <- round(runif(n, 10, 40), 1)
  real_data$Humidity <- round(runif(n, 20, 90), 1)
  real_data$WindSpeed <- round(runif(n, 0, 20), 1)
  real_data$SolarRadiation <- round(runif(n, 0, 1000), 1)
}

energy_data <- real_data %>% 
  dplyr::select(DateTime, Global_active_power, Temperature, Humidity, WindSpeed, SolarRadiation) %>% 
  rename(Consumption = Global_active_power)

# ------------------------------
# 4. Train/Test Split
# ------------------------------
set.seed(123)
train_index <- sample(seq_len(nrow(energy_data)), size = 0.8*nrow(energy_data))
train_data <- energy_data[train_index, ]
test_data  <- energy_data[-train_index, ]

# ------------------------------
# 5. Train Models
# ------------------------------
# Linear Regression
model_linear <- lm(Consumption ~ Temperature + Humidity + WindSpeed + SolarRadiation, data = train_data)

# Nonlinear Regression
model_nonlinear <- nls(
  Consumption ~ a * exp(b * Temperature) + c * Humidity + d * SolarRadiation/100,
  data = train_data,
  start = list(a=1, b=0.01, c=1, d=1)
)

# ------------------------------
# 6. Evaluation Metrics
# ------------------------------
calculate_metrics <- function(actual, predicted){
  mae <- mean(abs(actual - predicted))
  rmse <- sqrt(mean((actual - predicted)^2))
  r2 <- 1 - sum((actual - predicted)^2)/sum((actual - mean(actual))^2)
  return(list(MAE=mae, RMSE=rmse, R2=r2))
}

# Predict on test data
pred_linear_test <- predict(model_linear, newdata=test_data)
pred_nonlinear_test <- predict(model_nonlinear, newdata=test_data)

metrics_linear <- calculate_metrics(test_data$Consumption, pred_linear_test)
metrics_nonlinear <- calculate_metrics(test_data$Consumption, pred_nonlinear_test)

# ------------------------------
# 7. Comparison Graph
# ------------------------------
comparison_df <- data.frame(
  DateTime = test_data$DateTime,
  Actual = test_data$Consumption,
  Predicted_Linear = pred_linear_test,
  Predicted_Nonlinear = pred_nonlinear_test
)

ggplot(comparison_df, aes(x=DateTime)) +
  geom_line(aes(y=Actual, color="Actual")) +
  geom_line(aes(y=Predicted_Linear, color="Linear Model")) +
  geom_line(aes(y=Predicted_Nonlinear, color="Nonlinear Model")) +
  labs(title="Energy Consumption Forecasting Comparison",
       x="DateTime", y="Consumption (kW)") +
  scale_color_manual(values=c("Actual"="black","Linear Model"="blue","Nonlinear Model"="red")) +
  theme_minimal()

# ------------------------------
# 8. Plumber API
# ------------------------------

#* @apiTitle Energy Forecast API
#* @apiDescription Predict energy consumption using Linear & Non-linear regression models

#* Predict Energy Consumption
#* @param temp:numeric Temperature in °C
#* @param humidity:numeric Humidity in %
#* @param wind:numeric Wind speed in km/h
#* @param solar:numeric Solar radiation in W/m²
#* @post /predict
function(temp, humidity, wind, solar){
  input <- data.frame(
    Temperature = as.numeric(temp),
    Humidity = as.numeric(humidity),
    WindSpeed = as.numeric(wind),
    SolarRadiation = as.numeric(solar)
  )
  
  pred_linear <- predict(model_linear, newdata=input)
  pred_nonlinear <- predict(model_nonlinear, newdata=input)
  
  list(
    linear_prediction = round(pred_linear,2),
    nonlinear_prediction = round(pred_nonlinear,2),
    linear_metrics = metrics_linear,
    nonlinear_metrics = metrics_nonlinear
  )
}
