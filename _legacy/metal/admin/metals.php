<?php
// metal/admin/metals.php
require_once __DIR__ . '/../includes/auth.php';
requireAdminLogin();

require_once __DIR__ . '/../includes/db.php';
require_once __DIR__ . '/../lib/price_service.php';

/**
 * Page rules (as requested)
 * - Only PKR
 * - Only Gold (XAU) + Silver (XAG)
 * - Add "Rawa" category for gold (Rawa = 2x 24K)
 */
$PAGE_CURRENCIES = ['PKR'];
$PAGE_METALS     = ['XAU', 'XAG'];

function get_setting($k, $fallback = '') {
  global $conn;
  $stmt = $conn->prepare("SELECT v FROM settings WHERE k=? LIMIT 1");
  $stmt->bind_param('s', $k);
  $stmt->execute();
  $res = $stmt->get_result()->fetch_assoc();
  return $res ? $res['v'] : $fallback;
}

$displayCur  = 'PKR';
$CUR_PREFIX  = '₨ ';

function nf2($v): string {
  return number_format((float)$v, 2);
}

function safev($arr, $path, $fallback = null) {
  $cur = $arr;
  foreach ($path as $k) {
    if (!is_array($cur) || !array_key_exists($k, $cur)) return $fallback;
    $cur = $cur[$k];
  }
  return $cur;
}

// ----- Save adjustments (MID + SELL + BUY) -----
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['save'])) {
  foreach ($PAGE_METALS as $m) {
    foreach ($PAGE_CURRENCIES as $c) {
      $p_mid  = (float)($_POST["p_mid_{$m}_{$c}"] ?? 0);
      $f_mid  = (float)($_POST["f_mid_{$m}_{$c}"] ?? 0);
      $p_sell = (float)($_POST["p_sell_{$m}_{$c}"] ?? 0);
      $f_sell = (float)($_POST["f_sell_{$m}_{$c}"] ?? 0);
      $p_buy  = (float)($_POST["p_buy_{$m}_{$c}"] ?? 0);
      $f_buy  = (float)($_POST["f_buy_{$m}_{$c}"] ?? 0);

      $stmt = $conn->prepare("
        INSERT INTO price_adjustments
          (metal_code, currency_code,
           percent_adjust, flat_adjust,
           sell_percent_adjust, sell_flat_adjust,
           buy_percent_adjust,  buy_flat_adjust)
        VALUES (?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
          percent_adjust       = VALUES(percent_adjust),
          flat_adjust          = VALUES(flat_adjust),
          sell_percent_adjust  = VALUES(sell_percent_adjust),
          sell_flat_adjust     = VALUES(sell_flat_adjust),
          buy_percent_adjust   = VALUES(buy_percent_adjust),
          buy_flat_adjust      = VALUES(buy_flat_adjust)
      ");
      $stmt->bind_param('ssdddddd', $m, $c, $p_mid, $f_mid, $p_sell, $f_sell, $p_buy, $f_buy);
      $stmt->execute();
    }
  }
  $msg = 'Saved adjustments.';
}

// ----- Load adjustments for form -----
$adj = [];
$q = $conn->query("
  SELECT metal_code, currency_code,
         percent_adjust, flat_adjust,
         sell_percent_adjust, sell_flat_adjust,
         buy_percent_adjust,  buy_flat_adjust
  FROM price_adjustments
  WHERE currency_code='PKR'
");
while ($r = $q->fetch_assoc()) {
  $adj[$r['metal_code']][$r['currency_code']] = [
    'p_mid'  => (float)$r['percent_adjust'], 'f_mid'  => (float)$r['flat_adjust'],
    'p_sell' => (float)$r['sell_percent_adjust'], 'f_sell' => (float)$r['sell_flat_adjust'],
    'p_buy'  => (float)$r['buy_percent_adjust'],  'f_buy'  => (float)$r['buy_flat_adjust'],
  ];
}

// ----- First paint live prices -----
$live = build_response($displayCur);
$liveOk = is_array($live) && !empty($live['success']);
$liveByCode = [];
if ($liveOk) {
  foreach (($live['metals'] ?? []) as $m) {
    if (!empty($m['code'])) $liveByCode[$m['code']] = $m;
  }
  $updatedAt = date('Y-m-d H:i:s', (int)($live['timestamp'] ?? time()));
} else {
  $liveError = is_array($live) ? ($live['error']['info'] ?? 'Unknown error') : 'Unknown error';
  $updatedAt = '';
}
?>
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Metals & Adjustments</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
  <style>
    nav a { margin-right: 1rem }
    .grid {
      display:grid;
      gap:10px;
      grid-template-columns: 140px repeat(<?=count($PAGE_CURRENCIES)?>, minmax(280px,1fr));
      align-items:start;
    }
    .head { font-weight:700 }
    .small { font-size:.85rem; opacity:.9 }
    input[type=number]{ text-align:right }
    .live-card { display:grid; grid-template-columns: repeat(3, minmax(160px,1fr)); gap:8px; }
    .panel { border:1px solid var(--muted-border-color,#e5e7eb); border-radius:10px; padding:10px }
    .colhead { font-weight:700; font-size:.95rem; margin-bottom:6px }
    .badge { display:inline-block; padding:2px 10px; border-radius:999px; background:#eef2ff; font-size:.82rem }
    .warn { background:#fff6e5; border:1px solid #ffd48a; padding:.5rem .75rem; border-radius:10px }
    .krow { display:flex; gap:6px; flex-wrap:wrap }

    /* Price feel: white text always, but background flashes green/red based on last-2-decimal tick direction */
    .num{
      color:#fff;
      font-variant-numeric: tabular-nums;
      letter-spacing: .2px;
      padding: 1px 6px;
      border-radius: 8px;
      background: rgba(255,255,255,0.06);
      transition: background-color 180ms ease;
      display:inline-flex;
      align-items:baseline;
      gap:0;
    }
    .num.flash-up{ background: rgba(155, 231, 160, 0.35); }   /* light green */
    .num.flash-down{ background: rgba(255, 122, 122, 0.35); } /* red */

    .num .cur { opacity: .95; margin-right: 2px; }
    .num .dot { opacity: .9; }
    .num .dec{
      display:inline-block;
      min-width: 2ch;
      font-variant-numeric: tabular-nums;
    }

    fieldset { margin-bottom: 10px }
    legend { font-weight: 700; }

    /* Dark background-friendly container tweaks */
    body.container { background: #0b1220; color: #e8edf7; }
    article, details, .panel { background: rgba(255,255,255,0.03); }
    details>summary { cursor:pointer; }
    .badge { background: rgba(238,242,255,0.12); color: #e8edf7; }
    .warn { background: rgba(255, 246, 229, 0.12); border-color: rgba(255, 212, 138, 0.45); }
  </style>
</head>

<body class="container">
<nav>
  <a href="index.php">Dashboard</a>
  <strong>Metals & Adjustments</strong>
  <a href="settings.php">Settings</a>
  <a href="logout.php">Logout</a>
</nav>

<main>
  <h2>Per-Metal Adjustments (Mid / Sell / Buy)</h2>
  <?php if (!empty($msg)): ?><mark><?=$msg?></mark><?php endif; ?>

  <article>
    <header style="display:flex;gap:12px;align-items:center;flex-wrap:wrap">
      <h3 style="margin:0">Live Prices (PKR)</h3>
      <a role="button" href="?t=<?=time()?>">Refresh</a>
      <?php if ($updatedAt): ?>
        <span id="updatedAt" class="badge">Updated: <?=$updatedAt?> (<?=$displayCur?> <?=$CUR_PREFIX?>)</span>
      <?php endif; ?>
    </header>

    <?php if (!$liveOk): ?>
      <p class="warn">Couldn’t load live prices: <strong><?=htmlspecialchars($liveError)?></strong>. Check your API key in <a href="settings.php">Settings</a>.</p>
    <?php else: ?>
      <?php foreach ($PAGE_METALS as $mcode): $m = $liveByCode[$mcode] ?? null; ?>
        <details open>
          <summary><strong><?=htmlspecialchars(($m['name'] ?? ($mcode === 'XAU' ? 'Gold' : 'Silver')))?> (<?=$mcode?>)</strong></summary>

          <?php if ($m): ?>
            <div class="live-card">
              <div class="panel">
                <div class="colhead">Mid</div>
                <div class="small"><strong>Per Ounce:</strong> <span class="num" id="<?=$mcode?>_mid_oz"><?=$CUR_PREFIX?><?=nf2($m['per_oz'])?></span></div>
                <div class="small"><strong>Per Gram:</strong> <span class="num" id="<?=$mcode?>_mid_g"><?=$CUR_PREFIX?><?=nf2($m['per_gram'])?></span></div>
                <div class="small"><strong>Per Tola:</strong> <span class="num" id="<?=$mcode?>_mid_t"><?=$CUR_PREFIX?><?=nf2($m['per_tola'])?></span></div>
              </div>

              <div class="panel">
                <div class="colhead">Sell</div>
                <div class="small"><strong>Per Ounce:</strong> <span class="num" id="<?=$mcode?>_sell_oz"><?=$CUR_PREFIX?><?=nf2(safev($m, ['sell','per_oz'], 0))?></span></div>
                <div class="small"><strong>Per Gram:</strong> <span class="num" id="<?=$mcode?>_sell_g"><?=$CUR_PREFIX?><?=nf2(safev($m, ['sell','per_gram'], 0))?></span></div>
                <div class="small"><strong>Per Tola:</strong> <span class="num" id="<?=$mcode?>_sell_t"><?=$CUR_PREFIX?><?=nf2(safev($m, ['sell','per_tola'], 0))?></span></div>
              </div>

              <div class="panel">
                <div class="colhead">Buy</div>
                <div class="small"><strong>Per Ounce:</strong> <span class="num" id="<?=$mcode?>_buy_oz"><?=$CUR_PREFIX?><?=nf2(safev($m, ['buy','per_oz'], 0))?></span></div>
                <div class="small"><strong>Per Gram:</strong> <span class="num" id="<?=$mcode?>_buy_g"><?=$CUR_PREFIX?><?=nf2(safev($m, ['buy','per_gram'], 0))?></span></div>
                <div class="small"><strong>Per Tola:</strong> <span class="num" id="<?=$mcode?>_buy_t"><?=$CUR_PREFIX?><?=nf2(safev($m, ['buy','per_tola'], 0))?></span></div>
              </div>
            </div>

            <?php if ($mcode === 'XAU'): ?>
              <?php
                $midKar = safev($m, ['gold_by_karat_per_gram'], []);
                $selKar = safev($m, ['gold_by_karat_per_gram_sell'], []);
                $buyKar = safev($m, ['gold_by_karat_per_gram_buy'], []);
                $mid24  = isset($midKar['24K']) ? (float)$midKar['24K'] : null;
                $sel24  = isset($selKar['24K']) ? (float)$selKar['24K'] : null;
                $buy24  = isset($buyKar['24K']) ? (float)$buyKar['24K'] : null;

                $midRawa = $mid24 !== null ? $mid24 * 2.0 : null; // Rawa = double of 24K
                $selRawa = $sel24 !== null ? $sel24 * 2.0 : null;
                $buyRawa = $buy24 !== null ? $buy24 * 2.0 : null;
              ?>
              <div class="small" style="margin-top:10px">
                <strong>Gold per gram by Category:</strong>
                <div class="krow" style="margin-top:6px">
                  <?php foreach ($midKar as $k=>$v): ?>
                    <span class="badge">Mid <?=$k?>: <span class="num" id="XAU_mid_<?=$k?>"><?=$CUR_PREFIX?><?=nf2($v)?></span></span>
                  <?php endforeach; ?>
                  <?php if ($midRawa !== null): ?>
                    <span class="badge">Mid Rawa: <span class="num" id="XAU_mid_Rawa"><?=$CUR_PREFIX?><?=nf2($midRawa)?></span></span>
                  <?php endif; ?>

                  <?php foreach ($selKar as $k=>$v): ?>
                    <span class="badge" style="background:rgba(234,255,234,0.10)">Sell <?=$k?>: <span class="num" id="XAU_sell_<?=$k?>"><?=$CUR_PREFIX?><?=nf2($v)?></span></span>
                  <?php endforeach; ?>
                  <?php if ($selRawa !== null): ?>
                    <span class="badge" style="background:rgba(234,255,234,0.10)">Sell Rawa: <span class="num" id="XAU_sell_Rawa"><?=$CUR_PREFIX?><?=nf2($selRawa)?></span></span>
                  <?php endif; ?>

                  <?php foreach ($buyKar as $k=>$v): ?>
                    <span class="badge" style="background:rgba(255,234,234,0.10)">Buy <?=$k?>: <span class="num" id="XAU_buy_<?=$k?>"><?=$CUR_PREFIX?><?=nf2($v)?></span></span>
                  <?php endforeach; ?>
                  <?php if ($buyRawa !== null): ?>
                    <span class="badge" style="background:rgba(255,234,234,0.10)">Buy Rawa: <span class="num" id="XAU_buy_Rawa"><?=$CUR_PREFIX?><?=nf2($buyRawa)?></span></span>
                  <?php endif; ?>
                </div>
              </div>
            <?php endif; ?>

          <?php else: ?>
            <p class="warn">No live data available for <?=$mcode?> in <?=$displayCur?>.</p>
          <?php endif; ?>
        </details>
      <?php endforeach; ?>
    <?php endif; ?>
  </article>

  <form method="post" style="margin-top:1rem">
    <div class="grid">
      <div class="head">Metal \ Currency</div>
      <?php foreach ($PAGE_CURRENCIES as $c): ?><div class="head"><?=$c?></div><?php endforeach; ?>

      <?php foreach ($PAGE_METALS as $m): ?>
        <div><strong><?=$m?></strong></div>

        <?php foreach ($PAGE_CURRENCIES as $c):
          $a = $adj[$m][$c] ?? ['p_mid'=>0,'f_mid'=>0,'p_sell'=>0,'f_sell'=>0,'p_buy'=>0,'f_buy'=>0];
        ?>
          <div>
            <fieldset class="small">
              <legend>Mid</legend>
              <label>Percent (+/− %) <input step="0.0001" type="number" name="p_mid_<?=$m?>_<?=$c?>" value="<?=$a['p_mid']?>"></label>
              <label>Flat (+/− <?=$c?>) <input step="0.000001" type="number" name="f_mid_<?=$m?>_<?=$c?>" value="<?=$a['f_mid']?>"></label>
            </fieldset>

            <fieldset class="small">
              <legend>Sell</legend>
              <label>Percent (+/− %) <input step="0.0001" type="number" name="p_sell_<?=$m?>_<?=$c?>" value="<?=$a['p_sell']?>"></label>
              <label>Flat (+/− <?=$c?>) <input step="0.000001" type="number" name="f_sell_<?=$m?>_<?=$c?>" value="<?=$a['f_sell']?>"></label>
            </fieldset>

            <fieldset class="small">
              <legend>Buy</legend>
              <label>Percent (+/− %) <input step="0.0001" type="number" name="p_buy_<?=$m?>_<?=$c?>" value="<?=$a['p_buy']?>"></label>
              <label>Flat (+/− <?=$c?>) <input step="0.000001" type="number" name="f_buy_<?=$m?>_<?=$c?>" value="<?=$a['f_buy']?>"></label>
            </fieldset>
          </div>
        <?php endforeach; ?>

      <?php endforeach; ?>
    </div>

    <br>
    <button name="save" value="1">Save</button>
  </form>
</main>

<script>
const DISPLAY_CUR    = "PKR";
const CUR_PREFIX     = "₨ ";
const REFRESH_MS     = 10000; // keep real refresh
const DEC_TICK_MS    = 2000;  // your request: every 2 seconds
const DECIMALS       = 2;

const fmtUS = new Intl.NumberFormat('en-US', {
  minimumFractionDigits: DECIMALS,
  maximumFractionDigits: DECIMALS
});

function parseNumFromText(t){
  const s = String(t).replace(/,/g,'').replace(/[^0-9.\-]/g,'');
  const n = Number(s);
  return isFinite(n) ? n : 0;
}

function ensureStructured(el){
  if (!el || el.dataset.structured === "1") return;

  const raw = (el.textContent || "").trim();
  const idx = raw.search(/[0-9\-]/);
  const prefix = idx > 0 ? raw.slice(0, idx) : CUR_PREFIX;
  const numStr = idx >= 0 ? raw.slice(idx) : "0";
  const n = parseNumFromText(numStr);

  el.innerHTML = `
    <span class="cur"></span>
    <span class="int"></span><span class="dot">.</span><span class="dec"></span>
  `;
  el.querySelector('.cur').textContent = prefix;
  el.dataset.structured = "1";

  renderNumber(el, n);
}

function splitParts(n){
  const s = fmtUS.format(Number(n));
  const parts = s.split('.');
  return { i: parts[0], d: (parts[1] || "00").padEnd(2,'0').slice(0,2) };
}

function renderNumber(el, n){
  ensureStructured(el);
  const p = splitParts(n);
  el.querySelector('.int').textContent = p.i;
  el.querySelector('.dec').textContent = p.d;
  el.dataset.value = String(Number(n));
}

function flash(el, dir){
  el.classList.remove('flash-up','flash-down');
  if (dir === 'up') el.classList.add('flash-up');
  if (dir === 'down') el.classList.add('flash-down');
  if (!dir) return;

  window.clearTimeout(el._flashTimer);
  el._flashTimer = window.setTimeout(() => {
    el.classList.remove('flash-up','flash-down');
  }, 320);
}

/**
 * Every 2 seconds:
 * - Change ONLY the last 2 decimal digits (00..99)
 * - Keep text white
 * - Background flashes light green if decimals go up, red if go down
 */
function tickLastTwoDecimals(){
  document.querySelectorAll('.num').forEach(el => {
    ensureStructured(el);

    const cur = Number(el.dataset.value || "0");
    const whole = Math.floor(cur);

    // derive current cents from displayed value (0..99)
    let oldCents = Math.round((cur - whole) * 100);
    if (oldCents < 0) oldCents = 0;
    if (oldCents > 99) oldCents = 99;

    const newCents = Math.floor(Math.random() * 100); // 00..99
    const newVal = whole + (newCents / 100.0);

    let dir = '';
    if (newCents > oldCents) dir = 'up';
    else if (newCents < oldCents) dir = 'down';

    renderNumber(el, newVal);
    flash(el, dir);
  });
}

async function refreshOnce(){
  try{
    const url = `../api/latest.php?currency=${encodeURIComponent(DISPLAY_CUR)}&t=${Date.now()}`;
    const resp = await fetch(url, {headers:{'Accept':'application/json'}});
    if(!resp.ok) return;
    const json = await resp.json();
    if(json.success !== true) return;

    const ts = (json.timestamp||0) * 1000;
    const updatedAt = new Date(ts);
    const updEl = document.getElementById('updatedAt');
    if (updEl) {
      const stamp = updatedAt.toISOString().slice(0,19).replace('T',' ');
      updEl.textContent = `Updated: ${stamp} (${DISPLAY_CUR} ${CUR_PREFIX})`;
    }

    (json.metals||[]).forEach(m=>{
      const code = m.code;
      const pairs = [
        [`${code}_mid_oz`,   m.per_oz],
        [`${code}_mid_g`,    m.per_gram],
        [`${code}_mid_t`,    m.per_tola],

        [`${code}_sell_oz`,  m.sell?.per_oz],
        [`${code}_sell_g`,   m.sell?.per_gram],
        [`${code}_sell_t`,   m.sell?.per_tola],

        [`${code}_buy_oz`,   m.buy?.per_oz],
        [`${code}_buy_g`,    m.buy?.per_gram],
        [`${code}_buy_t`,    m.buy?.per_tola],
      ];

      pairs.forEach(([id,val])=>{
        if (val == null) return;
        const el = document.getElementById(id);
        if (el) renderNumber(el, Number(val));
      });

      if (code === 'XAU') {
        const midK  = m.gold_by_karat_per_gram || {};
        const sellK = m.gold_by_karat_per_gram_sell || {};
        const buyK  = m.gold_by_karat_per_gram_buy || {};

        Object.entries(midK).forEach(([k,v])=>{
          const el = document.getElementById(`XAU_mid_${k}`);
          if (el) renderNumber(el, Number(v));
        });
        Object.entries(sellK).forEach(([k,v])=>{
          const el = document.getElementById(`XAU_sell_${k}`);
          if (el) renderNumber(el, Number(v));
        });
        Object.entries(buyK).forEach(([k,v])=>{
          const el = document.getElementById(`XAU_buy_${k}`);
          if (el) renderNumber(el, Number(v));
        });

        // Rawa = 2x 24K (UI-side)
        const mid24  = Number(midK['24K'] ?? NaN);
        const sell24 = Number(sellK['24K'] ?? NaN);
        const buy24  = Number(buyK['24K'] ?? NaN);

        const elMidR = document.getElementById('XAU_mid_Rawa');
        const elSelR = document.getElementById('XAU_sell_Rawa');
        const elBuyR = document.getElementById('XAU_buy_Rawa');

        if (elMidR && Number.isFinite(mid24))  renderNumber(elMidR, mid24 * 2);
        if (elSelR && Number.isFinite(sell24)) renderNumber(elSelR, sell24 * 2);
        if (elBuyR && Number.isFinite(buy24))  renderNumber(elBuyR, buy24 * 2);
      }
    });
  } catch (e) {}
}

// First structure all numbers
document.querySelectorAll('.num').forEach(ensureStructured);

// Live refresh + 2-second decimal ticks
setInterval(refreshOnce, REFRESH_MS);
setInterval(tickLastTwoDecimals, DEC_TICK_MS);
</script>
</body>
</html>