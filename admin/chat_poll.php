<?php
require '../config.php';
require '../auth.php';
require_admin();

header('Content-Type: application/json');

$targetUserId = (int)($_GET['user_id'] ?? 0);
$afterId = (int)($_GET['after_id'] ?? 0);

if ($targetUserId <= 0) {
    echo json_encode(['messages' => []]);
    exit;
}

$stmt = $conn->prepare('
    SELECT cm.id, cm.sender_role, cm.message, cm.created_at, u.name AS sender_name
    FROM chat_messages cm
    JOIN users u ON u.id = cm.sender_id
    WHERE cm.user_id = ? AND cm.id > ?
    ORDER BY cm.id ASC
');
$stmt->bind_param('ii', $targetUserId, $afterId);
$stmt->execute();
$rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

// Polling this thread counts as reading any user messages that arrived.
$conn->query("UPDATE chat_messages SET read_by_admin = 1 WHERE user_id = $targetUserId AND sender_role = 'user' AND read_by_admin = 0");

$messages = array_map(function ($row) {
    return [
        'id' => (int)$row['id'],
        'sender_role' => $row['sender_role'],
        'sender_name' => $row['sender_name'],
        'message' => $row['message'],
        'created_at_label' => date('M j, g:i A', strtotime($row['created_at'])),
    ];
}, $rows);

echo json_encode(['messages' => $messages]);