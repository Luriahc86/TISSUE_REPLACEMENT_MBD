<?php
// ===================================================
// CONFIG
// ===================================================
$config = json_decode(file_get_contents("config.json"), true);
$db = $config["database"];

// ===================================================
// KONEKSI DATABASE
// ===================================================
$conn = new mysqli($db["host"], $db["cleaning_system"], $db["password"], $db["dbname"]);
if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}
$conn->set_charset($db["charset"]);

// ===================================================
// QUERY DATA (contoh: ambil laporan penggantian terbaru)
// ===================================================
$sql = "SELECT * FROM v_laporan_penggantian ORDER BY waktu DESC LIMIT 10";
$result = $conn->query($sql);

// ===================================================
// TAMPILKAN DATA
// ===================================================
?>
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Cleaning System Dashboard</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
  <div class="container py-5">
    <h1 class="mb-4 text-center">🧼 Cleaning System Dashboard</h1>

    <div class="card shadow">
      <div class="card-header bg-primary text-white">
        <h5 class="mb-0">Laporan Penggantian Terbaru</h5>
      </div>
      <div class="card-body">
        <table class="table table-striped table-bordered align-middle">
          <thead class="table-dark">
            <tr>
              <th>ID</th>
              <th>Pegawai</th>
              <th>Lokasi</th>
              <th>Jumlah Tisu</th>
              <th>Keterangan</th>
              <th>Waktu</th>
            </tr>
          </thead>
          <tbody>
            <?php if ($result->num_rows > 0): ?>
              <?php while($row = $result->fetch_assoc()): ?>
                <tr>
                  <td><?= htmlspecialchars($row['id_laporan']) ?></td>
                  <td><?= htmlspecialchars($row['nama_pegawai']) ?></td>
                  <td><?= htmlspecialchars($row['nama_lokasi']) ?> (<?= htmlspecialchars($row['area']) ?>)</td>
                  <td><?= htmlspecialchars($row['jumlah_tisu']) ?></td>
                  <td><?= htmlspecialchars($row['keterangan']) ?></td>
                  <td><?= htmlspecialchars($row['waktu']) ?></td>
                </tr>
              <?php endwhile; ?>
            <?php else: ?>
              <tr><td colspan="6" class="text-center text-muted">Belum ada data laporan</td></tr>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </div>

    <p class="text-center mt-4 text-secondary">© <?= date('Y') ?> Cleaning System - Infinite 2024</p>
  </div>
</body>
</html>
<?php
$conn->close();
?>
