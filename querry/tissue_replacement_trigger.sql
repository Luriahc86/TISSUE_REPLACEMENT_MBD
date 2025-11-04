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