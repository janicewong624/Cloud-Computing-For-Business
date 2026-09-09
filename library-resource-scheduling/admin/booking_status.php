<?php
require '../config.php';
require '../auth.php';
require_admin();

$allowedStatuses = ['pending', 'confirmed', 'done'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = (int)$_POST['id'];
    $status = $_POST['status'] ?? '';

    if (in_array($status, $allowedStatuses, true)) {
        $stmt = $conn->prepare('UPDATE bookings SET status = ? WHERE id = ?');
        $stmt->bind_param('si', $status, $id);
        $stmt->execute();
        $stmt->close();
    }
}

header('Location: bookings.php');
exit;