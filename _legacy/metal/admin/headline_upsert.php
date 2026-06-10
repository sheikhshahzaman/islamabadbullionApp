<?php
require_once __DIR__ . '/../includes/db.php';

// ------------------- DB handle: supports $mysqli OR $conn -------------------
$db = null;
if (isset($mysqli) && $mysqli instanceof mysqli) $db = $mysqli;
if (!$db && isset($conn) && $conn instanceof mysqli) $db = $conn;
if (!$db) die("DB connection not found. Make sure db include defines \$mysqli or \$conn.");

if (session_status() === PHP_SESSION_NONE) session_start();

// ---------------- CSRF ----------------
if (empty($_SESSION["csrf"])) {
  $_SESSION["csrf"] = bin2hex(random_bytes(16));
}
$CSRF = $_SESSION["csrf"];

function h($v) { return htmlspecialchars((string)$v, ENT_QUOTES, "UTF-8"); }

function fromDateTimeLocal($v) {
  $v = trim((string)$v);
  if ($v === "") return null;
  return str_replace("T", " ", $v) . ":00";
}
function toDateTimeLocal($dt) {
  if (!$dt) return "";
  return str_replace(" ", "T", substr($dt, 0, 16));
}

$id = isset($_GET["id"]) ? (int)$_GET["id"] : 0;
$isEdit = $id > 0;

$title_en = "";
$title_ur = "";
$is_active = 1;
$starts_at = "";
$ends_at = "";
$errors = [];

if ($isEdit) {
  $stmt = $db->prepare("SELECT * FROM app_headlines WHERE id=?");
  $stmt->bind_param("i", $id);
  $stmt->execute();
  $res = $stmt->get_result();
  $row = $res ? $res->fetch_assoc() : null;
  $stmt->close();

  if (!$row) die("Headline not found.");

  $title_en = $row["title_en"];
  $title_ur = $row["title_ur"];
  $is_active = (int)$row["is_active"];
  $starts_at = toDateTimeLocal($row["starts_at"]);
  $ends_at = toDateTimeLocal($row["ends_at"]);
}

if ($_SERVER["REQUEST_METHOD"] === "POST") {
  $postCsrf = $_POST["csrf"] ?? "";
  if (!hash_equals($CSRF, $postCsrf)) die("Invalid CSRF token");

  $title_en = trim((string)($_POST["title_en"] ?? ""));
  $title_ur = trim((string)($_POST["title_ur"] ?? ""));
  $is_active = isset($_POST["is_active"]) ? 1 : 0;

  $starts_at_db = fromDateTimeLocal($_POST["starts_at"] ?? "");
  $ends_at_db = fromDateTimeLocal($_POST["ends_at"] ?? "");

  if ($title_en === "" || mb_strlen($title_en) > 180) $errors[] = "English line is required (max 180 chars).";
  if ($title_ur === "" || mb_strlen($title_ur) > 180) $errors[] = "Urdu line is required (max 180 chars).";
  if ($starts_at_db && $ends_at_db && $starts_at_db > $ends_at_db) $errors[] = "Start must be before End.";

  if (empty($errors)) {
    if ($isEdit) {
      $stmt = $db->prepare(
        "UPDATE app_headlines
         SET title_en=?, title_ur=?, is_active=?, starts_at=?, ends_at=?
         WHERE id=?"
      );
      $stmt->bind_param("ssissi", $title_en, $title_ur, $is_active, $starts_at_db, $ends_at_db, $id);
      $stmt->execute();
      $stmt->close();
    } else {
      $res = $db->query("SELECT COALESCE(MAX(sort_order),0) AS m FROM app_headlines");
      $m = $res ? (int)($res->fetch_assoc()["m"] ?? 0) : 0;
      $nextOrder = $m + 1;

      $stmt = $db->prepare(
        "INSERT INTO app_headlines (title_en, title_ur, is_active, sort_order, starts_at, ends_at)
         VALUES (?,?,?,?,?,?)"
      );
      $stmt->bind_param("ssiiss", $title_en, $title_ur, $is_active, $nextOrder, $starts_at_db, $ends_at_db);
      $stmt->execute();
      $stmt->close();
    }

    header("Location: headlines.php");
    exit;
  }

  // Keep submitted values
  $starts_at = $_POST["starts_at"] ?? "";
  $ends_at = $_POST["ends_at"] ?? "";
}
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title><?= $isEdit ? "Edit Headline" : "Add Headline" ?></title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;margin:0;background:#1A5249;color:#fff;}
    .wrap{max-width:860px;margin:0 auto;padding:18px;}
    .card{background:#0A3C30;border:1px solid rgba(223,162,115,.30);border-radius:14px;padding:14px;}
    .title{font-weight:900;color:#dfa273;font-size:18px;margin-bottom:4px;}
    .muted{color:rgba(223,162,115,.75);font-size:12px;}
    label{display:block;margin-top:12px;font-weight:900;color:#dfa273;font-size:13px;}
    input[type="text"], input[type="datetime-local"]{
      width:100%;padding:12px;border-radius:12px;border:1px solid rgba(223,162,115,.35);
      background:rgba(255,255,255,.08);color:#fff;outline:none;
    }
    .row{display:flex;gap:12px;flex-wrap:wrap;}
    .col{flex:1;min-width:240px;}
    .btn{display:inline-block;padding:10px 12px;border-radius:10px;text-decoration:none;font-weight:900;cursor:pointer;border:0;}
    .btn-primary{background:#dfa273;color:#000;}
    .btn-ghost{border:1px solid rgba(223,162,115,.40);color:#dfa273;background:transparent;}
    .errors{margin:12px 0;padding:12px;border-radius:12px;border:1px solid rgba(255,80,80,.45);background:rgba(255,80,80,.10);}
    .check{display:flex;align-items:center;gap:10px;margin-top:12px;}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <div class="title"><?= $isEdit ? "Edit Headline" : "Add Headline" ?></div>
      <div class="muted">One line per slide. English + Urdu. Optional scheduling.</div>

      <?php if (!empty($errors)): ?>
        <div class="errors">
          <?php foreach ($errors as $e): ?>
            <div>• <?= h($e) ?></div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>

      <form method="post">
        <input type="hidden" name="csrf" value="<?= h($CSRF) ?>">

        <label>English Headline</label>
        <input type="text" name="title_en" maxlength="180" value="<?= h($title_en) ?>" placeholder="e.g. Gold rates updated every 30 seconds">

        <label>Urdu Headline</label>
        <input type="text" name="title_ur" maxlength="180" value="<?= h($title_ur) ?>" dir="rtl" placeholder="مثلاً: گولڈ ریٹس ہر 30 سیکنڈ بعد اپڈیٹ ہوتے ہیں">

        <div class="check">
          <input id="is_active" type="checkbox" name="is_active" <?= $is_active ? "checked" : "" ?>>
          <label for="is_active" style="margin:0;">Active</label>
        </div>

        <div class="row">
          <div class="col">
            <label>Start (optional)</label>
            <input type="datetime-local" name="starts_at" value="<?= h($starts_at) ?>">
          </div>
          <div class="col">
            <label>End (optional)</label>
            <input type="datetime-local" name="ends_at" value="<?= h($ends_at) ?>">
          </div>
        </div>

        <div style="margin-top:16px;display:flex;gap:10px;flex-wrap:wrap;">
          <button class="btn btn-primary" type="submit"><?= $isEdit ? "Save Changes" : "Create Headline" ?></button>
          <a class="btn btn-ghost" href="headlines.php">Cancel</a>
        </div>
      </form>
    </div>
  </div>
</body>
</html>
