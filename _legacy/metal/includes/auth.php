<?php
// metal/includes/auth.php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/db.php';

function isAdminLoggedIn(): bool {
  return !empty($_SESSION['admin_id']);
}

function requireAdminLogin(): void {
  if (!isAdminLoggedIn()) {
    header('Location: /metal/admin/login.php');
    exit;
  }
}

function ensureDefaultAdminIfEmpty(): void {
  global $conn;
  $res = $conn->query("SELECT COUNT(*) AS c FROM admins");
  $row = $res ? $res->fetch_assoc() : ['c' => 0];
  if ((int)$row['c'] === 0) {
    $u = 'admin';
    $hash = password_hash('admin123', PASSWORD_BCRYPT);
    $stmt = $conn->prepare("INSERT INTO admins (username, password_hash) VALUES (?,?)");
    $stmt->bind_param('ss', $u, $hash);
    $stmt->execute();
  }
}

function adminLogin(string $username, string $password): bool {
  global $conn;

  ensureDefaultAdminIfEmpty();

  $stmt = $conn->prepare("SELECT id, password_hash FROM admins WHERE username=? LIMIT 1");
  $stmt->bind_param('s', $username);
  $stmt->execute();
  $stmt->bind_result($id, $hash);

  if ($stmt->fetch() && password_verify($password, $hash)) {
    $_SESSION['admin_id'] = $id;
    $_SESSION['admin_username'] = $username;
    return true;
  }
  return false;
}

function adminLogout(): void {
  $_SESSION = [];
  if (session_status() === PHP_SESSION_ACTIVE) {
    session_destroy();
  }
}
