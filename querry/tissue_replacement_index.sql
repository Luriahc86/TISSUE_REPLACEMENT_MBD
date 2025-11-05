CREATE INDEX idx_login_admin ON login(id_admin);
CREATE INDEX idx_login_pegawai ON login(id_pegawai);
CREATE INDEX idx_dispenser_lokasi ON dispenser(id_lokasi);
CREATE INDEX idx_lp_disp ON laporan_penggantian(id_dispenser);
CREATE INDEX idx_lp_peg ON laporan_penggantian(id_pegawai);
CREATE INDEX idx_lp_waktu ON laporan_penggantian(waktu);
