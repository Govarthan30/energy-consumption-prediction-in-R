import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  BarChart,
  Bar,
  ResponsiveContainer,
} from "recharts";
interface GraphData {
  Date: string;
  Consumption: number;
  Pred_Linear: number;
  Pred_Nonlinear: number;
}

interface AccuracyMetrics {
  RMSE: number;
  MAE: number;
  R2: number;
}

interface AccuracyResponse {
  linear: AccuracyMetrics;
  nonlinear: AccuracyMetrics;
}

function App() {
  // --- States ---
  const [graphData, setGraphData] = useState<GraphData[]>([]);
  const [accuracy, setAccuracy] = useState<AccuracyResponse | null>(null);
  const [temp, setTemp] = useState("");
  const [humidity, setHumidity] = useState("");
  const [wind, setWind] = useState("");
  const [solar, setSolar] = useState("");
  const [prediction, setPrediction] = useState<{ linear: number; nonlinear: number } | null>(null);

  // --- Fetch Graph Data ---
  useEffect(() => {
    fetch("http://localhost:8000/graphdata")
      .then((res) => res.json())
      .then((data) => setGraphData(data))
      .catch((err) => console.error(err));

    fetch("http://localhost:8000/accuracy")
      .then((res) => res.json())
      .then((data) => setAccuracy(data))
      .catch((err) => console.error(err));
  }, []);

  // --- Handle Prediction Submit ---
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const response = await fetch("http://localhost:8000/predict", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        temp,
        humidity,
        wind,
        solar,
      }),
    });

    const result = await response.json();
    setPrediction({
      linear: result.linear_prediction,
      nonlinear: result.nonlinear_prediction,
    });
  };

  return (
    <div style={{ padding: "2rem", maxWidth: "1200px", margin: "auto" }}>
      <h1 style={{ textAlign: "center" }}>⚡ Energy Consumption Forecast</h1>

      {/* Input Form */}
      <form
        onSubmit={handleSubmit}
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: "1rem",
          marginBottom: "2rem",
        }}
      >
        <input
          type="number"
          placeholder="Temperature (°C)"
          value={temp}
          onChange={(e) => setTemp(e.target.value)}
          required
        />
        <input
          type="number"
          placeholder="Humidity (%)"
          value={humidity}
          onChange={(e) => setHumidity(e.target.value)}
          required
        />
        <input
          type="number"
          placeholder="Wind Speed (km/h)"
          value={wind}
          onChange={(e) => setWind(e.target.value)}
          required
        />
        <input
          type="number"
          placeholder="Solar Radiation (W/m²)"
          value={solar}
          onChange={(e) => setSolar(e.target.value)}
          required
        />
        <button
          type="submit"
          style={{
            gridColumn: "span 4",
            padding: "0.8rem",
            background: "#007bff",
            color: "white",
            border: "none",
            borderRadius: "8px",
            cursor: "pointer",
          }}
        >
          Predict
        </button>
      </form>

      {/* Show Prediction */}
      {prediction && (
        <div style={{ marginBottom: "2rem", textAlign: "center" }}>
          <h2>Predicted Values</h2>
          <p>
            <b>Linear Model:</b> {prediction.linear} kWh
          </p>
          <p>
            <b>Nonlinear Model:</b> {prediction.nonlinear} kWh
          </p>
        </div>
      )}

      {/* Line Chart */}
      <h2>📈 Actual vs Predicted (Last 100 points)</h2>
      <ResponsiveContainer width="100%" height={400}>
        <LineChart data={graphData} margin={{ top: 20, right: 30, left: 0, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="Date" tick={false} />
          <YAxis />
          <Tooltip />
          <Legend />
          <Line type="monotone" dataKey="Consumption" stroke="#8884d8" name="Actual" />
          <Line type="monotone" dataKey="Pred_Linear" stroke="#82ca9d" name="Linear Model" />
          <Line type="monotone" dataKey="Pred_Nonlinear" stroke="#ff7300" name="Nonlinear Model" />
        </LineChart>
      </ResponsiveContainer>

      {/* Bar Chart */}
      <h2 style={{ marginTop: "2rem" }}>📊 Accuracy Metrics (RMSE, MAE, R²)</h2>
      {accuracy && (
        <ResponsiveContainer width="100%" height={300}>
          <BarChart
            data={[
              { model: "Linear", ...accuracy.linear },
              { model: "Nonlinear", ...accuracy.nonlinear },
            ]}
            margin={{ top: 20, right: 30, left: 0, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="model" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="RMSE" fill="#8884d8" />
            <Bar dataKey="MAE" fill="#82ca9d" />
            <Bar dataKey="R2" fill="#ff7300" />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

export default App;
