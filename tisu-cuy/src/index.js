import express from "express";
import cors from "cors";
import morgan from "morgan";
import mysql from "mysql2";
import masterRoutes from "./routes/masterRoutes.js";

const app = express();
const PORT = process.env.PORT || 3000;

const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "",
  database: "cleaning_system"
});

db.connect((err) => {
  if (err) {
    console.error("DATABASE MU GA KONEK CES:", );
    process.exit(1);
  } else {
    console.log("DATABASE MU SUDAH KONEK CES");
  }
});

app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.use("/api/master", masterRoutes);

app.get("/", (req, res) => {
  res.json({
    message: "🧻 TISU-CUY API is running!",
    endpoints: {
      laporan: "/api/laporan",
      master: "/api/master"
    }
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running di http://localhost:${PORT}`);
});
