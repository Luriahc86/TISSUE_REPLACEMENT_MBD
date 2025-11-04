DROP DATABASE IF EXISTS cleaning_system;
CREATE DATABASE cleaning_system;
USE cleaning_system;


CREATE TABLE admin (
  id_admin INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE pegawai (
  id_pegawai INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE login (
  id_login INT AUTO_INCREMENT PRIMARY KEY,
  id_admin INT NULL,
  id_pegawai INT NULL,
  waktu_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_login_admin FOREIGN KEY (id_admin) REFERENCES admin(id_admin)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_login_pegawai FOREIGN KEY (id_pegawai) REFERENCES pegawai(id_pegawai)
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE lokasi (
  id_lokasi INT AUTO_INCREMENT PRIMARY KEY,
  nama_lokasi VARCHAR(100) NOT NULL,
  lokasi VARCHAR(100) NOT NULL,
  deskripsi TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_lokasi (nama_lokasi, lokasi)
);

CREATE TABLE dispenser (
  id_dispenser INT AUTO_INCREMENT PRIMARY KEY,
  id_lokasi INT NOT NULL,
  kondisi ENUM('AKTIF','RUSAK','PERBAIKAN') DEFAULT 'AKTIF',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_dispenser_lokasi FOREIGN KEY (id_lokasi) REFERENCES lokasi(id_lokasi)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE laporan_penggantian (
  id_laporan INT AUTO_INCREMENT PRIMARY KEY,
  id_dispenser INT NOT NULL,
  id_pegawai INT NOT NULL,
  jumlah_tisu INT NOT NULL,
  keterangan TEXT,
  waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_lp_disp FOREIGN KEY (id_dispenser) REFERENCES dispenser(id_dispenser)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_lp_peg FOREIGN KEY (id_pegawai) REFERENCES pegawai(id_pegawai)
    ON DELETE CASCADE ON UPDATE CASCADE
);


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


DELIMITER $$
CREATE FUNCTION total_tisu_by_pegawai(p_id_pegawai INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT SUM(jumlah_tisu) INTO total FROM laporan_penggantian WHERE id_pegawai=p_id_pegawai;
  RETURN IFNULL(total,0);
END$$

CREATE FUNCTION total_laporan_by_dispenser(p_id_dispenser INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT COUNT(*) INTO total FROM laporan_penggantian WHERE id_dispenser=p_id_dispenser;
  RETURN IFNULL(total,0);
END$$

CREATE FUNCTION total_dispenser_by_lokasi(p_id_lokasi INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT COUNT(*) INTO total FROM dispenser WHERE id_lokasi=p_id_lokasi;
  RETURN IFNULL(total,0);
END$$

CREATE FUNCTION last_penggantian_by_dispenser(p_id_dispenser INT)
RETURNS DATETIME DETERMINISTIC
BEGIN
  DECLARE t DATETIME;
  SELECT MAX(waktu) INTO t FROM laporan_penggantian WHERE id_dispenser=p_id_dispenser;
  RETURN t;
END$$

CREATE FUNCTION get_laporan_by_lokasi(p_id_lokasi INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n
  FROM laporan_penggantian lp
  JOIN dispenser d ON lp.id_dispenser = d.id_dispenser
  WHERE d.id_lokasi = p_id_lokasi;
  RETURN IFNULL(n,0);
END$$

CREATE FUNCTION rekap_penggantian_periode(p_start DATE, p_end DATE)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT SUM(jumlah_tisu) INTO total
  FROM laporan_penggantian
  WHERE DATE(waktu) BETWEEN p_start AND p_end;
  RETURN IFNULL(total,0);
END$$

DELIMITER $$
CREATE PROCEDURE laporan_penggantian_insert(
  IN p_id_dispenser INT,
  IN p_id_pegawai INT,
  IN p_jumlah_tisu INT,
  IN p_keterangan TEXT
)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;

  IF p_jumlah_tisu < 0 THEN
    SELECT 'ERROR: jumlah_tisu tidak boleh negatif' AS message;
  ELSE
    START TRANSACTION;
      INSERT INTO laporan_penggantian(id_dispenser, id_pegawai, jumlah_tisu, keterangan)
      VALUES(p_id_dispenser, p_id_pegawai, p_jumlah_tisu, p_keterangan);

      IF ROW_COUNT() = 0 THEN
        SET _err = TRUE;
      END IF;

      IF _err THEN
        ROLLBACK;
        INSERT INTO log_aktivitas(tabel, aksi, id_aktor, tipe_aktor, keterangan)
        VALUES('laporan_penggantian', 'FAILED-INSERT', p_id_pegawai, 'PEGAWAI',
               CONCAT('dispenser_id=', p_id_dispenser));
        SELECT 'ERROR: gagal tambah laporan' AS message;
      ELSE
        INSERT INTO log_aktivitas(tabel, id_referensi, aksi, id_aktor, tipe_aktor, keterangan)
        VALUES('laporan_penggantian', LAST_INSERT_ID(), 'INSERT', p_id_pegawai, 'PEGAWAI',
               CONCAT('dispenser_id=', p_id_dispenser, '; jumlah=', p_jumlah_tisu));
        COMMIT;
        SELECT 'OK' AS message;
      END IF;
  END IF;
END$$

CREATE PROCEDURE login_admin(IN p_username VARCHAR(50), IN p_password VARCHAR(100))
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT id_admin INTO v_id FROM admin WHERE username=p_username AND password=p_password LIMIT 1;
  IF v_id IS NULL THEN
    SELECT 'ERROR: Login admin gagal' AS message;
  ELSE
    INSERT INTO login(id_admin) VALUES (v_id);
    SELECT 'OK' AS message, v_id AS id_admin;
  END IF;
END$$

CREATE PROCEDURE login_pegawai(IN p_username VARCHAR(50), IN p_password VARCHAR(100))
BEGIN
  DECLARE v_id INT DEFAULT NULL;
  SELECT id_pegawai INTO v_id FROM pegawai WHERE username=p_username AND password=p_password LIMIT 1;
  IF v_id IS NULL THEN
    SELECT 'ERROR: Login pegawai gagal' AS message;
  ELSE
    INSERT INTO login(id_pegawai) VALUES (v_id);
    SELECT 'OK' AS message, v_id AS id_pegawai;
  END IF;
END$$

CREATE PROCEDURE tambah_pegawai_by_admin(
  IN p_id_admin INT, IN p_username VARCHAR(50), IN p_password VARCHAR(100)
)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;

  START TRANSACTION;
    INSERT INTO pegawai(username,password) VALUES(p_username,p_password);
    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('pegawai','FAILED-INSERT',p_id_admin,'ADMIN',CONCAT('username=',p_username));
      SELECT 'ERROR: gagal tambah pegawai' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('pegawai',LAST_INSERT_ID(),'INSERT-BY-ADMIN',p_id_admin,'ADMIN',CONCAT('username=',p_username));
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END$$

CREATE PROCEDURE edit_pegawai_by_admin(
  IN p_id_admin INT, IN p_id_pegawai INT, IN p_username_baru VARCHAR(50), IN p_password_baru VARCHAR(100)
)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  START TRANSACTION;
    UPDATE pegawai
      SET username=p_username_baru, password=p_password_baru, updated_at=NOW()
    WHERE id_pegawai=p_id_pegawai;

    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('pegawai',p_id_pegawai,'FAILED-UPDATE',p_id_admin,'ADMIN');
      SELECT 'ERROR: pegawai tidak ditemukan / tidak diubah' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('pegawai',p_id_pegawai,'UPDATE-BY-ADMIN',p_id_admin,'ADMIN',CONCAT('username_baru=',p_username_baru));
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END$$

CREATE PROCEDURE hapus_pegawai_by_admin(IN p_id_admin INT, IN p_id_pegawai INT)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  START TRANSACTION;
    DELETE FROM pegawai WHERE id_pegawai=p_id_pegawai;
    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('pegawai',p_id_pegawai,'FAILED-DELETE',p_id_admin,'ADMIN');
      SELECT 'ERROR: pegawai tidak ditemukan' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('pegawai',p_id_pegawai,'DELETE-BY-ADMIN',p_id_admin,'ADMIN');
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END$$

CREATE PROCEDURE tambah_lokasi_by_admin(
  IN p_id_admin INT, IN p_nama_lokasi VARCHAR(100), IN p_lokasi VARCHAR(100), IN p_deskripsi TEXT
)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  DECLARE v_id INT;

  START TRANSACTION;
    INSERT INTO lokasi(nama_lokasi,lokasi,deskripsi,created_at,updated_at)
    VALUES(p_nama_lokasi,p_lokasi,p_deskripsi,NOW(),NOW());
    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('lokasi','FAILED-INSERT',p_id_admin,'ADMIN',CONCAT('nama=',p_nama_lokasi,'; area=',p_lokasi));
      SELECT 'ERROR: gagal tambah lokasi (mungkin duplikat)' AS message;
    ELSE
      SET v_id = LAST_INSERT_ID();
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('lokasi',v_id,'INSERT-BY-ADMIN',p_id_admin,'ADMIN',CONCAT('nama=',p_nama_lokasi,'; area=',p_lokasi));
      COMMIT;
      SELECT 'OK' AS message, v_id AS id_lokasi;
    END IF;
END$$

CREATE PROCEDURE edit_lokasi_by_admin(
  IN p_id_admin INT, IN p_id_lokasi INT,
  IN p_nama_lokasi_baru VARCHAR(100), IN p_lokasi_baru VARCHAR(100), IN p_deskripsi_baru TEXT
)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  START TRANSACTION;
    UPDATE lokasi
      SET nama_lokasi=p_nama_lokasi_baru, lokasi=p_lokasi_baru, deskripsi=p_deskripsi_baru, updated_at=NOW()
    WHERE id_lokasi=p_id_lokasi;

    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('lokasi',p_id_lokasi,'FAILED-UPDATE',p_id_admin,'ADMIN');
      SELECT 'ERROR: lokasi tidak ditemukan / tidak diubah' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('lokasi',p_id_lokasi,'UPDATE-BY-ADMIN',p_id_admin,'ADMIN',
             CONCAT('nama_baru=',p_nama_lokasi_baru,'; area_baru=',p_lokasi_baru));
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END$$

CREATE PROCEDURE hapus_lokasi_by_admin(IN p_id_admin INT, IN p_id_lokasi INT)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  START TRANSACTION;
    DELETE FROM lokasi WHERE id_lokasi=p_id_lokasi;
    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('lokasi',p_id_lokasi,'FAILED-DELETE',p_id_admin,'ADMIN');
      SELECT 'ERROR: lokasi tidak ditemukan' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('lokasi',p_id_lokasi,'DELETE-BY-ADMIN',p_id_admin,'ADMIN');
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END$$

CREATE PROCEDURE edit_dispenser_by_admin(
  IN p_id_admin INT, IN p_id_dispenser INT, IN p_id_lokasi_baru INT, IN p_kondisi_baru VARCHAR(20)
)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  DECLARE v_kondisi ENUM('AKTIF','RUSAK','PERBAIKAN');

  SET p_kondisi_baru = UPPER(TRIM(p_kondisi_baru));
  IF p_kondisi_baru NOT IN ('AKTIF','RUSAK','PERBAIKAN') THEN
    SELECT 'ERROR: kondisi harus AKTIF/RUSAK/PERBAIKAN' AS message;
  ELSE
    SET v_kondisi = p_kondisi_baru;
    START TRANSACTION;
      UPDATE dispenser
        SET id_lokasi=p_id_lokasi_baru, kondisi=v_kondisi, updated_at=NOW()
      WHERE id_dispenser=p_id_dispenser;

      IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

      IF _err THEN
        ROLLBACK;
        INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
        VALUES('dispenser',p_id_dispenser,'FAILED-UPDATE',p_id_admin,'ADMIN');
        SELECT 'ERROR: dispenser tidak ditemukan / tidak diubah' AS message;
      ELSE
        INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
        VALUES('dispenser',p_id_dispenser,'UPDATE-BY-ADMIN',p_id_admin,'ADMIN',
               CONCAT('lokasi_baru=',p_id_lokasi_baru,'; kondisi_baru=',v_kondisi));
        COMMIT;
        SELECT 'OK' AS message;
      END IF;
    END IF;
END$$

CREATE PROCEDURE hapus_dispenser_by_admin(IN p_id_admin INT, IN p_id_dispenser INT)
BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  START TRANSACTION;
    DELETE FROM dispenser WHERE id_dispenser=p_id_dispenser;
    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('dispenser',p_id_dispenser,'FAILED-DELETE',p_id_admin,'ADMIN');
      SELECT 'ERROR: dispenser tidak ditemukan' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor)
      VALUES('dispenser',p_id_dispenser,'DELETE-BY-ADMIN',p_id_admin,'ADMIN');
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END$$

CREATE PROCEDURE tambah_dispenser_by_lokasi(
  IN p_id_admin INT, IN p_id_lokasi INT, IN p_kondisi VARCHAR(20)
)
proc: BEGIN
  DECLARE _err BOOL DEFAULT FALSE;
  DECLARE v_kondisi ENUM('AKTIF','RUSAK','PERBAIKAN');

  SET p_kondisi = UPPER(TRIM(p_kondisi));
  IF p_kondisi NOT IN ('AKTIF','RUSAK','PERBAIKAN') THEN
    SELECT 'ERROR: kondisi harus AKTIF/RUSAK/PERBAIKAN' AS message;
    LEAVE proc;
  END IF;

  SET v_kondisi = p_kondisi;

  START TRANSACTION;
    INSERT INTO dispenser(id_lokasi,kondisi,created_at,updated_at)
    VALUES(p_id_lokasi,v_kondisi,NOW(),NOW());
    IF ROW_COUNT()=0 THEN SET _err=TRUE; END IF;

    IF _err THEN
      ROLLBACK;
      INSERT INTO log_aktivitas(tabel,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('dispenser','FAILED-INSERT',p_id_admin,'ADMIN',CONCAT('lokasi_id=',p_id_lokasi,'; kondisi=',v_kondisi));
      SELECT 'ERROR: gagal tambah dispenser' AS message;
    ELSE
      INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
      VALUES('dispenser',LAST_INSERT_ID(),'INSERT-BY-ADMIN',p_id_admin,'ADMIN',
             CONCAT('lokasi_id=',p_id_lokasi,'; kondisi=',v_kondisi));
      COMMIT;
      SELECT 'OK' AS message;
    END IF;
END proc$$

DELIMITER $$
CREATE TRIGGER trg_bu_pegawai BEFORE UPDATE ON pegawai
FOR EACH ROW BEGIN
  SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_ai_pegawai AFTER INSERT ON pegawai
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('pegawai',NEW.id_pegawai,'INSERT',CONCAT('username=',NEW.username));
END$$

CREATE TRIGGER trg_au_pegawai AFTER UPDATE ON pegawai
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('pegawai',NEW.id_pegawai,'UPDATE',CONCAT('username=',NEW.username));
END$$

CREATE TRIGGER trg_ad_pegawai AFTER DELETE ON pegawai
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('pegawai',OLD.id_pegawai,'DELETE',CONCAT('username=',OLD.username));
END$$

CREATE TRIGGER trg_bu_lokasi BEFORE UPDATE ON lokasi
FOR EACH ROW BEGIN
  SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_ai_lokasi AFTER INSERT ON lokasi
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('lokasi',NEW.id_lokasi,'INSERT',CONCAT('nama=',NEW.nama_lokasi,'; area=',NEW.lokasi));
END$$

CREATE TRIGGER trg_au_lokasi AFTER UPDATE ON lokasi
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('lokasi',NEW.id_lokasi,'UPDATE',CONCAT('nama=',NEW.nama_lokasi,'; area=',NEW.lokasi));
END$$

CREATE TRIGGER trg_ad_lokasi AFTER DELETE ON lokasi
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('lokasi',OLD.id_lokasi,'DELETE',CONCAT('nama=',OLD.nama_lokasi,'; area=',OLD.lokasi));
END$$

CREATE TRIGGER trg_bu_dispenser BEFORE UPDATE ON dispenser
FOR EACH ROW BEGIN
  SET NEW.updated_at = NOW();
END$$

CREATE TRIGGER trg_ai_dispenser AFTER INSERT ON dispenser
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('dispenser',NEW.id_dispenser,'INSERT',CONCAT('lokasi_id=',NEW.id_lokasi,'; kondisi=',NEW.kondisi));
END$$

CREATE TRIGGER trg_au_dispenser AFTER UPDATE ON dispenser
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('dispenser',NEW.id_dispenser,'UPDATE',CONCAT('lokasi_id=',NEW.id_lokasi,'; kondisi=',NEW.kondisi));
END$$

CREATE TRIGGER trg_ad_dispenser AFTER DELETE ON dispenser
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('dispenser',OLD.id_dispenser,'DELETE',CONCAT('lokasi_id=',OLD.id_lokasi,'; kondisi=',OLD.kondisi));
END$$

CREATE TRIGGER trg_ai_login AFTER INSERT ON login
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
  VALUES('login',NEW.id_login,'LOGIN',
         IFNULL(NEW.id_admin,NEW.id_pegawai),
         IF(NEW.id_admin IS NOT NULL,'ADMIN','PEGAWAI'),
         'user login');
END$$

CREATE TRIGGER trg_ai_laporan AFTER INSERT ON laporan_penggantian
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,id_aktor,tipe_aktor,keterangan)
  VALUES('laporan_penggantian',NEW.id_laporan,'INSERT',NEW.id_pegawai,'PEGAWAI',
         CONCAT('dispenser_id=',NEW.id_dispenser,'; jumlah=',NEW.jumlah_tisu));
END$$

CREATE TRIGGER trg_au_laporan AFTER UPDATE ON laporan_penggantian
FOR EACH ROW BEGIN
  INSERT INTO log_aktivitas(tabel,id_referensi,aksi,keterangan)
  VALUES('laporan_penggantian',NEW.id_laporan,'UPDATE',
         CONCAT('dispenser_id=',NEW.id_dispenser,'; jumlah=',NEW.jumlah_tisu));
END$$