<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../includes/db.php';

$pdo = $pdo ?? null;
$mysqli =
  ($mysqli ?? null)
  ?: ($conn ?? null)
  ?: ($con ?? null)
  ?: ($db ?? null)
  ?: ($connection ?? null)
  ?: ($link ?? null);

if (!$pdo && !$mysqli) {
  foreach (["getPDO", "pdo", "db", "getDb", "getDB", "connectDb"] as $fn) {
    if (function_exists($fn)) {
      $tmp = $fn();
      if ($tmp instanceof PDO) { $pdo = $tmp; break; }
      if ($tmp instanceof mysqli) { $mysqli = $tmp; break; }
    }
  }
}

$dbDriver = null;
if ($pdo instanceof PDO) {
  $dbDriver = "pdo";
} elseif ($mysqli instanceof mysqli) {
  $dbDriver = "mysqli";
  if (method_exists($mysqli, "set_charset")) {
    @$mysqli->set_charset("utf8mb4");
  }
} else {
  http_response_code(500);
  echo json_encode(["success"=>false, "error"=>"DB connection not found"], JSON_UNESCAPED_UNICODE);
  exit;
}

try {
  $sql = "SELECT id, text_en, text_ur, sort_order, updated_at
          FROM headlines
          WHERE is_active = 1
          ORDER BY sort_order ASC, updated_at DESC";

  $rows = [];

  if ($dbDriver === "pdo") {
    $stmt = $pdo->query($sql);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
  } else {
    $res = $mysqli->query($sql);
    if (!$res) throw new Exception("DB query failed: " . $mysqli->error);
    while ($row = $res->fetch_assoc()) $rows[] = $row;
    $res->free();
  }

  echo json_encode([
    "success" => true,
    "server_time" => date("Y-m-d H:i:s"),
    "headlines" => array_map(function($r) {
      return [
        "id" => (int)$r["id"],
        "en" => (string)$r["text_en"],
        "ur" => (string)$r["text_ur"],
        "sort_order" => (int)$r["sort_order"],
        "updated_at" => (string)$r["updated_at"],
      ];
    }, $rows),
  ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["success"=>false, "error"=>"Server error"], JSON_UNESCAPED_UNICODE);
}