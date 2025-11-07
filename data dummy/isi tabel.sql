INSERT INTO admin (username, password)
VALUES
('apong', 'admin123'),
('bima', 'admin123'),
('ata', 'admin123'),
('raka', 'admin123');

INSERT INTO pegawai (username, password)
VALUES
('rei', 'pegawai123'),
('luri', 'pegawai123'),
('faisal', 'pegawai123'),
('noel', 'pegawai123');

INSERT INTO lokasi (nama_lokasi, lokasi, deskripsi)
VALUES
('Kantor Pusat', 'Balikpapan Tengah', 'Dispenser utama kantor pusat'),
('Mall E-Walk', 'Balikpapan Selatan', 'Dispenser area umum mall E-Walk'),
('RSUD Kanudjoso', 'Balikpapan Utara', 'Dispenser area rumah sakit'),
('Stadion Batakan', 'Balikpapan Selatan', 'Dispenser di ruang ganti pemain');

INSERT INTO dispenser (id_lokasi, kondisi)
VALUES
(1, 'AKTIF'),
(1, 'RUSAK'),
(2, 'PERBAIKAN'),
(3, 'AKTIF'),
(4, 'AKTIF');

INSERT INTO laporan_penggantian (id_dispenser, id_pegawai, jumlah_tisu, keterangan)
VALUES
(1, 1, 30, 'Isi ulang dispenser utama kantor pusat'),
(2, 2, 25, 'Perbaikan dan isi ulang dispenser rusak'),
(3, 3, 40, 'Penggantian tisu rutin di area mall E-Walk'),
(4, 4, 20, 'Isi ulang tisu di rumah sakit Kanudjoso'),
(5, 1, 35, 'Pengecekan rutin dispenser stadion Batakan');

INSERT INTO login (id_admin, id_pegawai)
VALUES
(1, NULL),  
(2, NULL),  
(NULL, 1),  
(NULL, 2),  
(NULL, 3),  
(NULL, 4); 