<?php
require 'config.php';
require 'auth.php';
require_login();

header('Content-Type: application/json');

$uid = current_user_id();
$message = trim($_POST['message'] ?? '');

if ($message === '') {
    echo json_encode(['success' => false, 'error' => 'Message cannot be empty.']);
    exit;
}
if (mb_strlen($message) > 1000) {
    echo json_encode(['success' => false, 'error' => 'Message is too long (max 1000 characters).']);
    exit;
}

// A user's own message is, by definition, already "read" by them - only the
// admin side needs to catch up on it.
$stmt = $conn->prepare("INSERT INTO chat_messages (user_id, sender_role, sender_id, message, read_by_user, read_by_admin) VALUES (?, 'user', ?, ?, 1, 0)");
$stmt->bind_param('iis', $uid, $uid, $message);
$stmt->execute();
$newId = $stmt->insert_id;
$stmt->close();

$stmt = $conn->prepare('SELECT id, sender_role, message, created_at FROM chat_messages WHERE id = ?');
$stmt->bind_param('i', $newId);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

echo json_encode([
    'success' => true,
    'message' => [
        'id' => (int)$row['id'],
        'sender_role' => $row['sender_role'],
        'message' => $row['message'],
        'created_at_label' => date('M j, g:i A', strtotime($row['created_at'])),
    ],
]);