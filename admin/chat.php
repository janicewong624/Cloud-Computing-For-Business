<?php
require '../config.php';
require '../auth.php';
require '../helpers.php';
require_admin();

$threads = $conn->query("
    SELECT u.id, u.name, u.email,
        (SELECT cm2.message FROM chat_messages cm2 WHERE cm2.user_id = u.id ORDER BY cm2.id DESC LIMIT 1) AS last_message,
        (SELECT cm3.created_at FROM chat_messages cm3 WHERE cm3.user_id = u.id ORDER BY cm3.id DESC LIMIT 1) AS last_time,
        (SELECT COUNT(*) FROM chat_messages cm4 WHERE cm4.user_id = u.id AND cm4.sender_role = 'user' AND cm4.read_by_admin = 0) AS unread_count
    FROM users u
    WHERE EXISTS (SELECT 1 FROM chat_messages cm WHERE cm.user_id = u.id)
    ORDER BY last_time DESC
")->fetch_all(MYSQLI_ASSOC);

$selectedUserId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($threads[0]['id'] ?? 0);

$messages = [];
$selectedUser = null;
if ($selectedUserId) {
    foreach ($threads as $t) {
        if ((int)$t['id'] === $selectedUserId) { $selectedUser = $t; break; }
    }

    if ($selectedUser) {
        // Opening this thread means the admin has now seen every user
        // message in it.
        $conn->query("UPDATE chat_messages SET read_by_admin = 1 WHERE user_id = $selectedUserId AND sender_role = 'user' AND read_by_admin = 0");

        $stmt = $conn->prepare('SELECT id, sender_role, message, created_at FROM chat_messages WHERE user_id = ? ORDER BY id ASC');
        $stmt->bind_param('i', $selectedUserId);
        $stmt->execute();
        $messages = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();
    }
}

$pageTitle = 'Live Chat';
require 'partials/header.php';
?>
<h1>Live Chat</h1>

<?php if (empty($threads)): ?>
<div class="empty-state">
<div class="empty-state-icon">&#128172;</div>
<p>No conversations yet. Threads appear here once a user sends a message from the Live Chat page.</p>
</div>
<?php else: ?>
<div class="chat-layout">
<div class="chat-thread-list">
<?php foreach ($threads as $t): ?>
<a class="chat-thread-item <?= (int)$t['id'] === $selectedUserId ? 'active' : '' ?>" href="chat.php?user_id=<?= (int)$t['id'] ?>">
<span class="chat-thread-name"><?= htmlspecialchars($t['name']) ?><?php if ((int)$t['unread_count'] > 0): ?> <span class="chat-badge"><?= (int)$t['unread_count'] ?></span><?php endif; ?></span>
<span class="chat-thread-preview"><?= htmlspecialchars(mb_substr($t['last_message'], 0, 60)) ?><?= mb_strlen($t['last_message']) > 60 ? '…' : '' ?></span>
</a>
<?php endforeach; ?>
</div>

<div class="chat-thread-main">
<?php if ($selectedUser): ?>
<h2><?= htmlspecialchars($selectedUser['name']) ?> <span class="stat-subtext"><?= htmlspecialchars($selectedUser['email']) ?></span></h2>

<div class="chat-window" id="chat-window" data-user-id="<?= (int)$selectedUserId ?>" data-last-id="<?= !empty($messages) ? (int)end($messages)['id'] : 0 ?>">
<?php foreach ($messages as $m): ?>
<div class="chat-message <?= $m['sender_role'] === 'admin' ? 'chat-mine' : 'chat-theirs' ?>" data-id="<?= (int)$m['id'] ?>">
<div class="chat-bubble">
<span class="chat-sender"><?= $m['sender_role'] === 'admin' ? 'You (Staff)' : htmlspecialchars($selectedUser['name']) ?></span>
<p><?= nl2br(htmlspecialchars($m['message'])) ?></p>
<span class="chat-time"><?= htmlspecialchars(date('M j, g:i A', strtotime($m['created_at']))) ?></span>
</div>
</div>
<?php endforeach; ?>
</div>

<form id="chat-form" class="chat-input-bar">
<textarea id="chat-input" placeholder="Reply as library staff..." maxlength="1000" required></textarea>
<button type="submit" class="btn">Send</button>
</form>
<p id="chat-error" class="alert alert-error" style="display:none;"></p>
<?php endif; ?>
</div>
</div>

<script>
(function () {
    var windowEl = document.getElementById('chat-window');
    if (!windowEl) return;
    var userId = windowEl.getAttribute('data-user-id');
    var form = document.getElementById('chat-form');
    var input = document.getElementById('chat-input');
    var errorEl = document.getElementById('chat-error');

    function scrollToBottom() {
        windowEl.scrollTop = windowEl.scrollHeight;
    }
    scrollToBottom();

    function escapeHtml(str) {
        var div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    function appendMessage(m) {
        var wrap = document.createElement('div');
        wrap.className = 'chat-message ' + (m.sender_role === 'admin' ? 'chat-mine' : 'chat-theirs');
        wrap.setAttribute('data-id', m.id);
        wrap.innerHTML =
            '<div class="chat-bubble">' +
            '<span class="chat-sender">' + (m.sender_role === 'admin' ? 'You (Staff)' : escapeHtml(m.sender_name || 'User')) + '</span>' +
            '<p>' + escapeHtml(m.message).replace(/\n/g, '<br>') + '</p>' +
            '<span class="chat-time">' + escapeHtml(m.created_at_label) + '</span>' +
            '</div>';
        windowEl.appendChild(wrap);
        windowEl.setAttribute('data-last-id', m.id);
    }

    function poll() {
        var afterId = windowEl.getAttribute('data-last-id') || 0;
        fetch('chat_poll.php?user_id=' + encodeURIComponent(userId) + '&after_id=' + encodeURIComponent(afterId))
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data.messages && data.messages.length) {
                    data.messages.forEach(appendMessage);
                    scrollToBottom();
                }
            })
            .catch(function () { /* silent - will retry on next poll */ });
    }

    setInterval(poll, 3000);

    form.addEventListener('submit', function (e) {
        e.preventDefault();
        var text = input.value.trim();
        if (!text) return;

        errorEl.style.display = 'none';
        var sendBtn = form.querySelector('button');
        sendBtn.disabled = true;

        fetch('chat_send.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'user_id=' + encodeURIComponent(userId) + '&message=' + encodeURIComponent(text),
        })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                sendBtn.disabled = false;
                if (data.success) {
                    appendMessage(data.message);
                    scrollToBottom();
                    input.value = '';
                } else {
                    errorEl.textContent = data.error || 'Could not send message.';
                    errorEl.style.display = 'block';
                }
            })
            .catch(function () {
                sendBtn.disabled = false;
                errorEl.textContent = 'Network error - please try again.';
                errorEl.style.display = 'block';
            });
    });
})();
</script>
<?php endif; ?>

<?php require 'partials/footer.php'; ?>