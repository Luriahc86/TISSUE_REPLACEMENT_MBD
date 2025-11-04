DELIMITER $$
CREATE OR REPLACE VIEW v_laporan_pegawai AS
SELECT 
  p.id_pegawai,
  p.username AS nama_pegawai,
  lp.id_laporan,
  lp.jumlah_tisu,
  lp.keterangan,
  lp.waktu,
  l.nama_lokasi,
  d.kondisi AS kondisi_dispenser
FROM laporan_penggantian lp
JOIN pegawai p ON p.id_pegawai = lp.id_pegawai
JOIN dispenser d ON d.id_dispenser = lp.id_dispenser
JOIN lokasi l ON l.id_lokasi = d.id_lokasi
ORDER BY lp.waktu DESC;

CREATE OR REPLACE VIEW v_detail_penggantian AS
SELECT 
  lp.id_laporan,
  lp.waktu,
  p.username AS pegawai,
  l.nama_lokasi,
  d.id_dispenser,
  lp.jumlah_tisu,
  lp.keterangan
FROM laporan_penggantian lp
JOIN pegawai p ON p.id_pegawai = lp.id_pegawai
JOIN dispenser d ON d.id_dispenser = lp.id_dispenser
JOIN lokasi l ON l.id_lokasi = d.id_lokasi
ORDER BY lp.waktu DESC;

CREATE OR REPLACE VIEW v_login_activity AS
SELECT 
  lg.id_login,
  lg.waktu_login,
  COALESCE(a.username, p.username) AS username,
  CASE 
    WHEN lg.id_admin IS NOT NULL THEN 'ADMIN'
    WHEN lg.id_pegawai IS NOT NULL THEN 'PEGAWAI'
    ELSE 'UNKNOWN'
  END AS tipe_pengguna
FROM login lg
LEFT JOIN admin a ON a.id_admin = lg.id_admin
LEFT JOIN pegawai p ON p.id_pegawai = lg.id_pegawai
ORDER BY lg.waktu_login DESC;

CREATE OR REPLACE VIEW v_laporan_penggantian AS
SELECT 
  lp.id_laporan, lp.waktu, lp.jumlah_tisu, lp.keterangan,
  p.id_pegawai, p.username AS nama_pegawai,
  d.id_dispenser, d.kondisi,
  l.id_lokasi, l.nama_lokasi, l.lokasi AS area
FROM laporan_penggantian lp
JOIN pegawai p   ON p.id_pegawai  = lp.id_pegawai
JOIN dispenser d ON d.id_dispenser= lp.id_dispenser
JOIN lokasi l    ON l.id_lokasi   = d.id_lokasi;

CREATE OR REPLACE VIEW v_dispenser_per_lokasi AS
SELECT 
  l.id_lokasi, l.nama_lokasi, l.lokasi AS area,
  COUNT(d.id_dispenser) AS total_dispenser,
  SUM(CASE WHEN d.kondisi='AKTIF' THEN 1 ELSE 0 END) AS aktif,
  SUM(CASE WHEN d.kondisi='RUSAK' THEN 1 ELSE 0 END) AS rusak,
  SUM(CASE WHEN d.kondisi='PERBAIKAN' THEN 1 ELSE 0 END) AS perbaikan
FROM lokasi l
LEFT JOIN dispenser d ON d.id_lokasi=l.id_lokasi
GROUP BY l.id_lokasi, l.nama_lokasi, l.lokasi;