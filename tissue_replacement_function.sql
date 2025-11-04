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