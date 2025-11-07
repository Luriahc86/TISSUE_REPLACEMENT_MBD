import db from "../config/db.js";

export const getAdmin = (req, res) => {
  const sql = "SELECT * FROM admin";
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ message: err });
    res.json(result);
  });
};


export const createAdmin = (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ message: "Username dan password wajib diisi" });
  }

  db.query(
    "INSERT INTO admin (username, password) VALUES (?, ?)",
    [username, password],
    (err, result) => {
      if (err) {
        if (err.code === "ER_DUP_ENTRY") {
          return res.status(409).json({ message: "Username sudah digunakan" });
        }
        return res.status(500).json({ message: err });
      }
      res.json({
        message: "ADMIN GACOR BERHASIL DIBUAT",
        data: { id_admin: result.insertId, username }
      });
    }
  );
};


export const getPegawai = (req, res) => {
  db.query("SELECT * FROM pegawai", (err, result) => {
    if (err) return res.status(500).json({ message: err });
    res.json(result);
  });
};

export const getLokasi = (req, res) => {
  db.query("SELECT * FROM lokasi", (err, result) => {
    if (err) return res.status(500).json({ message: err });
    res.json(result);
  });
};

export const getDispenser = (req, res) => {
  const sql = `
    SELECT d.id_dispenser, d.kondisi, 
           l.nama_lokasi, l.lokasi AS area
    FROM dispenser d
    JOIN lokasi l ON l.id_lokasi = d.id_lokasi;
  `;
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ message: err });
    res.json(result);
  });
};

export const getLogin = (req, res) => {
  const sql = `
    SELECT 
      lg.id_login, lg.waktu_login,
      a.username AS admin,
      p.username AS pegawai
    FROM login lg
    LEFT JOIN admin a ON a.id_admin = lg.id_admin
    LEFT JOIN pegawai p ON p.id_pegawai = lg.id_pegawai
    ORDER BY lg.waktu_login DESC;
  `;
  db.query(sql, (err, result) => {
    if (err) return res.status(500).json({ message: err });
    res.json(result);
  });
};
