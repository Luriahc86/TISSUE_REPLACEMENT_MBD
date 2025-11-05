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
        SELECT 'laporan berhasil di buat' AS message;
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
    SELECT 'Login berhasil' AS message, v_id AS id_admin;
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
    SELECT 'Login berhasil' AS message, v_id AS id_pegawai;
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
      SELECT 'berhasil menambahkan pegawai' AS message;
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
      SELECT 'pegawai berhasil di update' AS message;
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
      SELECT 'pegawai berhasil di hapus' AS message;
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
      SELECT 'lokasi berhasil ditambahkan' AS message, v_id AS id_lokasi;
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
      SELECT 'lokasi berhasil di update' AS message;
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
      SELECT 'lokasi berhasil di hapus' AS message;
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
        SELECT 'dispenser berhasil di update' AS message;
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
      SELECT 'dispenser berhasil di hapus' AS message;
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
      SELECT 'dispenser berhasil di tambahkan' AS message;
    END IF;
END proc$$