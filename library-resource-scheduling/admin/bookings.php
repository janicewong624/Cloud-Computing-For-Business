<?php
require '../config.php';
require '../auth.php';
require '../helpers.php';
require_admin();

$bookings = $conn->query('
    SELECT b.id, r.room_name, b.booking_date, b.time_slot, b.purpose, b.status, u.name AS user_name, u.email AS user_email
    FROM bookings b
    JOIN rooms r ON r.id = b.room_id
    JOIN users u ON u.id = b.user_id
    ORDER BY b.booking_date DESC
')->fetch_all(MYSQLI_ASSOC);

$pageTitle = 'All Bookings';
require 'partials/header.php';
?>
<h1>All Bookings</h1>
<?php if (empty($bookings)): ?>
<div class="empty-state">
<div class="empty-state-icon">&#128197;</div>
<p>No bookings yet.</p>
</div>
<?php else: ?>
<table>
<tr><th>Room</th><th>Date</th><th>Time Slot</th><th>Purpose</th><th>Status</th><th>Booked By</th><th>Email</th><th>Actions</th></tr>
<?php foreach ($bookings as $b): ?>
<?php
$displayStatus = booking_display_status($b['status'], $b['booking_date'], $b['time_slot']);
$slotOver = $displayStatus === 'done' && $b['status'] !== 'done';
?>
<tr>
<td><?= htmlspecialchars($b['room_name']) ?></td>
<td><?= htmlspecialchars($b['booking_date']) ?></td>
<td><?= htmlspecialchars($b['time_slot']) ?></td>
<td><?= htmlspecialchars($b['purpose']) ?></td>
<td><span class="badge <?= booking_status_badge_class($displayStatus) ?>"><?= booking_status_label($displayStatus) ?></span></td>
<td><?= htmlspecialchars($b['user_name']) ?></td>
<td><?= htmlspecialchars($b['user_email']) ?></td>
<td>
<form action="booking_status.php" method="post" style="display:inline-flex; gap:6px; align-items:center;">
<input type="hidden" name="id" value="<?= (int)$b['id'] ?>">
<select name="status" style="padding:4px 6px;">
<option value="pending" <?= $b['status'] === 'pending' ? 'selected' : '' ?>>Pending</option>
<option value="confirmed" <?= $b['status'] === 'confirmed' ? 'selected' : '' ?>>Confirmed</option>
<option value="done" <?= $b['status'] === 'done' ? 'selected' : '' ?>>Done</option>
</select>
<button type="submit" class="btn-small btn-secondary">Update</button>
</form>
<form action="booking_cancel.php" method="post" style="display:inline" onsubmit="return confirm('Cancel this booking?');">
<input type="hidden" name="id" value="<?= (int)$b['id'] ?>">
<button type="submit" class="btn-small btn-danger">Cancel</button>
</form>
<?php if ($slotOver): ?>
<div class="form-hint">Slot has passed &mdash; shown as Done.</div>
<?php endif; ?>
</td>
</tr>
<?php endforeach; ?>
</table>
<?php endif; ?>
<?php require 'partials/footer.php'; ?>
