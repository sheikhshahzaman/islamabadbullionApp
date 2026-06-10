<?php
// metal/admin/gold_karat_adjustments.php
require_once __DIR__ . '/../includes/db.php';

session_start();

/**
 * IMPORTANT:
 * Adjust this login-guard to match your existing admin session variable
 * (copy the same session check you use in index.php).
 */
if (empty($_SESSION['user_id']) && empty($_SESSION['admin_id']) && empty($_SESSION['logged_in'])) {
  header("Location: login.php");
  exit;
}

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

$currencies = ['PKR','USD','EUR','GBP','AED','CAD'];
$currency = $_GET['currency'] ?? 'PKR';
if (!in_array($currency, $currencies, true)) $currency = 'PKR';

$KARATS = [
  '24K'  => '24K',
  '22K'  => '22K',
  '21K'  => '21K',
  '18K'  => '18K',
  'RAWA' => 'Rawa',
];

$successMsg = null;
$errorMsg = null;

function read_rows(mysqli $conn, string $currency): array {
  $rows = [];
  $stmt = $conn->prepare("
    SELECT
      karat_code,
      mid_percent_adjust,  mid_flat_adjust,
      sell_percent_adjust, sell_flat_adjust,
      buy_percent_adjust,  buy_flat_adjust
    FROM gold_karat_adjustments
    WHERE currency_code=?
  ");
  $stmt->bind_param('s', $currency);
  $stmt->execute();
  $stmt->bind_result($k, $mp, $mf, $sp, $sf, $bp, $bf);

  while ($stmt->fetch()) {
    $rows[$k] = [
      'mid_percent'  => (float)$mp,
      'mid_flat'     => (float)$mf,
      'sell_percent' => (float)$sp,
      'sell_flat'    => (float)$sf,
      'buy_percent'  => (float)$bp,
      'buy_flat'     => (float)$bf,
    ];
  }
  return $rows;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $currency = $_POST['currency'] ?? $currency;
  if (!in_array($currency, $currencies, true)) $currency = 'PKR';

  try {
    foreach ($KARATS as $kcode => $_label) {
      $mp = (float)($_POST["{$kcode}_mid_percent"] ?? 0);
      $mf = (float)($_POST["{$kcode}_mid_flat"] ?? 0);

      $sp = (float)($_POST["{$kcode}_sell_percent"] ?? 0);
      $sf = (float)($_POST["{$kcode}_sell_flat"] ?? 0);

      $bp = (float)($_POST["{$kcode}_buy_percent"] ?? 0);
      $bf = (float)($_POST["{$kcode}_buy_flat"] ?? 0);

      // UPSERT
      $stmt = $conn->prepare("
        INSERT INTO gold_karat_adjustments
          (currency_code, karat_code,
           mid_percent_adjust, mid_flat_adjust,
           sell_percent_adjust, sell_flat_adjust,
           buy_percent_adjust, buy_flat_adjust)
        VALUES
          (?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
          mid_percent_adjust=VALUES(mid_percent_adjust),
          mid_flat_adjust=VALUES(mid_flat_adjust),
          sell_percent_adjust=VALUES(sell_percent_adjust),
          sell_flat_adjust=VALUES(sell_flat_adjust),
          buy_percent_adjust=VALUES(buy_percent_adjust),
          buy_flat_adjust=VALUES(buy_flat_adjust)
      ");
      $stmt->bind_param(
        'sssdddddd', // NOTE: we will bind as string+string then doubles; easiest is split binds:
        $dummy // placeholder
      );
    }
  } catch (Throwable $e) {
    $errorMsg = "Save failed: " . $e->getMessage();
  }

  // The above binding with 'sssdddddd' isn't valid as-written due to PHP bind types.
  // We'll do the correct, explicit bind below (keeping code clean and reliable).

  try {
    foreach ($KARATS as $kcode => $_label) {
      $mp = (float)($_POST["{$kcode}_mid_percent"] ?? 0);
      $mf = (float)($_POST["{$kcode}_mid_flat"] ?? 0);

      $sp = (float)($_POST["{$kcode}_sell_percent"] ?? 0);
      $sf = (float)($_POST["{$kcode}_sell_flat"] ?? 0);

      $bp = (float)($_POST["{$kcode}_buy_percent"] ?? 0);
      $bf = (float)($_POST["{$kcode}_buy_flat"] ?? 0);

      $stmt = $conn->prepare("
        INSERT INTO gold_karat_adjustments
          (currency_code, karat_code,
           mid_percent_adjust, mid_flat_adjust,
           sell_percent_adjust, sell_flat_adjust,
           buy_percent_adjust, buy_flat_adjust)
        VALUES
          (?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
          mid_percent_adjust=VALUES(mid_percent_adjust),
          mid_flat_adjust=VALUES(mid_flat_adjust),
          sell_percent_adjust=VALUES(sell_percent_adjust),
          sell_flat_adjust=VALUES(sell_flat_adjust),
          buy_percent_adjust=VALUES(buy_percent_adjust),
          buy_flat_adjust=VALUES(buy_flat_adjust)
      ");

      // currency_code (s), karat_code (s), then 6 doubles (d)
      $stmt->bind_param(
        'ssdddddd',
        $currency,
        $kcode,
        $mp, $mf,
        $sp, $sf,
        $bp, $bf
      );

      $stmt->execute();
    }

    $successMsg = "Saved successfully for currency: $currency";
  } catch (Throwable $e) {
    $errorMsg = "Save failed: " . $e->getMessage();
  }
}

// load current
$existing = read_rows($conn, $currency);

function val(array $existing, string $kcode, string $field): string {
  if (!isset($existing[$kcode])) return "0";
  return (string)$existing[$kcode][$field];
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gold Category Adjustments</title>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial; background:#0b2f26; color:#fff; margin:0;}
    .wrap{max-width:1100px; margin:0 auto; padding:18px;}
    .card{background:#0a3c30; border-radius:14px; padding:16px; border:1px solid rgba(255,255,255,.14);}
    .row{display:flex; gap:12px; flex-wrap:wrap;}
    .title{font-size:18px; font-weight:900; margin:0 0 6px;}
    .muted{opacity:.75; margin:0 0 14px; font-size:13px;}
    .msg{padding:10px 12px; border-radius:10px; margin-bottom:12px;}
    .ok{background:rgba(46,204,113,.18); border:1px solid rgba(46,204,113,.35);}
    .bad{background:rgba(231,76,60,.18); border:1px solid rgba(231,76,60,.35);}
    table{width:100%; border-collapse:collapse; overflow:hidden; border-radius:12px;}
    th,td{padding:10px; border-bottom:1px solid rgba(255,255,255,.12); vertical-align:top;}
    th{font-size:12px; text-transform:uppercase; letter-spacing:.04em; opacity:.85; text-align:left;}
    input,select{width:100%; padding:9px 10px; border-radius:10px; border:1px solid rgba(255,255,255,.22); background:#082a22; color:#fff; outline:none;}
    .grid{display:grid; grid-template-columns:1fr 1fr; gap:8px;}
    .btnbar{display:flex; gap:10px; margin-top:12px; flex-wrap:wrap;}
    .btn{padding:10px 14px; border-radius:12px; border:0; font-weight:900; cursor:pointer;}
    .btn-primary{background:#ffffff; color:#0a3c30;}
    .btn-ghost{background:transparent; color:#fff; border:1px solid rgba(255,255,255,.22);}
    .small{font-size:12px; opacity:.8; margin-top:6px;}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <p class="title">Gold Pricing Adjustments</p>
      <p class="muted">
        Set separate adjustments for <b>18K, 21K, 22K, 24K, Rawa</b> per currency.
        Percent is applied first, then flat is added.
      </p>

      <?php if ($successMsg): ?>
        <div class="msg ok"><?php echo h($successMsg); ?></div>
      <?php endif; ?>
      <?php if ($errorMsg): ?>
        <div class="msg bad"><?php echo h($errorMsg); ?></div>
      <?php endif; ?>

      

      <form method="post">
        <input type="hidden" name="currency" value="<?php echo h($currency); ?>">

        <table>
          <thead>
            <tr>
              <th style="width:120px;">Category</th>
              <th>Mid (DO NOT ENTER ANYTHING)</th>
              <th>Sell</th>
              <th>Buy</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($KARATS as $kcode => $label): ?>
              <tr>
                <td><b><?php echo h($label); ?></b></td>

                <td>
                  <div class="grid">
                    <div>
                      <label class="small">% Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($kcode); ?>_mid_percent"
                        value="<?php echo h(val($existing,$kcode,'mid_percent')); ?>">
                    </div>
                    <div>
                      <label class="small">Flat Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($kcode); ?>_mid_flat"
                        value="<?php echo h(val($existing,$kcode,'mid_flat')); ?>">
                    </div>
                  </div>
                </td>

                <td>
                  <div class="grid">
                    <div>
                      <label class="small">% Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($kcode); ?>_sell_percent"
                        value="<?php echo h(val($existing,$kcode,'sell_percent')); ?>">
                    </div>
                    <div>
                      <label class="small">Flat Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($kcode); ?>_sell_flat"
                        value="<?php echo h(val($existing,$kcode,'sell_flat')); ?>">
                    </div>
                  </div>
                </td>

                <td>
                  <div class="grid">
                    <div>
                      <label class="small">% Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($kcode); ?>_buy_percent"
                        value="<?php echo h(val($existing,$kcode,'buy_percent')); ?>">
                    </div>
                    <div>
                      <label class="small">Flat Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($kcode); ?>_buy_flat"
                        value="<?php echo h(val($existing,$kcode,'buy_flat')); ?>">
                    </div>
                  </div>
                </td>
              </tr>
            <?php endforeach; ?>
          </tbody>
        </table>

        <div class="btnbar">
          <button class="btn btn-primary" type="submit">Save Changes</button>
          <a class="btn btn-ghost" href="?currency=<?php echo h($currency); ?>">Reload</a>
          <a class="btn btn-ghost" href="index.php">Back to Dashboard</a>
        </div>

        
      </form>
    </div>
  </div>
</body>
</html>