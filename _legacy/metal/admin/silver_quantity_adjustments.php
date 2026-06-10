<?php
// metal/admin/silver_quantity_adjustments.php
require_once __DIR__ . '/../includes/db.php';

session_start();

/**
 * IMPORTANT:
 * Keep the same login guard pattern you already use.
 */
if (empty($_SESSION['user_id']) && empty($_SESSION['admin_id']) && empty($_SESSION['logged_in'])) {
  header("Location: login.php");
  exit;
}

require_once __DIR__ . '/../lib/price_service.php'; // used only to show live/base prices (optional but recommended)

function h($s) { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

function nf2($v): string {
  return number_format((float)$v, 2, '.', ',');
}

$currencies = ['PKR','USD','EUR','GBP','AED','CAD'];
$currency = $_GET['currency'] ?? 'PKR';
if (!in_array($currency, $currencies, true)) $currency = 'PKR';

$CUR_PREFIX = match ($currency) {
  'PKR' => '₨ ',
  'USD' => '$ ',
  'EUR' => '€ ',
  'GBP' => '£ ',
  'AED' => 'د.إ ',
  'CAD' => 'C$ ',
  default => $currency . ' ',
};

const GRAMS_PER_TOLA = 11.6638038;

$QTY = [
  'GRAM' => 'Gram',
  'G10'  => '10 Gram',
  'TOLA' => 'Tola',
  'T10'  => '10 Tola',
  'KG'   => '1 KG',
];

$successMsg = null;
$errorMsg = null;

function read_rows(mysqli $conn, string $currency): array {
  $rows = [];
  $stmt = $conn->prepare("
    SELECT
      qty_code,
      mid_percent_adjust,  mid_flat_adjust,
      sell_percent_adjust, sell_flat_adjust,
      buy_percent_adjust,  buy_flat_adjust
    FROM silver_qty_adjustments
    WHERE currency_code=?
  ");
  $stmt->bind_param('s', $currency);
  $stmt->execute();
  $stmt->bind_result($q, $mp, $mf, $sp, $sf, $bp, $bf);

  while ($stmt->fetch()) {
    $rows[$q] = [
      'mid_percent'  => (float)$mp,
      'mid_flat'     => (float)$mf,
      'sell_percent' => (float)$sp,
      'sell_flat'    => (float)$sf,
      'buy_percent'  => (float)$bp,
      'buy_flat'     => (float)$bf,
    ];
  }
  $stmt->close();
  return $rows;
}

function val(array $existing, string $qcode, string $field): string {
  if (!isset($existing[$qcode])) return "0";
  return (string)$existing[$qcode][$field];
}

function apply_adj(float $base, float $percent, float $flat): float {
  // Percent first, then flat
  return ($base * (1.0 + ($percent / 100.0))) + $flat;
}

function base_for_qty(string $qcode, float $perGram, float $perTola): float {
  $tola = $perTola > 0 ? $perTola : ($perGram * GRAMS_PER_TOLA);
  return match ($qcode) {
    'GRAM' => $perGram,
    'G10'  => $perGram * 10.0,
    'TOLA' => $tola,
    'T10'  => $tola * 10.0,
    'KG'   => $perGram * 1000.0,
    default => $perGram,
  };
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $currency = $_POST['currency'] ?? $currency;
  if (!in_array($currency, $currencies, true)) $currency = 'PKR';

  try {
    foreach ($QTY as $qcode => $_label) {
      $mp = (float)($_POST["{$qcode}_mid_percent"] ?? 0);
      $mf = (float)($_POST["{$qcode}_mid_flat"] ?? 0);

      $sp = (float)($_POST["{$qcode}_sell_percent"] ?? 0);
      $sf = (float)($_POST["{$qcode}_sell_flat"] ?? 0);

      $bp = (float)($_POST["{$qcode}_buy_percent"] ?? 0);
      $bf = (float)($_POST["{$qcode}_buy_flat"] ?? 0);

      $stmt = $conn->prepare("
        INSERT INTO silver_qty_adjustments
          (currency_code, qty_code,
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
        'ssdddddd',
        $currency,
        $qcode,
        $mp, $mf,
        $sp, $sf,
        $bp, $bf
      );
      $stmt->execute();
      $stmt->close();
    }

    $successMsg = "Saved successfully for currency: $currency";
  } catch (Throwable $e) {
    $errorMsg = "Save failed: " . $e->getMessage();
  }
}

$existing = read_rows($conn, $currency);

/**
 * Optional: show live/base Silver prices (XAG) + preview final after adjustments.
 * If build_response() is not available or API fails, page still works (inputs + save).
 */
$liveOk = false;
$liveError = '';
$silver = null;

if (function_exists('build_response')) {
  $live = build_response($currency);
  $liveOk = is_array($live) && !empty($live['success']);
  if ($liveOk) {
    foreach (($live['metals'] ?? []) as $m) {
      if (($m['code'] ?? '') === 'XAG') { $silver = $m; break; }
    }
    if (!$silver) {
      $liveOk = false;
      $liveError = "Live data missing for XAG.";
    }
  } else {
    $liveError = is_array($live) ? (($live['error']['info'] ?? 'Unknown error')) : 'Unknown error';
  }
} else {
  $liveError = "build_response() not found. Check ../lib/price_service.php";
}

$perGramMid  = $silver ? (float)($silver['per_gram'] ?? 0) : 0.0;
$perTolaMid  = $silver ? (float)($silver['per_tola'] ?? 0) : 0.0;

$sellPerGram = $silver ? (float)(($silver['sell']['per_gram'] ?? 0)) : 0.0;
$sellPerTola = $silver ? (float)(($silver['sell']['per_tola'] ?? 0)) : 0.0;

$buyPerGram  = $silver ? (float)(($silver['buy']['per_gram'] ?? 0)) : 0.0;
$buyPerTola  = $silver ? (float)(($silver['buy']['per_tola'] ?? 0)) : 0.0;

?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Silver Quantity Adjustments</title>
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
    .btn-ghost{background:transparent; color:#fff; border:1px solid rgba(255,255,255,.22); text-decoration:none; display:inline-flex; align-items:center;}
    .small{font-size:12px; opacity:.82; margin-top:6px; line-height:1.35;}
    .badge{display:inline-block; padding:2px 10px; border-radius:999px; background:rgba(255,255,255,.10); border:1px solid rgba(255,255,255,.14); font-size:12px; margin-right:6px; margin-top:6px;}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <p class="title">Silver Pricing Adjustments</p>
      <p class="muted">
        Set separate adjustments for <b>Gram, 10 Gram, Tola, 10 Tola, 1 KG</b> per currency.
        Percent is applied first, then flat is added.
      </p>

      <?php if ($successMsg): ?>
        <div class="msg ok"><?php echo h($successMsg); ?></div>
      <?php endif; ?>
      <?php if ($errorMsg): ?>
        <div class="msg bad"><?php echo h($errorMsg); ?></div>
      <?php endif; ?>

      <?php if (!$liveOk): ?>
        <div class="msg bad">Live preview not available: <b><?php echo h($liveError); ?></b> (Inputs & saving will still work.)</div>
      <?php endif; ?>

      

      <form method="post">
        <input type="hidden" name="currency" value="<?php echo h($currency); ?>">

        <table>
          <thead>
            <tr>
              <th style="width:260px;">Quantity (XAG)</th>
              <th>Mid (optional)</th>
              <th>Sell</th>
              <th>Buy</th>
            </tr>
          </thead>
          <tbody>
            <?php foreach ($QTY as $qcode => $label): ?>
              <?php
                $mp = (float)val($existing, $qcode, 'mid_percent');
                $mf = (float)val($existing, $qcode, 'mid_flat');
                $sp = (float)val($existing, $qcode, 'sell_percent');
                $sf = (float)val($existing, $qcode, 'sell_flat');
                $bp = (float)val($existing, $qcode, 'buy_percent');
                $bf = (float)val($existing, $qcode, 'buy_flat');

                $baseMid  = $liveOk ? base_for_qty($qcode, $perGramMid,  $perTolaMid)  : 0.0;
                $baseSell = $liveOk ? base_for_qty($qcode, $sellPerGram, $sellPerTola) : 0.0;
                $baseBuy  = $liveOk ? base_for_qty($qcode, $buyPerGram,  $buyPerTola)  : 0.0;

                $finalMid  = apply_adj($baseMid,  $mp, $mf);
                $finalSell = apply_adj($baseSell, $sp, $sf);
                $finalBuy  = apply_adj($baseBuy,  $bp, $bf);
              ?>
              <tr>
                <td>
                  <b><?php echo h($label); ?></b>
                  <?php if ($liveOk): ?>
                    <div class="small">
                      <span class="badge">Mid: <?php echo h($CUR_PREFIX) . nf2($baseMid); ?> → <b><?php echo h($CUR_PREFIX) . nf2($finalMid); ?></b></span>
                      <span class="badge">Sell: <?php echo h($CUR_PREFIX) . nf2($baseSell); ?> → <b><?php echo h($CUR_PREFIX) . nf2($finalSell); ?></b></span>
                      <span class="badge">Buy: <?php echo h($CUR_PREFIX) . nf2($baseBuy); ?> → <b><?php echo h($CUR_PREFIX) . nf2($finalBuy); ?></b></span>
                    </div>
                  <?php else: ?>
                    <div class="small">Live preview will appear once API is available.</div>
                  <?php endif; ?>
                </td>

                <td>
                  <div class="grid">
                    <div>
                      <label class="small">% Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($qcode); ?>_mid_percent"
                        value="<?php echo h(val($existing,$qcode,'mid_percent')); ?>">
                    </div>
                    <div>
                      <label class="small">Flat Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($qcode); ?>_mid_flat"
                        value="<?php echo h(val($existing,$qcode,'mid_flat')); ?>">
                    </div>
                  </div>
                </td>

                <td>
                  <div class="grid">
                    <div>
                      <label class="small">% Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($qcode); ?>_sell_percent"
                        value="<?php echo h(val($existing,$qcode,'sell_percent')); ?>">
                    </div>
                    <div>
                      <label class="small">Flat Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($qcode); ?>_sell_flat"
                        value="<?php echo h(val($existing,$qcode,'sell_flat')); ?>">
                    </div>
                  </div>
                </td>

                <td>
                  <div class="grid">
                    <div>
                      <label class="small">% Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($qcode); ?>_buy_percent"
                        value="<?php echo h(val($existing,$qcode,'buy_percent')); ?>">
                    </div>
                    <div>
                      <label class="small">Flat Adjust</label>
                      <input type="number" step="0.0001" name="<?php echo h($qcode); ?>_buy_flat"
                        value="<?php echo h(val($existing,$qcode,'buy_flat')); ?>">
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