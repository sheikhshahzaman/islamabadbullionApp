<?php
// metal/admin/reset_admin.php
// OPTIONAL: Delete this file after you successfully reset password.

declare(strict_types=1);
require_once __DIR__ . '/../includes/db.php';

const RESET_SECRET = 'CHANGE_THIS_TO_A_RANDOM_LONG_STRING';

if (!isset($_GET['secret']) || $_GET['secret'] !== RESET_SECRET) {
  http_response_code(403);
  echo "Forbidden. Add ?secret=YOUR_SECRET and change RESET_SECRET in this file first.";
  exit;
}

$msg = '';
$err = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $username = trim($_POST['username'] ?? '');
  $password = trim($_POST['password'] ?? '');

  if ($username === '' || $password === '') {
    $err = 'Username & password required.';
  } elseif (strlen($password) < 8) {
    $err = 'Password must be at least 8 characters.';
  } else {
    $hash = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $conn->prepare("
      INSERT INTO admins (username, password_hash)
      VALUES (?,?)
      ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash)
    ");
    $stmt->bind_param('ss', $username, $hash);
    if ($stmt->execute()) $msg = "Updated admin '$username'. Now login and DELETE this file.";
    else $err = "DB error: " . $conn->error;
  }
}
?>
<!doctype html><html><head>
<meta charset="utf-8"><title>Reset Admin (Delete After)</title>
<meta name="robots" content="noindex">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
</head><body class="container">
<main style="max-width:520px;margin:3rem auto;">
  <h3>Reset Admin Password</h3>
  <?php if ($msg): ?><mark><?=$msg?></mark><?php endif; ?>
  <?php if ($err): ?><mark style="background:#ffe6e6"><?=$err?></mark><?php endif; ?>
  <form method="post">
    <label>Username <input name="username" required value="admin"></label>
    <label>New Password <input type="password" name="password" required></label>
    <button type="submit">Save</button>
  </form>
  <p><strong>Important:</strong> delete this file after use.</p>
</main>
</body></html>
