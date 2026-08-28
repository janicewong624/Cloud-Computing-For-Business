<?php
require 'config.php';
require 'auth.php';
require_login();

header('Content-Type: application/json');

$uid = current_user_id();
$afterId = (int)($_GET['after_id'] ?? 0);

$stmt = $conn->prepare('SELECT id, sender_role, message, created_at FROM chat_messages WHERE user_id = ? AND id > ? ORDER BY id ASC');
$stmt->bind_param('ii', $uid, $afterId);
$stmt->execute();
$rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

// Polling this thread counts as reading any admin replies that arrived.
$conn->query("UPDATE chat_messages SET read_by_user = 1 WHERE user_id = $uid AND sender_role = 'admin' AND read_by_user = 0");

$messages = array_map(function ($row) {
    return [
        'id' => (int)$row['id'],
        'sender_role' => $row['sender_role'],
        'message' => $row['message'],
        'created_at_label' => date('M j, g:i A', strtotime($row['created_at'])),
    ];
}, $rows);

echo json_encode(['messages' => $messages]);