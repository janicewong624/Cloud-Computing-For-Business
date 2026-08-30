<?php
require '../config.php';
require '../auth.php';
require_admin();

header('Content-Type: application/json');

$adminId = current_user_id();
$targetUserId = (int)($_POST['user_id'] ?? 0);
$message = trim($_POST['message'] ?? '');

if ($targetUserId <= 0) {
    echo json_encode(['success' => false, 'error' => 'No conversation selected.']);
    exit;
}
if ($message === '') {
    echo json_encode(['success' => false, 'error' => 'Message cannot be empty.']);
    exit;
}
if (mb_strlen($message) > 1000) {
    echo json_encode(['success' => false, 'error' => 'Message is too long (max 1000 characters).']);
    exit;
}

// Make sure the thread's owner is a real user before writing to it.
$stmt = $conn->prepare('SELECT id FROM users WHERE id = ?');
$stmt->bind_param('i', $targetUserId);
$stmt->execute();
$exists = $stmt->get_result()->fetch_assoc();
$stmt->close();
if (!$exists) {
    echo json_encode(['success' => false, 'error' => 'That user no longer exists.']);
    exit;
}

// An admin's own reply is, by definition, already "read" by admin - only
// the user side needs to catch up on it.
$stmt = $conn->prepare("INSERT INTO chat_messages (user_id, sender_role, sender_id, message, read_by_user, read_by_admin) VALUES (?, 'admin', ?, ?, 0, 1)");
$stmt->bind_param('iis', $targetUserId, $adminId, $message);
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