<?php
require 'config.php';
require 'auth.php';
require 'helpers.php';
require_login();

$uid = current_user_id();

// Opening the thread means you've seen every admin reply in it so far.
$conn->query("UPDATE chat_messages SET read_by_user = 1 WHERE user_id = $uid AND sender_role = 'admin' AND read_by_user = 0");

$stmt = $conn->prepare('SELECT id, sender_role, message, created_at FROM chat_messages WHERE user_id = ? ORDER BY id ASC');
$stmt->bind_param('i', $uid);
$stmt->execute();
$messages = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
$stmt->close();

$pageTitle = 'Live Chat with Library Staff';
require 'partials/header.php';
?>
<h1>Live Chat with Library Staff</h1>
<p>Ask a question about bookings, loans, or fines. A staff member will reply here as soon as they're available.</p>

<div class="chat-window" id="chat-window" data-last-id="<?= !empty($messages) ? (int)end($messages)['id'] : 0 ?>">
<?php if (empty($messages)): ?>
<p class="chat-empty-hint">No messages yet - say hello to get started!</p>
<?php endif; ?>
<?php foreach ($messages as $m): ?>
<div class="chat-message <?= $m['sender_role'] === 'user' ? 'chat-mine' : 'chat-theirs' ?>" data-id="<?= (int)$m['id'] ?>">
<div class="chat-bubble">
<span class="chat-sender"><?= $m['sender_role'] === 'user' ? 'You' : 'Library Staff' ?></span>
<p><?= nl2br(htmlspecialchars($m['message'])) ?></p>
<span class="chat-time"><?= htmlspecialchars(date('M j, g:i A', strtotime($m['created_at']))) ?></span>
</div>
</div>
<?php endforeach; ?>
</div>

<form id="chat-form" class="chat-input-bar">
<textarea id="chat-input" placeholder="Type your message..." maxlength="1000" required></textarea>
<button type="submit" class="btn">Send</button>
</form>
<p id="chat-error" class="alert alert-error" style="display:none;"></p>

<script>
(function () {
    var windowEl = document.getElementById('chat-window');
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
        var emptyHint = windowEl.querySelector('.chat-empty-hint');
        if (emptyHint) emptyHint.remove();

        var wrap = document.createElement('div');
        wrap.className = 'chat-message ' + (m.sender_role === 'user' ? 'chat-mine' : 'chat-theirs');
        wrap.setAttribute('data-id', m.id);
        wrap.innerHTML =
            '<div class="chat-bubble">' +
            '<span class="chat-sender">' + (m.sender_role === 'user' ? 'You' : 'Library Staff') + '</span>' +
            '<p>' + escapeHtml(m.message).replace(/\n/g, '<br>') + '</p>' +
            '<span class="chat-time">' + escapeHtml(m.created_at_label) + '</span>' +
            '</div>';
        windowEl.appendChild(wrap);
        windowEl.setAttribute('data-last-id', m.id);
    }

    function poll() {
        var afterId = windowEl.getAttribute('data-last-id') || 0;
        fetch('chat_poll.php?after_id=' + encodeURIComponent(afterId))
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
            body: 'message=' + encodeURIComponent(text),
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

<?php require 'partials/footer.php'; ?>