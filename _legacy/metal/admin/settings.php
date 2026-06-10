<?php
// metal/admin/settings.php
require_once __DIR__ . '/../includes/auth.php';
requireAdminLogin();
require_once __DIR__ . '/../includes/db.php';

function get_setting($k, $fallback='') {
  global $conn;
  $stmt = $conn->prepare("SELECT v FROM settings WHERE k=? LIMIT 1");
  $stmt->bind_param('s', $k);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return $row ? $row['v'] : $fallback;
}

$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $api_key = trim($_POST['api_key'] ?? '');
  $def_cur = strtoupper(trim($_POST['default_currency'] ?? 'PKR'));
  $tz      = trim($_POST['timezone'] ?? 'Asia/Karachi');

  if (!in_array($def_cur, APP_CURRENCIES, true)) $def_cur = 'PKR';

  $stmt = $conn->prepare("
    REPLACE INTO settings (k, v) VALUES
      ('api_key', ?),
      ('default_currency', ?),
      ('timezone', ?)
  ");
  $stmt->bind_param('sss', $api_key, $def_cur, $tz);
  $stmt->execute();
  $msg = 'Saved.';
}

$api_key = get_setting('api_key', '');
$def_cur = get_setting('default_currency', 'PKR');
$tz      = get_setting('timezone', 'Asia/Karachi');
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Settings - Metal Admin</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
  <style>nav a{margin-right:1rem}</style>
</head>
<body class="container">
<nav>
  <a href="index.php">Dashboard</a>
  <strong>Settings</strong>
  <a href="logout.php">Logout</a>
</nav>

<main>
  <h2>Settings</h2>
  <?php if ($msg): ?><mark><?=$msg?></mark><?php endif; ?>

  <form method="post">
    <label>License
      <input name="api_key" value="<?=htmlspecialchars($api_key)?>" required>
    </label>

    <label>Default Currency
      <select name="default_currency">
        <?php foreach (APP_CURRENCIES as $c): ?>
          <option value="<?=$c?>" <?=$def_cur===$c?'selected':''?>><?=$c?></option>
        <?php endforeach; ?>
      </select>
    </label>

    <label>Timezone
      <input name="timezone" value="<?=htmlspecialchars($tz)?>" placeholder="Asia/Karachi">
    </label>

    <button type="submit">Save</button>
  </form>

  <small>Tip: Do not <code>Touch, Edit</code> or <code>Change</code> Settings.</small>
</main>
</body>
</html>
