<?php
require '../config.php';
require '../auth.php';
require_admin();

$allowedTransitions = [
    'pending'   => 'confirmed',
    'confirmed' => 'done',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = (int)$_POST['id'];

    $stmt = $conn->prepare('SELECT status FROM bookings WHERE id = ?');
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $booking = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($booking && isset($allowedTransitions[$booking['status']])) {
        $nextStatus = $allowedTransitions[$booking['status']];
        $stmt = $conn->prepare('UPDATE bookings SET status = ? WHERE id = ?');
        $stmt->bind_param('si', $nextStatus, $id);
        $stmt->execute();
        $stmt->close();
    }
}

header('Location: bookings.php');
exit;