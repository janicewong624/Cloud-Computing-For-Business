<?php
require '../config.php';
require '../auth.php';
require '../helpers.php';
require_admin();

// ---- Stat tile 1: Total bookings across all three resource types ----
$totalRoomBookings = (int)$conn->query('SELECT COUNT(*) c FROM bookings')->fetch_assoc()['c'];
$totalEquipmentLoans = (int)$conn->query('SELECT COUNT(*) c FROM equipment_loans')->fetch_assoc()['c'];
$totalBookLoans = (int)$conn->query('SELECT COUNT(*) c FROM book_loans')->fetch_assoc()['c'];
$totalBookings = $totalRoomBookings + $totalEquipmentLoans + $totalBookLoans;

// ---- Stat tile 2: Total revenue (fines actually collected) ----
$totalRevenue = 0.0;

$paidEquipmentFines = $conn->query('SELECT loan_date, time_slot, returned_at FROM equipment_loans WHERE fine_paid_at IS NOT NULL');
while ($row = $paidEquipmentFines->fetch_assoc()) {
    $totalRevenue += equipment_fine_amount($row['loan_date'], $row['time_slot'], $row['returned_at']);
}

$paidBookFines = $conn->query('SELECT due_date, returned_at FROM book_loans WHERE fine_paid_at IS NOT NULL');
while ($row = $paidBookFines->fetch_assoc()) {
    $totalRevenue += book_fine_amount($row['due_date'], $row['returned_at']);
}

// ---- Stat tile 3: Busiest resource (highest booking/loan count, any type) ----
$busiestRoom = $conn->query('
    SELECT r.room_name AS name, COUNT(*) AS cnt
    FROM bookings b JOIN rooms r ON r.id = b.room_id
    GROUP BY b.room_id ORDER BY cnt DESC LIMIT 1
')->fetch_assoc();

$busiestEquipment = $conn->query('
    SELECT e.equipment_name AS name, COUNT(*) AS cnt
    FROM equipment_loans l JOIN equipment e ON e.id = l.equipment_id
    GROUP BY l.equipment_id ORDER BY cnt DESC LIMIT 1
')->fetch_assoc();

$busiestBook = $conn->query('
    SELECT bk.title AS name, COUNT(*) AS cnt
    FROM book_loans bl JOIN books bk ON bk.id = bl.book_id
    GROUP BY bl.book_id ORDER BY cnt DESC LIMIT 1
')->fetch_assoc();

$busiestCandidates = array_filter([
    $busiestRoom      ? ['label' => $busiestRoom['name'],      'type' => 'Room',      'cnt' => (int)$busiestRoom['cnt']]      : null,
    $busiestEquipment ? ['label' => $busiestEquipment['name'], 'type' => 'Equipment', 'cnt' => (int)$busiestEquipment['cnt']] : null,
    $busiestBook      ? ['label' => $busiestBook['name'],      'type' => 'Book',      'cnt' => (int)$busiestBook['cnt']]      : null,
]);
usort($busiestCandidates, fn($a, $b) => $b['cnt'] <=> $a['cnt']);
$busiest = $busiestCandidates[0] ?? null;

// ---- Stat tile 4: Bookings made today, across all three types ----
$bookingsToday = (int)$conn->query("SELECT COUNT(*) c FROM bookings WHERE booking_date = CURDATE()")->fetch_assoc()['c'];
$loansToday    = (int)$conn->query("SELECT COUNT(*) c FROM equipment_loans WHERE loan_date = CURDATE()")->fetch_assoc()['c'];
$bookLoansToday = (int)$conn->query("SELECT COUNT(*) c FROM book_loans WHERE checkout_date = CURDATE()")->fetch_assoc()['c'];
$activityToday = $bookingsToday + $loansToday + $bookLoansToday;

// ---- Chart: last 30 days, broken down per resource type ----
$days = 30;
$startDate = date('Y-m-d', strtotime("-" . ($days - 1) . " days"));

$labels = [];
$roomSeries = [];
$equipmentSeries = [];
$bookSeries = [];
for ($i = 0; $i < $days; $i++) {
    $d = date('Y-m-d', strtotime($startDate . " +$i days"));
    $labels[$d] = date('M j', strtotime($d));
    $roomSeries[$d] = 0;
    $equipmentSeries[$d] = 0;
    $bookSeries[$d] = 0;
}

$stmt = $conn->prepare('SELECT booking_date d, COUNT(*) c FROM bookings WHERE booking_date >= ? GROUP BY booking_date');
$stmt->bind_param('s', $startDate);
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    if (isset($roomSeries[$row['d']])) $roomSeries[$row['d']] = (int)$row['c'];
}
$stmt->close();

$stmt = $conn->prepare('SELECT loan_date d, COUNT(*) c FROM equipment_loans WHERE loan_date >= ? GROUP BY loan_date');
$stmt->bind_param('s', $startDate);
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    if (isset($equipmentSeries[$row['d']])) $equipmentSeries[$row['d']] = (int)$row['c'];
}
$stmt->close();

$stmt = $conn->prepare('SELECT checkout_date d, COUNT(*) c FROM book_loans WHERE checkout_date >= ? GROUP BY checkout_date');
$stmt->bind_param('s', $startDate);
$stmt->execute();
$res = $stmt->get_result();
while ($row = $res->fetch_assoc()) {
    if (isset($bookSeries[$row['d']])) $bookSeries[$row['d']] = (int)$row['c'];
}
$stmt->close();

$chartLabels = array_values($labels);
$chartRoomData = array_values($roomSeries);
$chartEquipmentData = array_values($equipmentSeries);
$chartBookData = array_values($bookSeries);

$pageTitle = 'Admin Dashboard';
require 'partials/header.php';
?>
<h1>Dashboard</h1>

<div class="stat-grid">
<div class="stat-tile">
<span class="stat-label">Total Bookings</span>
<span class="stat-value"><?= number_format($totalBookings) ?></span>
<span class="stat-subtext"><?= number_format($totalRoomBookings) ?> rooms &middot; <?= number_format($totalEquipmentLoans) ?> equipment &middot; <?= number_format($totalBookLoans) ?> books</span>
</div>

<div class="stat-tile">
<span class="stat-label">Total Revenue (Fines Collected)</span>
<span class="stat-value">RM<?= number_format($totalRevenue, 2) ?></span>
<span class="stat-subtext">From paid overdue fines</span>
</div>

<div class="stat-tile">
<span class="stat-label">Busiest Resource</span>
<?php if ($busiest): ?>
<span class="stat-value" style="font-size:1.3rem;"><?= htmlspecialchars($busiest['label']) ?></span>
<span class="stat-subtext"><?= htmlspecialchars($busiest['type']) ?> &middot; <?= number_format($busiest['cnt']) ?> bookings</span>
<?php else: ?>
<span class="stat-value" style="font-size:1.3rem;">&mdash;</span>
<span class="stat-subtext">No bookings yet</span>
<?php endif; ?>
</div>

<div class="stat-tile">
<span class="stat-label">Bookings Today</span>
<span class="stat-value"><?= number_format($activityToday) ?></span>
<span class="stat-subtext"><?= number_format($bookingsToday) ?> rooms &middot; <?= number_format($loansToday) ?> equipment &middot; <?= number_format($bookLoansToday) ?> books</span>
</div>
</div>

<div class="chart-card">
<h2>Bookings Over Time (Last 30 Days)</h2>
<canvas id="bookingsChart"></canvas>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.4/chart.umd.min.js"></script>
<script>
(function () {
    var ctx = document.getElementById('bookingsChart');
    if (!ctx || typeof Chart === 'undefined') return;

    var textColor = getComputedStyle(document.documentElement).getPropertyValue('--text').trim() || '#222';
    var gridColor = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#ddd';

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: <?= json_encode($chartLabels) ?>,
            datasets: [
                {
                    label: 'Room Bookings',
                    data: <?= json_encode($chartRoomData) ?>,
                    borderColor: '#2e8b57',
                    backgroundColor: 'rgba(46, 139, 87, 0.15)',
                    tension: 0.3,
                    fill: true,
                },
                {
                    label: 'Equipment Loans',
                    data: <?= json_encode($chartEquipmentData) ?>,
                    borderColor: '#e8843a',
                    backgroundColor: 'rgba(232, 132, 58, 0.15)',
                    tension: 0.3,
                    fill: true,
                },
                {
                    label: 'Book Loans',
                    data: <?= json_encode($chartBookData) ?>,
                    borderColor: '#1a5fb4',
                    backgroundColor: 'rgba(26, 95, 180, 0.15)',
                    tension: 0.3,
                    fill: true,
                },
            ],
        },
        options: {
            responsive: true,
            interaction: { mode: 'index', intersect: false },
            plugins: {
                legend: { labels: { color: textColor } },
            },
            scales: {
                x: { ticks: { color: textColor }, grid: { color: gridColor } },
                y: { beginAtZero: true, ticks: { color: textColor, precision: 0 }, grid: { color: gridColor } },
            },
        },
    });
})();
</script>

<?php require 'partials/footer.php'; ?>