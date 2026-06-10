<?php
ini_set('display_errors', 1);
session_start();

// If you want login protection again, uncomment and match your session keys:
// if (!isset($_SESSION['user_id'])) { header("Location: login.php"); exit; }

require_once __DIR__ . '/../includes/db.php'; // your existing DB include

function h($s) { return htmlspecialchars($s ?? "", ENT_QUOTES, "UTF-8"); }

/**
 * Detect DB connection created by db.php.
 * Supports: PDO as $pdo, or mysqli as $conn/$con/$mysqli/$db/$connection/$link
 */
$pdo = $pdo ?? null;

$mysqli =
  ($mysqli ?? null)
  ?: ($conn ?? null)
  ?: ($con ?? null)
  ?: ($db ?? null)
  ?: ($connection ?? null)
  ?: ($link ?? null);

// Also support function-based connections if your db.php uses that style
if (!$pdo && !$mysqli) {
  foreach (["getPDO", "pdo", "db", "getDb", "getDB", "connectDb"] as $fn) {
    if (function_exists($fn)) {
      $tmp = $fn();
      if ($tmp instanceof PDO) { $pdo = $tmp; break; }
      if ($tmp instanceof mysqli) { $mysqli = $tmp; break; }
    }
  }
}

// Choose driver
$dbDriver = null;
if ($pdo instanceof PDO) {
  $dbDriver = "pdo";
} elseif ($mysqli instanceof mysqli) {
  $dbDriver = "mysqli";
  // ensure utf8mb4 for Urdu
  if (method_exists($mysqli, "set_charset")) {
    @$mysqli->set_charset("utf8mb4");
  }
} else {
  die("DB connection not found. Your includes/db.php must provide PDO (\$pdo) or mysqli (\$conn/\$con/\$mysqli).");
}

// Helper: mysqli bind_param with dynamic params (needs references)
function mysqli_bind_params(mysqli_stmt $stmt, string $types, array $params): void {
  $refs = [];
  foreach ($params as $k => $v) {
    $refs[$k] = &$params[$k];
  }
  array_unshift($refs, $types);
  call_user_func_array([$stmt, "bind_param"], $refs);
}

$err = "";
$ok  = "";

/* ------------------------- Handle actions ------------------------- */
try {
  if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["action"])) {
    $action = $_POST["action"];

    if ($action === "save") {
      $id = isset($_POST["id"]) ? (int)$_POST["id"] : 0;
      $text_en = trim($_POST["text_en"] ?? "");
      $text_ur = trim($_POST["text_ur"] ?? "");
      $is_active = isset($_POST["is_active"]) ? 1 : 0;
      $sort_order = (int)($_POST["sort_order"] ?? 0);

      if ($text_en === "" || $text_ur === "") {
        throw new Exception("Both English and Urdu headline text are required.");
      }
      if (mb_strlen($text_en) > 255 || mb_strlen($text_ur) > 255) {
        throw new Exception("Headline must be 255 characters or less.");
      }

      if ($dbDriver === "pdo") {
        if ($id > 0) {
          $stmt = $pdo->prepare("UPDATE headlines SET text_en=?, text_ur=?, is_active=?, sort_order=? WHERE id=?");
          $stmt->execute([$text_en, $text_ur, $is_active, $sort_order, $id]);
          $ok = "Headline updated successfully.";
        } else {
          $stmt = $pdo->prepare("INSERT INTO headlines (text_en, text_ur, is_active, sort_order) VALUES (?, ?, ?, ?)");
          $stmt->execute([$text_en, $text_ur, $is_active, $sort_order]);
          $ok = "Headline added successfully.";
        }
      } else {
        // mysqli
        if ($id > 0) {
          $stmt = $mysqli->prepare("UPDATE headlines SET text_en=?, text_ur=?, is_active=?, sort_order=? WHERE id=?");
          if (!$stmt) throw new Exception("DB prepare failed: " . $mysqli->error);
          $params = [$text_en, $text_ur, $is_active, $sort_order, $id];
          mysqli_bind_params($stmt, "ssiii", $params);
          if (!$stmt->execute()) throw new Exception("DB execute failed: " . $stmt->error);
          $stmt->close();
          $ok = "Headline updated successfully.";
        } else {
          $stmt = $mysqli->prepare("INSERT INTO headlines (text_en, text_ur, is_active, sort_order) VALUES (?, ?, ?, ?)");
          if (!$stmt) throw new Exception("DB prepare failed: " . $mysqli->error);
          $params = [$text_en, $text_ur, $is_active, $sort_order];
          mysqli_bind_params($stmt, "ssii", $params);
          if (!$stmt->execute()) throw new Exception("DB execute failed: " . $stmt->error);
          $stmt->close();
          $ok = "Headline added successfully.";
        }
      }
    }

    if ($action === "delete") {
      $id = (int)($_POST["id"] ?? 0);
      if ($id > 0) {
        if ($dbDriver === "pdo") {
          $stmt = $pdo->prepare("DELETE FROM headlines WHERE id=?");
          $stmt->execute([$id]);
        } else {
          $stmt = $mysqli->prepare("DELETE FROM headlines WHERE id=?");
          if (!$stmt) throw new Exception("DB prepare failed: " . $mysqli->error);
          $params = [$id];
          mysqli_bind_params($stmt, "i", $params);
          if (!$stmt->execute()) throw new Exception("DB execute failed: " . $stmt->error);
          $stmt->close();
        }
        $ok = "Headline deleted.";
      }
    }

    if ($action === "toggle") {
      $id = (int)($_POST["id"] ?? 0);
      if ($id > 0) {
        if ($dbDriver === "pdo") {
          $stmt = $pdo->prepare("UPDATE headlines SET is_active = 1 - is_active WHERE id=?");
          $stmt->execute([$id]);
        } else {
          $stmt = $mysqli->prepare("UPDATE headlines SET is_active = 1 - is_active WHERE id=?");
          if (!$stmt) throw new Exception("DB prepare failed: " . $mysqli->error);
          $params = [$id];
          mysqli_bind_params($stmt, "i", $params);
          if (!$stmt->execute()) throw new Exception("DB execute failed: " . $stmt->error);
          $stmt->close();
        }
        $ok = "Headline status updated.";
      }
    }
  }
} catch (Throwable $e) {
  $err = $e->getMessage();
}

/* ------------------------- Fetch list ------------------------- */
$items = [];
try {
  $sql = "SELECT id, text_en, text_ur, is_active, sort_order, updated_at
          FROM headlines
          ORDER BY sort_order ASC, updated_at DESC";

  if ($dbDriver === "pdo") {
    $stmt = $pdo->query($sql);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
  } else {
    $res = $mysqli->query($sql);
    if (!$res) throw new Exception("DB query failed: " . $mysqli->error);
    while ($row = $res->fetch_assoc()) $items[] = $row;
    $res->free();
  }
} catch (Throwable $e) {
  $err = $err ?: $e->getMessage();
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Manage Headlines</title>
  <style>
    /* Professional, responsive design */
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
      background: #0a2e26; /* deeper green background */
      color: #e9f0eb;
      line-height: 1.5;
      padding: 1rem;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .wrap {
      max-width: 1200px;
      width: 100%;
      margin: 0 auto;
    }

    /* main card */
    .card {
      background: #0f3f35;
      border: 1px solid rgba(223, 162, 115, 0.25);
      border-radius: 1.5rem;
      padding: 1.5rem;
      box-shadow: 0 20px 35px -8px rgba(0, 0, 0, 0.5);
      transition: box-shadow 0.2s;
    }

    /* Header with title and dashboard button */
    .header-row {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 0.25rem;
    }
    .header-row h1 {
      margin: 0;
      font-size: 2rem;
      font-weight: 600;
      color: #eecbad; /* softer gold */
      letter-spacing: -0.02em;
    }
    .dashboard-link {
      margin-left: 1rem;
    }

    .muted {
      color: #aac3b9;
      font-size: 0.9rem;
      margin-bottom: 1rem;
    }

    /* message boxes */
    .msg {
      margin: 1.5rem 0 1rem;
      padding: 1rem 1.2rem;
      border-radius: 1rem;
      font-weight: 500;
    }
    .ok {
      background: rgba(72, 187, 120, 0.15);
      border: 1px solid rgba(72, 187, 120, 0.4);
      color: #c6f0d0;
    }
    .err {
      background: rgba(245, 101, 101, 0.15);
      border: 1px solid rgba(245, 101, 101, 0.4);
      color: #fccaca;
    }

    /* form layout */
    .row {
      display: flex;
      gap: 1rem;
      flex-wrap: wrap;
    }
    .col {
      flex: 1 1 200px;
      min-width: 0; /* prevent overflow */
    }

    label {
      display: block;
      margin-bottom: 0.5rem;
      font-weight: 600;
      color: #e2c3a0;
      font-size: 0.9rem;
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }

    input[type=text],
    input[type=number] {
      width: 100%;
      padding: 0.8rem 1rem;
      border-radius: 1rem;
      border: 1px solid rgba(223, 162, 115, 0.35);
      background: rgba(255, 255, 255, 0.06);
      color: #fff;
      font-size: 1rem;
      transition: border 0.2s, background 0.2s;
    }
    input[type=text]:focus,
    input[type=number]:focus {
      outline: none;
      border-color: #e2a56f;
      background: rgba(255, 255, 255, 0.1);
    }
    input[type=checkbox] {
      width: 1.2rem;
      height: 1.2rem;
      accent-color: #dfa273;
      margin-right: 0.5rem;
      transform: translateY(2px);
    }

    .btn, .btn2 {
      cursor: pointer;
      border: none;
      border-radius: 2rem;
      padding: 0.7rem 1.4rem;
      font-weight: 600;
      font-size: 0.95rem;
      transition: background 0.15s, transform 0.1s, box-shadow 0.15s;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      text-decoration: none;
    }
    .btn {
      background: #dfa273;
      color: #0a2e26;
      box-shadow: 0 8px 18px -6px rgba(223, 162, 115, 0.4);
    }
    .btn:hover {
      background: #e6b38a;
      box-shadow: 0 10px 22px -6px rgba(223, 162, 115, 0.6);
      transform: scale(1.02);
    }
    .btn2 {
      background: transparent;
      border: 1px solid rgba(223, 162, 115, 0.6);
      color: #dfa273;
    }
    .btn2:hover {
      background: rgba(223, 162, 115, 0.1);
      border-color: #dfa273;
    }
    button:active {
      transform: scale(0.98);
    }

    /* checkbox row alignment */
    .checkbox-wrapper {
      display: flex;
      align-items: center;
      margin: 0.5rem 0;
    }

    /* table responsive */
    .table-responsive {
      overflow-x: auto;
      margin: 1.8rem 0 0.8rem;
      border-radius: 1rem;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.95rem;
      min-width: 600px; /* forces horizontal scroll on small screens */
    }
    th {
      text-align: left;
      padding: 1rem 0.8rem 0.8rem 0.8rem;
      color: #eecbad;
      font-weight: 600;
      border-bottom: 2px solid rgba(223, 162, 115, 0.25);
    }
    td {
      padding: 0.9rem 0.8rem;
      border-bottom: 1px solid rgba(223, 162, 115, 0.12);
      vertical-align: middle;
    }
    tr:last-child td {
      border-bottom: none;
    }
    tbody tr:hover {
      background: rgba(255, 255, 255, 0.02);
    }

    .badge {
      display: inline-block;
      padding: 0.3rem 0.8rem;
      border-radius: 2rem;
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      border: 1px solid rgba(223, 162, 115, 0.4);
      color: #dfa273;
      background: rgba(223, 162, 115, 0.05);
    }
    .badge.off {
      opacity: 0.7;
      border-color: rgba(170, 195, 185, 0.4);
      color: #aac3b9;
    }

    .actions {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
    }
    .actions form {
      display: inline-block;
    }

    /* small screen adjustments */
    @media (max-width: 640px) {
      body { padding: 0.5rem; }
      .wrap { padding: 0; }
      .card { padding: 1.2rem; border-radius: 1.2rem; }
      .header-row h1 { font-size: 1.8rem; }

      .row {
        flex-direction: column;
        gap: 0.8rem;
      }
      .col {
        width: 100%;
      }

      .btn, .btn2 {
        width: 100%;
        margin-top: 0.3rem;
      }
      .checkbox-wrapper {
        justify-content: flex-start;
      }
      td .btn2 {
        width: auto; /* keep action buttons inline */
        padding: 0.4rem 1rem;
      }
      .table-responsive {
        margin-top: 1rem;
      }
      .header-row {
        flex-direction: column;
        align-items: flex-start;
        gap: 0.5rem;
      }
      .dashboard-link {
        margin-left: 0;
        width: 100%;
      }
      .dashboard-link .btn2 {
        width: 100%;
      }
    }

    /* extra small devices */
    @media (max-width: 480px) {
      .actions {
        flex-direction: column;
        gap: 0.3rem;
      }
      .actions form {
        width: 100%;
      }
      .actions .btn2 {
        width: 100%;
      }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <div class="header-row">
        <h1>📰 Headlines</h1>
        <div class="dashboard-link">
          <a href="index.php" class="btn2">← Back to Dashboard</a>
        </div>
      </div>
      <div class="muted">Manage single‑line sliding headlines shown in the app.</div>

      <?php if ($ok): ?>
        <div class="msg ok"><?=h($ok)?></div>
      <?php endif; ?>
      <?php if ($err): ?>
        <div class="msg err"><?=h($err)?></div>
      <?php endif; ?>

      <!-- Add / Edit form (always in "add" mode, could be extended for edit) -->
      <form method="post" style="margin-top: 1.8rem;">
        <input type="hidden" name="action" value="save"/>
        <div class="row">
          <div class="col">
            <label>English Text</label>
            <input type="text" name="text_en" maxlength="255" placeholder="e.g. Gold rates updated every 10 seconds" required>
          </div>
          <div class="col">
            <label>Urdu Text</label>
            <input type="text" name="text_ur" maxlength="255" placeholder="مثلاً: گولڈ ریٹس ہر 10 سیکنڈ میں اپڈیٹ ہوتے ہیں" required>
          </div>
        </div>

        <div class="row" style="margin-top: 0.8rem; align-items: flex-end;">
          <div class="col">
            <label>Sort Order</label>
            <input type="number" name="sort_order" value="0" min="0" step="1">
          </div>
          <div class="col">
            <div class="checkbox-wrapper">
              <input type="checkbox" name="is_active" id="is_active" checked>
              <label for="is_active" style="display: inline; margin: 0; text-transform: none;">Active</label>
            </div>
          </div>
          <div class="col" style="display: flex; justify-content: flex-end;">
            <button class="btn" type="submit">➕ Add Headline</button>
          </div>
        </div>
      </form>

      <!-- List of headlines -->
      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>English</th>
              <th>Urdu</th>
              <th>Order</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($items as $it): ?>
              <tr>
                <td><?= (int)$it["id"] ?></td>
                <td><?= h($it["text_en"]) ?></td>
                <td><?= h($it["text_ur"]) ?></td>
                <td><?= (int)$it["sort_order"] ?></td>
                <td>
                  <?php if ((int)$it["is_active"] === 1): ?>
                    <span class="badge">ON</span>
                  <?php else: ?>
                    <span class="badge off">OFF</span>
                  <?php endif; ?>
                </td>
                <td class="actions">
                  <form method="post">
                    <input type="hidden" name="action" value="toggle">
                    <input type="hidden" name="id" value="<?= (int)$it["id"] ?>">
                    <button class="btn2" type="submit">Toggle</button>
                  </form>
                  <form method="post" onsubmit="return confirm('Delete this headline?');">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="<?= (int)$it["id"] ?>">
                    <button class="btn2" type="submit">Delete</button>
                  </form>
                </td>
              </tr>
            <?php endforeach; ?>
            <?php if (count($items) === 0): ?>
              <tr><td colspan="6" class="muted" style="text-align:center; padding:2rem;">No headlines yet. Create one above.</td></tr>
            <?php endif; ?>
          </tbody>
        </table>
      </div>

      <!--<div class="muted" style="margin-top: 1.5rem; text-align: right;">-->
      <!--  <span style="background: rgba(223,162,115,0.1); padding: 0.2rem 0.8rem; border-radius: 2rem;">API endpoint: <code style="background: #0a2e26; padding:0.2rem 0.4rem; border-radius:0.5rem;">/metal/api/headlines.php</code></span>-->
      <!--</div>-->
    </div>
  </div>
</body>
</html>