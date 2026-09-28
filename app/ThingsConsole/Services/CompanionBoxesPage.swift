import Foundation

/// 箱子清理 Web 作业页：三 tab（箱子 / 出口区 / 方法），手机优先。
/// 方法论 = 一畳循环法：出口流 / 暂存流 / 归位流，物品永不落地。
enum CompanionBoxesPage {

    static let html = ##"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#f6f6f4" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#17171a" media="(prefers-color-scheme: dark)">
<title>箱子清理 · 物品管理台</title>
<style>
:root {
  color-scheme: light dark;
  --bg: #f6f6f4; --card: #ffffff; --text: #1d1d1f;
  --muted: #8a8a8e; --line: #e6e6e2; --accent: #0a84ff;
  --trash: #ff3b30; --donate: #0a84ff; --sell: #ff9f0a;
  --keep: #af52de; --home: #30d158; --pending: #8e8e93;
}
@media (prefers-color-scheme: dark) {
  :root { --bg: #17171a; --card: #202024; --text: #f2f2f5; --muted: #98989d; --line: #2d2d31; }
}
* { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
html { -webkit-text-size-adjust: 100%; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", sans-serif;
  background: var(--bg); color: var(--text); font-size: 16px; padding-bottom: 40px;
}
.wrap { max-width: 600px; margin: 0 auto; padding: 12px 14px 0; }
header { display: flex; align-items: baseline; justify-content: space-between; margin: 4px 2px 10px; }
h1 { font-size: 19px; font-weight: 700; letter-spacing: .3px; }
.tabs { display: flex; gap: 6px; position: sticky; top: 0; z-index: 5; background: var(--bg); padding: 8px 0; }
.tab {
  flex: 1; text-align: center; font-size: 14.5px; font-weight: 600; padding: 9px 0;
  border-radius: 10px; color: var(--muted); background: var(--card); border: 1px solid var(--line);
}
.tab.active { color: #fff; background: var(--accent); border-color: transparent; }
.tab .badge { font-size: 11px; font-weight: 700; margin-left: 4px; }
.stats { display: flex; gap: 14px; flex-wrap: wrap; padding: 10px 12px; background: var(--card); border: 1px solid var(--line); border-radius: 12px; margin-bottom: 12px; }
.stat b { font-size: 17px; font-variant-numeric: tabular-nums; display: block; }
.stat span { font-size: 11.5px; color: var(--muted); }
.card { background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 13px; margin-bottom: 10px; }
.box-row { display: flex; align-items: center; gap: 10px; padding: 11px 2px; border-bottom: 1px solid var(--line); }
.box-row:last-child { border-bottom: 0; }
.dot { width: 10px; height: 10px; border-radius: 50%; flex: none; }
.box-label { font-weight: 600; font-size: 15px; flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.box-meta { font-size: 12px; color: var(--muted); font-variant-numeric: tabular-nums; }
.chip-undecided { font-size: 11px; color: var(--sell); border: 1px solid var(--sell); border-radius: 99px; padding: 1px 7px; }
button { font-family: inherit; }
.btn {
  border: 0; border-radius: 11px; padding: 12px 16px; font-size: 16px; font-weight: 600;
  background: var(--accent); color: #fff; width: 100%;
}
.btn.secondary { background: var(--card); color: var(--text); border: 1px solid var(--line); }
.btn.small { padding: 8px 12px; font-size: 14px; width: auto; }
.btn:disabled { opacity: .45; }
.timer-bar { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
.timer { font-size: 26px; font-weight: 700; font-variant-numeric: tabular-nums; letter-spacing: .5px; }
input, select {
  width: 100%; font-size: 17px; padding: 11px 12px; border: 1px solid var(--line);
  border-radius: 10px; background: var(--bg); color: var(--text);
  -webkit-appearance: none; appearance: none;
}
input:focus, select:focus { outline: 2px solid var(--accent); outline-offset: -1px; }
.quick-add { display: flex; gap: 8px; margin: 10px 0; }
.quick-add input { flex: 1; }
.quick-add button { flex: none; width: 64px; border: 0; border-radius: 10px; background: var(--accent); color: #fff; font-size: 15px; font-weight: 600; }
.item { padding: 10px 2px; border-bottom: 1px solid var(--line); }
.item:last-child { border-bottom: 0; }
.item-head { display: flex; align-items: baseline; gap: 8px; }
.item-name { font-weight: 600; font-size: 15.5px; flex: 1; min-width: 0; }
.item-sub { font-size: 12px; color: var(--muted); }
.disp-row { display: flex; gap: 6px; margin-top: 8px; }
.disp {
  flex: 1; border: 0; border-radius: 9px; padding: 9px 0; font-size: 14px; font-weight: 600;
  color: var(--c); background: color-mix(in srgb, var(--c) 12%, transparent);
}
.disp.on { color: #fff; background: var(--c); }
.item.decided { opacity: .55; }
.exit-group-title { font-size: 14px; font-weight: 700; margin: 4px 2px 8px; }
.exit-row { display: flex; align-items: center; gap: 10px; padding: 9px 2px; border-bottom: 1px solid var(--line); }
.exit-row:last-child { border-bottom: 0; }
.sheet-mask { position: fixed; inset: 0; background: rgba(0,0,0,.35); z-index: 8; display: none; }
.sheet-mask.show { display: block; }
.sheet {
  position: fixed; left: 0; right: 0; bottom: 0; z-index: 9; background: var(--card);
  border-radius: 16px 16px 0 0; padding: 16px 16px calc(16px + env(safe-area-inset-bottom));
  display: none;
}
.sheet.show { display: block; }
.sheet h3 { font-size: 16px; margin-bottom: 10px; }
.sheet .row { display: flex; gap: 8px; margin-top: 10px; }
.method h2 { font-size: 16px; margin: 14px 0 6px; }
.method p, .method li { font-size: 14px; line-height: 1.75; color: var(--text); }
.method ul, .method ol { padding-left: 20px; }
.method .flow { display: flex; gap: 8px; margin: 10px 0; }
.method .flow div { flex: 1; border-radius: 10px; padding: 9px; font-size: 12.5px; line-height: 1.5; background: var(--bg); border: 1px solid var(--line); }
.method pre { font-size: 12.5px; line-height: 1.7; background: var(--bg); border: 1px solid var(--line); border-radius: 10px; padding: 10px; overflow-x: auto; font-family: inherit; }
.muted { color: var(--muted); font-size: 12.5px; }
.empty { text-align: center; color: var(--muted); font-size: 14px; padding: 26px 0; }
.back-line { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.back-line button { border: 0; background: none; color: var(--accent); font-size: 15px; font-weight: 600; padding: 4px 0; }
.staging-line { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.staging-line label { font-size: 13px; color: var(--muted); flex: none; }
.toast {
  position: fixed; top: 14px; left: 50%; transform: translateX(-50%);
  background: var(--text); color: var(--bg); font-size: 14px; padding: 9px 18px;
  border-radius: 99px; opacity: 0; transition: opacity .2s; pointer-events: none; z-index: 20;
}
.toast.show { opacity: .92; }
.hidden { display: none !important; }
.method h2 { font-size: 16.5px; margin: 22px 0 8px; padding-top: 14px; border-top: 1px solid var(--line); }
.method h2:first-child { border-top: 0; padding-top: 0; }
.method .flow div b { font-size: 13px; }
.tree { margin: 10px 0 4px; }
.t-node.start { display: inline-block; background: var(--accent); color: #fff; border-radius: 99px; padding: 7px 18px; font-weight: 700; font-size: 14px; margin-bottom: 4px; }
.t-step { border-left: 2px solid var(--line); margin-left: 16px; padding: 10px 0 10px 14px; }
.t-q { font-weight: 600; font-size: 14px; margin-bottom: 7px; line-height: 1.5; }
.t-branch { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; margin: 5px 0; font-size: 13px; }
.t-tag { font-size: 11px; font-weight: 700; border-radius: 6px; padding: 2px 8px; flex: none; }
.t-tag.yes { background: color-mix(in srgb, var(--home) 16%, transparent); color: var(--home); }
.t-tag.no { background: var(--bg); color: var(--muted); border: 1px solid var(--line); }
.t-down, .t-note { color: var(--muted); font-size: 12px; }
.pill { border-radius: 99px; padding: 4px 13px; font-size: 13px; font-weight: 600; color: #fff; white-space: nowrap; }
.pill.trash { background: var(--trash); }
.pill.donate { background: var(--donate); }
.pill.sell { background: var(--sell); }
.pill.keep { background: var(--keep); }
.pill.home { background: var(--home); }
.pill.pending { background: var(--pending); }
.t-step.warn { border-left-color: var(--sell); font-size: 13.5px; display: flex; align-items: center; gap: 7px; flex-wrap: wrap; line-height: 2; }
.step { border: 1px solid var(--line); border-radius: 12px; padding: 11px 13px; margin-bottom: 8px; background: var(--bg); }
.step-head { display: flex; align-items: center; gap: 9px; }
.step-n { width: 23px; height: 23px; border-radius: 50%; background: var(--accent); color: #fff; font-size: 12.5px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex: none; }
.step-head b { font-size: 15px; flex: 1; }
.step-time { font-size: 11.5px; color: var(--muted); flex: none; }
.step-do { font-size: 13.5px; line-height: 1.75; margin-top: 7px; }
.step details { margin-top: 7px; }
.step summary, .faq summary { font-size: 12.5px; color: var(--accent); cursor: pointer; font-weight: 600; }
.step details p { font-size: 12.5px; color: var(--muted); line-height: 1.8; margin-top: 5px; }
.walk { border: 1px solid var(--line); border-radius: 12px; padding: 4px 13px; background: var(--bg); }
.w-row { display: flex; gap: 11px; font-size: 13px; line-height: 1.65; padding: 8px 0; border-bottom: 1px dashed var(--line); }
.w-row:last-child { border-bottom: 0; }
.w-row b { color: var(--accent); font-variant-numeric: tabular-nums; flex: none; width: 40px; }
.faq { border-bottom: 1px solid var(--line); padding: 10px 2px; }
.faq:last-of-type { border-bottom: 0; }
.faq p { font-size: 13px; color: var(--muted); line-height: 1.8; margin-top: 6px; }
.map-row { display: flex; gap: 10px; font-size: 13px; padding: 8px 2px; border-bottom: 1px solid var(--line); line-height: 1.6; }
.map-row:last-child { border-bottom: 0; }
.map-row b { flex: none; width: 34%; font-weight: 600; }
.map-row span { color: var(--muted); }
.stg-row { display: flex; align-items: center; gap: 8px; padding: 9px 2px; border-bottom: 1px solid var(--line); flex-wrap: wrap; }
.stg-row:last-child { border-bottom: 0; }
.stg-name { flex: 1; min-width: 0; font-weight: 600; font-size: 14.5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.stg-row select { width: auto; flex: none; font-size: 13px; padding: 6px 8px; max-width: 118px; }
.method ul { margin-top: 4px; }
</style>
</head>
<body>
<div class="wrap">
  <header>
    <h1>箱子清理</h1>
    <span class="muted" id="header-sub"></span>
  </header>

  <div class="tabs">
    <div class="tab active" id="tab-boxes" onclick="switchTab('boxes')">箱子</div>
    <div class="tab" id="tab-exit" onclick="switchTab('exit')">出口区<span class="badge" id="exit-badge"></span></div>
    <div class="tab" id="tab-staging" onclick="switchTab('staging')">暂存<span class="badge" id="staging-badge"></span></div>
    <div class="tab" id="tab-method" onclick="switchTab('method')">方法</div>
  </div>

  <!-- 箱子 tab -->
  <section id="page-boxes">
    <div class="stats" id="stats"></div>
    <div id="box-list-view">
      <div class="card" id="box-list"></div>
      <p class="muted" style="margin:6px 2px">箱子在 Mac 端「箱子清理」页批量创建。点箱子开始作业。</p>
    </div>

    <div id="box-work-view" class="hidden">
      <div class="back-line">
        <button onclick="closeBox()">‹ 箱子列表</button>
        <b id="work-title" style="font-size:16px"></b>
        <span class="muted" id="work-status"></span>
      </div>
      <div class="card">
        <div class="timer-bar">
          <span class="timer" id="timer">0:00:00</span>
          <button class="btn small" id="timer-btn" onclick="toggleTimer()">开始计时</button>
          <span class="muted" id="timer-total"></span>
        </div>
        <div class="staging-line">
          <label>当前暂存箱</label>
          <input id="staging-name" style="font-size:15px;padding:8px 10px" onchange="saveStaging()">
        </div>
        <div class="quick-add">
          <input id="quick-name" placeholder="拿出物品 → 输名称回车" autocomplete="off" autocapitalize="off">
          <button onclick="quickAdd()">录入</button>
        </div>
        <div id="item-list"></div>
      </div>
      <div style="display:flex;gap:8px">
        <button class="btn secondary" id="sorted-btn" onclick="setBoxStatus('已归类')">标记已归类</button>
        <button class="btn" id="done-btn" onclick="completeBox()">完成箱子</button>
      </div>
    </div>
  </section>

  <!-- 出口区 tab -->
  <section id="page-exit" class="hidden">
    <div class="stats" id="exit-stats"></div>
    <div id="exit-groups"></div>
    <button class="btn" id="exit-all-btn" onclick="executeExit(null)" style="margin-top:6px">全部已带出（出门一趟）</button>
    <p class="muted" style="margin:8px 2px">带出 = 物品退役出口袋。每带出一袋，房间就多出一袋的空间——这是整个方法的发动机。</p>
  </section>

  <!-- 暂存 tab -->
  <section id="page-staging" class="hidden">
    <div class="stats" id="staging-stats"></div>
    <div id="staging-groups"></div>
    <p class="muted" style="margin:8px 2px">二次清：给每件定分类、再归位到真实位置——位置不再是暂存箱后自动离开本列表。期限：主体清完后一周内。</p>
  </section>

  <!-- 方法 tab -->
  <section id="page-method" class="hidden">
  <div class="card method">

    <h2 style="margin-top:0">0 · 先看图：你现在的处境</h2>
    <svg viewBox="0 0 340 200" style="width:100%;height:auto" role="img" aria-label="房间俯视示意图：箱子堆满，仅剩一个工作位">
      <text x="12" y="10" font-size="10.5" fill="var(--muted)">房间（俯视）：箱子堆满，只剩虚线处能站人</text>
      <rect x="12" y="18" width="228" height="146" fill="none" stroke="var(--line)" stroke-width="3"/>
      <rect x="110" y="160" width="34" height="8" fill="var(--bg)"/>
      <g fill="var(--muted)" fill-opacity="0.22" stroke="var(--muted)" stroke-opacity="0.45" stroke-width="1">
        <rect x="18" y="24" width="40" height="38" rx="3"/><rect x="62" y="24" width="40" height="38" rx="3"/><rect x="106" y="24" width="40" height="38" rx="3"/><rect x="150" y="24" width="40" height="38" rx="3"/><rect x="194" y="24" width="40" height="38" rx="3"/>
        <rect x="18" y="66" width="40" height="38" rx="3"/><rect x="62" y="66" width="40" height="38" rx="3"/><rect x="150" y="66" width="40" height="38" rx="3"/><rect x="194" y="66" width="40" height="38" rx="3"/>
        <rect x="18" y="108" width="40" height="38" rx="3"/><rect x="62" y="108" width="40" height="38" rx="3"/><rect x="106" y="108" width="40" height="38" rx="3"/><rect x="150" y="108" width="40" height="38" rx="3"/><rect x="194" y="108" width="40" height="38" rx="3"/>
      </g>
      <rect x="106" y="66" width="40" height="38" rx="3" fill="none" stroke="var(--accent)" stroke-width="2" stroke-dasharray="5 3"/>
      <text x="126" y="83" font-size="10" fill="var(--accent)" text-anchor="middle" font-weight="600">工作位</text>
      <text x="126" y="96" font-size="8.5" fill="var(--accent)" text-anchor="middle">≈ 2㎡</text>
      <line x1="127" y1="158" x2="126" y2="106" stroke="var(--accent)" stroke-width="1.5" stroke-dasharray="4 3"/>
      <circle cx="127" cy="181" r="13" fill="var(--trash)" fill-opacity="0.85"/>
      <text x="127" y="185" font-size="9.5" fill="#fff" text-anchor="middle" font-weight="600">出口袋</text>
      <text x="160" y="185" font-size="9.5" fill="var(--muted)">← 挂在门口，伸手就够到</text>
      <rect x="252" y="18" width="76" height="146" fill="none" stroke="var(--line)" stroke-width="2" stroke-dasharray="6 4"/>
      <g fill="var(--muted)" fill-opacity="0.22" stroke="var(--muted)" stroke-opacity="0.45" stroke-width="1">
        <rect x="258" y="24" width="20" height="18" rx="2"/><rect x="282" y="24" width="20" height="18" rx="2"/><rect x="306" y="24" width="16" height="18" rx="2"/>
        <rect x="258" y="46" width="20" height="18" rx="2"/><rect x="282" y="46" width="20" height="18" rx="2"/><rect x="306" y="46" width="16" height="18" rx="2"/>
        <rect x="258" y="68" width="20" height="18" rx="2"/><rect x="282" y="68" width="20" height="18" rx="2"/><rect x="306" y="68" width="16" height="18" rx="2"/>
      </g>
      <text x="290" y="150" font-size="9.5" fill="var(--muted)" text-anchor="middle">外面空地（也满了）</text>
    </svg>
    <p style="font-size:13.5px;line-height:1.8;margin-top:8px">常规整理法（KonMari / 断舍离）都默认你有空地<b>把东西全部摊开</b>再集中比对。你现在摊不开——摊开等于堵死通道。所以这套方法的目标不是「整理」，而是<b>让物品和空间单向流动起来</b>。</p>

    <h2>1 · 核心思路（一句话）</h2>
    <p style="font-size:15px;line-height:1.9;background:var(--bg);border:1px solid var(--line);border-radius:10px;padding:12px">每拿起一件物品，<b>3 秒内</b>决定它进哪条流；出手即入流，<b>永远不放在地上</b>「待会儿再说」。</p>

    <h2>2 · 三条流：物品的唯一三个去向</h2>
    <svg viewBox="0 0 340 195" style="width:100%;height:auto" role="img" aria-label="三流图：物品分流到出口袋、暂存箱、归位">
      <defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="var(--muted)"/></marker></defs>
      <circle cx="48" cy="97" r="25" fill="var(--accent)" fill-opacity="0.14" stroke="var(--accent)" stroke-width="1.5"/>
      <text x="48" y="94" font-size="12" fill="var(--accent)" text-anchor="middle" font-weight="700">一件</text>
      <text x="48" y="108" font-size="12" fill="var(--accent)" text-anchor="middle" font-weight="700">物品</text>
      <path d="M 70 84 Q 130 40 196 34" fill="none" stroke="var(--muted)" stroke-width="1.5" marker-end="url(#ah)"/>
      <path d="M 74 97 L 196 97" fill="none" stroke="var(--muted)" stroke-width="1.5" marker-end="url(#ah)"/>
      <path d="M 70 110 Q 130 154 196 160" fill="none" stroke="var(--muted)" stroke-width="1.5" marker-end="url(#ah)"/>
      <text x="128" y="46" font-size="10" fill="var(--muted)" text-anchor="middle">不要了</text>
      <text x="132" y="90" font-size="10" fill="var(--muted)" text-anchor="middle">留，但现在没地方归</text>
      <text x="128" y="156" font-size="10" fill="var(--muted)" text-anchor="middle">留，且有固定位置</text>
      <rect x="200" y="12" width="132" height="44" rx="10" fill="var(--trash)" fill-opacity="0.12" stroke="var(--trash)"/>
      <text x="266" y="30" font-size="11.5" fill="var(--trash)" text-anchor="middle" font-weight="700">出口袋 · 扔/捐/卖</text>
      <text x="266" y="46" font-size="9.5" fill="var(--muted)" text-anchor="middle">挂门口，满即带出门</text>
      <rect x="200" y="75" width="132" height="44" rx="10" fill="var(--keep)" fill-opacity="0.12" stroke="var(--keep)"/>
      <text x="266" y="93" font-size="11.5" fill="var(--keep)" text-anchor="middle" font-weight="700">暂存箱 · 集中停放</text>
      <text x="266" y="109" font-size="9.5" fill="var(--muted)" text-anchor="middle">同一时间只开一个</text>
      <rect x="200" y="138" width="132" height="44" rx="10" fill="var(--home)" fill-opacity="0.12" stroke="var(--home)"/>
      <text x="266" y="156" font-size="11.5" fill="var(--home)" text-anchor="middle" font-weight="700">归位 · 放回原处</text>
      <text x="266" y="172" font-size="9.5" fill="var(--muted)" text-anchor="middle">衣柜 / 抽屉 / 架子</text>
      <text x="170" y="192" font-size="10" fill="var(--trash)" text-anchor="middle">✕ 禁止第四种状态：放在地上「待会儿再说」</text>
    </svg>
    <div class="flow">
      <div><b style="color:var(--trash)">出口流</b><br>物理离开房间 = 空间真正回来。这是发动机。</div>
      <div><b style="color:var(--keep)">暂存流</b><br>把「现在做不了的归类决定」推迟到有空地时，不是失败。</div>
      <div><b style="color:var(--home)">归位流</b><br>有位置的直接放回，不经过任何中间堆放。</div>
    </div>

    <h2>3 · 每件物品怎么判：决策树</h2>
    <div class="tree">
      <div class="t-node start">拿起一件物品</div>
      <div class="t-step">
        <div class="t-q">Q1 · 明显是垃圾 / 坏的 / 过期的？</div>
        <div class="t-branch"><span class="t-tag yes">是</span><span class="pill trash">扔 → 出口袋</span></div>
        <div class="t-branch"><span class="t-tag no">否</span><span class="t-down">↓ 继续问</span></div>
      </div>
      <div class="t-step">
        <div class="t-q">Q2 · 确定以后不会再用了？</div>
        <div class="t-branch"><span class="t-tag yes">是</span><span class="t-note">还能用 →</span><span class="pill donate">捐</span><span class="pill sell">卖</span><span class="t-note">；不能用 →</span><span class="pill trash">扔</span></div>
        <div class="t-branch"><span class="t-tag no">否</span><span class="t-down">↓ 继续问</span></div>
      </div>
      <div class="t-step">
        <div class="t-q">Q3 · 它有一个现在就能放回去的固定位置？</div>
        <div class="t-branch"><span class="t-tag yes">是</span><span class="pill home">归位</span></div>
        <div class="t-branch"><span class="t-tag no">否</span><span class="pill keep">进当前暂存箱</span></div>
      </div>
      <div class="t-step warn">⚠ 任何一问卡住超过 5 秒 → <span class="pill pending">待定 · 进暂存箱</span><span class="t-down">别让一件卡住一箱</span></div>
    </div>

    <h2>4 · 一轮作业：七步 SOP</h2>
    <div class="step">
      <div class="step-head"><span class="step-n">1</span><b>开道</b><span class="step-time">约 5 分钟</span></div>
      <p class="step-do">从门口到工作位，清出一条能过「一人 + 一箱」的通道；把出口袋（大垃圾袋或一个空箱）挂在门口。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：出口必须伸手可及，「满即带出」才做得动；通道不开，搬箱都费劲。<br>常见错误：跳过这步直接开箱——物品没处放，第一轮就卡死。</p></details>
    </div>
    <div class="step">
      <div class="step-head"><span class="step-n">2</span><b>取箱就人</b><span class="step-time">约 1 分钟</span></div>
      <p class="step-do">这一轮只选一箱，把它搬到工作位再开。搬箱子，不在堆里就地掏。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：就地掏会让堆体塌方；同时开多个箱 = 多个灾难现场。搬箱就人保证任何时刻只有一个箱是开的。<br>常见错误：嫌搬着麻烦就地开——这是复乱的最大来源。</p></details>
    </div>
    <div class="step">
      <div class="step-head"><span class="step-n">3</span><b>出口优先</b><span class="step-time">头 2 分钟</span></div>
      <p class="step-do">开箱后先不做精细判断：只挑明显的垃圾、破损、过期品，全部进出口袋。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：先在箱内制造空隙，后面翻找不塌方；扔是回收空间最快的动作，先做它士气也起来了。<br>常见错误：这一步翻到旧照片开始怀旧——垃圾先行，怀旧押后。</p></details>
    </div>
    <div class="step">
      <div class="step-head"><span class="step-n">4</span><b>三秒决策</b><span class="step-time">15–20 分钟</span></div>
      <p class="step-do">逐件：拿出 → 输名称录入 → 按六个大按钮之一（扔 / 捐 / 卖 / 暂存 / 归位 / 待定）。按决策树走，单件不超过几秒。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：限时决策防呆——一箱 30 件，每件纠结 1 分钟就要半小时；3 秒规则让流水线不停。<br>常见错误：想着「万一以后用得上」——超过 5 秒就待定进暂存箱，规则大于个案。</p></details>
    </div>
    <div class="step">
      <div class="step-head"><span class="step-n">5</span><b>空箱回收</b><span class="step-time">约 1 分钟</span></div>
      <p class="step-do">箱子清空后立刻压扁靠墙叠放；或者写上「暂存箱B」直接投入使用。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：空箱不压扁会继续占一个工作位的面积；压扁 = 地面立刻回笼，进度看得见。<br>常见错误：空箱留着「回头装东西」——5 分钟内用不上就压扁。</p></details>
    </div>
    <div class="step">
      <div class="step-head"><span class="step-n">6</span><b>满即带出</b><span class="step-time">5–10 分钟</span></div>
      <p class="step-do">出口袋满了（或本轮扔件凑齐）就立刻出门：垃圾站 / 捐赠点 / 车后备箱。App 出口区点「已带出」销账。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：这是整个方法的发动机——物品物理离开房间，空间才真正回来；袋放门口等于没清。<br>常见错误：「等周末一起扔」——出口袋会被慢慢塞回房间里。扔不等满，每轮随手带出。</p></details>
    </div>
    <div class="step">
      <div class="step-head"><span class="step-n">7</span><b>暂存二次清</b><span class="step-time">另择整轮</span></div>
      <p class="step-do">主体箱子清完、地面空出来后，每个暂存箱单独开一轮：逐件归位，这次有条件做精细归类了。</p>
      <details><summary>为什么 · 常见错误</summary><p>为什么：暂存是「停车场」不是「仓库」；限期（主体清完后一周内）防止停车变永久停放。<br>常见错误：不停开新暂存箱却从不二次清——同时开启的暂存箱不要超过 2 个。</p></details>
    </div>

    <h2>5 · 示例：一轮 25 分钟长什么样</h2>
    <div class="walk">
      <div class="w-row"><b>0:00</b><span>开道，挂出口袋，把第 3 箱搬到工作位</span></div>
      <div class="w-row"><b>0:02</b><span>按下计时。先只挑垃圾：断衣架、过期券、碎数据线 → 出口袋 5 件</span></div>
      <div class="w-row"><b>0:08</b><span>逐件录入：旧课本 → 卖；毛线团 → 待定；去年冬衣 → 暂存箱A；药盒 → 归位（玄关柜）</span></div>
      <div class="w-row"><b>0:20</b><span>第 3 箱已空出 1/3，把翻乱的部分收拢；旁边第 4 箱先不动</span></div>
      <div class="w-row"><b>0:25</b><span>铃响即停。本轮：录入 17 件 · 扔4 · 卖5 · 暂存6 · 归位2 · 待定0</span></div>
      <div class="w-row"><b>0:30</b><span>扔件单独扎袋拎下楼。复盘一句话：房间没有变乱，回来了 4 件的空间 + 半箱的空隙</span></div>
    </div>
    <p class="muted" style="margin-top:6px">注意：这一轮箱子没有「完成」也完全没关系——最小胜利单位是「有东西出门」，不是「清完一箱」。</p>

    <h2>6 · 节奏与完成标准</h2>
    <ul>
      <li>每轮 15–25 分钟计时，铃响即停，不透支；每天 1–2 轮就够</li>
      <li>一轮的最小完成单位 = <b>有东西离开房间</b>，哪怕只有 2 件扔</li>
      <li>按每轮推进 2–3 箱估算：50 箱 ≈ 20–25 轮 ≈ 每天 1–2 轮，两三周清完</li>
      <li><b>战役完成标准</b>：所有箱子压扁或归架 · 出口区待出门 = 0 · 暂存箱 ≤ 2 个且已排二次清 · 走进房间不需要侧身绕路</li>
    </ul>

    <h2>7 · 常见问题</h2>
    <details class="faq"><summary>进暂存箱是不是等于逃避、白整理了？</summary><p>不是。暂存是把「现在没有条件做的归类决定」推迟到有空地的时候——决定没有消失，只是排期了。有二次清期限兜底（主体清完一周内），过期未处理的按默认规则走：捐。</p></details>
    <details class="faq"><summary>为什么不能就地掏箱子？我明明只拿几件。</summary><p>掏洞会让上面的箱子失去支撑塌方，而且掏出来的东西没处放，最后摊在通道上——第二轮连站的地方都没有。搬箱就人保证现场永远只有「一箱 + 一袋 + 一暂存箱」三个容器。</p></details>
    <details class="faq"><summary>出口袋没满，要不要等满了再出门？</summary><p>扔不等满：每轮结束的垃圾随手带出，绝不隔夜。捐 / 卖可以等凑一批（捐赠点有开放时间、卖货要拍照上架），但别超过一周——出口区数字一直挂着，就是提醒你出门。</p></details>
    <details class="faq"><summary>家人会把东西又塞回来怎么办？</summary><p>给暂存箱编号并在家庭群公告：「箱内物品 = 待定，期限 X 月 X 日，过期默认捐」。把规则交给日期，不靠拉锯。</p></details>
    <details class="faq"><summary>录入 App 会不会拖慢速度？</summary><p>录入只花 3 秒（输名称 + 按一个处置按钮），换来的是：出口区自动记账、暂存箱内容可查、进度和耗时可视。如果某件东西实在不值得录（纯垃圾），直接扔、不录也行——台账是工具不是任务。</p></details>
    <details class="faq"><summary>50 箱要清到什么时候？会不会永远清不完？</summary><p>不会。按每轮 25 分钟推进 2–3 箱算，20–25 轮收尾，每天 1–2 轮就是两三周。关键不是单日猛干，是「每天有一袋出门」——空间每天回笼一点，正反馈会推着你走完。</p></details>

    <h2>8 · 方法 ↔ 页面按钮对照</h2>
    <div class="map-row"><b>轮次计时</b><span>作业屏计时器（每 30 秒自动上报，锁屏也不丢）</span></div>
    <div class="map-row"><b>出口袋</b><span>「出口区」tab——待出门数字 = 袋子有多满</span></div>
    <div class="map-row"><b>当前暂存箱</b><span>作业屏顶部输入框，换箱时改名（暂存箱A → B）</span></div>
    <div class="map-row"><b>三秒决策</b><span>每件物品下方六个大按钮：扔 / 捐 / 卖 / 暂存 / 归位 / 待定</span></div>
    <div class="map-row"><b>箱子的生命周期</b><span>未开封 → 清理中（按开始计时自动转）→ 已归类 → 已完成</span></div>
    <div class="map-row"><b>满即带出</b><span>出口区「已带出」按钮——物品自动退役销账</span></div>

  </div>
</section>
</div>

<div class="toast" id="toast"></div>

<div class="sheet-mask" id="sheet-mask" onclick="closeSheet()"></div>
<div class="sheet" id="loc-sheet">
  <h3>归位到哪里？</h3>
  <input id="loc-input" list="loc-list" placeholder="如：书房抽屉" autocomplete="off">
  <datalist id="loc-list"></datalist>
  <div class="row">
    <button class="btn secondary" onclick="closeSheet()">取消</button>
    <button class="btn" onclick="confirmRelocate()">归位</button>
  </div>
</div>

<script>
var KEY = new URLSearchParams(location.search).get('k') || '';
function withKey(url) { return url + (url.indexOf('?') < 0 ? '?' : '&') + 'k=' + encodeURIComponent(KEY); }
function api(path, options) { return fetch(withKey(path), options).then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); }); }
function post(path, body) { return api(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }); }
function patch(path, body) { return api(path, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }); }

var state = { boxes: [], stats: null, currentBox: null, items: [], exit: null, cats: [] };
var timer = { running: false, startedAt: null, unreported: 0, tick: null };
var relocateTarget = null;

var DISPOSITIONS = [
  { key: 'trash', label: '扔', color: 'var(--trash)' },
  { key: 'donate', label: '捐', color: 'var(--donate)' },
  { key: 'sell', label: '卖', color: 'var(--sell)' },
  { key: 'keep', label: '暂存', color: 'var(--keep)' },
  { key: 'relocate', label: '归位', color: 'var(--home)' },
  { key: 'pending', label: '待定', color: 'var(--pending)' },
];

function showToast(text) {
  var toast = document.getElementById('toast');
  toast.textContent = text;
  toast.classList.add('show');
  setTimeout(function () { toast.classList.remove('show'); }, 1500);
}

function fmtTime(seconds) {
  var h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60), s = seconds % 60;
  return h + ':' + (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
}

function switchTab(name) {
  ['boxes', 'exit', 'staging', 'method'].forEach(function (tabName) {
    document.getElementById('tab-' + tabName).classList.toggle('active', tabName === name);
    document.getElementById('page-' + tabName).classList.toggle('hidden', tabName !== name);
  });
  if (name === 'exit') loadExit();
  if (name === 'staging') loadStaging();
  if (name === 'boxes') loadBoxes();
}

// MARK: 箱子列表

function loadBoxes() {
  api('/api/boxes').then(function (data) {
    state.boxes = data.boxes;
    state.stats = data.stats;
    renderStats();
    renderBoxList();
  }).catch(function (e) { showToast('加载失败：' + e.message); });
}

function renderStats() {
  var s = state.stats || {};
  document.getElementById('header-sub').textContent = (s.completed || 0) + '/' + (s.total || 0) + ' 箱';
  document.getElementById('stats').innerHTML =
    stat((s.completed || 0) + '/' + (s.total || 0), '完成箱子') +
    stat(fmtTime(s.timeSpentSeconds || 0), '总耗时') +
    stat(s.pendingExit || 0, '待出门') +
    stat(s.staging || 0, '暂存中');
  var badge = document.getElementById('exit-badge');
  badge.textContent = s.pendingExit > 0 ? ' ' + s.pendingExit : '';
  badge.style.color = s.pendingExit > 0 ? 'var(--trash)' : 'inherit';
  var sbadge = document.getElementById('staging-badge');
  sbadge.textContent = s.staging > 0 ? ' ' + s.staging : '';
  sbadge.style.color = s.staging > 0 ? 'var(--keep)' : 'inherit';
}

function stat(value, label) {
  return '<div class="stat"><b>' + value + '</b><span>' + label + '</span></div>';
}

function statusColor(status) {
  if (status === '清理中') return 'var(--accent)';
  if (status === '已归类') return 'var(--sell)';
  if (status === '已完成') return 'var(--home)';
  return 'var(--pending)';
}

function renderBoxList() {
  var list = document.getElementById('box-list');
  if (!state.boxes.length) {
    list.innerHTML = '<div class="empty">还没有箱子——先在 Mac 端「箱子清理」页批量创建</div>';
    return;
  }
  list.innerHTML = state.boxes.map(function (box) {
    var undecided = box.undecidedCount > 0 ? '<span class="chip-undecided">' + box.undecidedCount + ' 待决</span>' : '';
    return '<div class="box-row" onclick="openBox(\'' + box.id + '\')">' +
      '<span class="dot" style="background:' + statusColor(box.status) + '"></span>' +
      '<span class="box-label">' + escapeHtml(box.label) + '</span>' + undecided +
      '<span class="box-meta">' + box.itemCount + ' 件' + (box.timeSpentSeconds > 0 ? ' · ' + fmtTime(box.timeSpentSeconds) : '') + '</span>' +
      '</div>';
  }).join('');
}

function escapeHtml(text) {
  var div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}

// MARK: 单箱作业

function openBox(id) {
  var box = state.boxes.filter(function (b) { return b.id === id; })[0];
  if (!box) return;
  state.currentBox = box;
  document.getElementById('box-list-view').classList.add('hidden');
  document.getElementById('box-work-view').classList.remove('hidden');
  document.getElementById('work-title').textContent = box.label;
  document.getElementById('work-status').textContent = box.status;
  document.getElementById('timer-total').textContent = box.timeSpentSeconds > 0 ? '已累计 ' + fmtTime(box.timeSpentSeconds) : '';
  document.getElementById('sorted-btn').classList.toggle('hidden', box.status === '已归类' || box.status === '已完成');
  document.getElementById('done-btn').classList.toggle('hidden', box.status === '已完成');
  try { localStorage.setItem('boxes.lastBoxId', id); } catch (e) {}
  loadItems();
}

function closeBox() {
  flushTimer();
  stopTimerUI();
  state.currentBox = null;
  try { localStorage.removeItem('boxes.lastBoxId'); } catch (e) {}
  document.getElementById('box-work-view').classList.add('hidden');
  document.getElementById('box-list-view').classList.remove('hidden');
  loadBoxes();
}

function loadItems() {
  if (!state.currentBox) return;
  api('/api/boxes/' + state.currentBox.id + '/items').then(function (data) {
    state.items = data.items;
    renderItems();
  });
}

function renderItems() {
  var list = document.getElementById('item-list');
  if (!state.items.length) {
    list.innerHTML = '<div class="empty">箱子里还没录入物品<br>拿出来一件 → 输名称 → 点处置</div>';
    return;
  }
  list.innerHTML = state.items.map(function (item) {
    var buttons = DISPOSITIONS.map(function (d) {
      var on = item.disposition === d.label || (d.key === 'keep' && item.disposition === '留');
      return '<button class="disp' + (on ? ' on' : '') + '" style="--c:' + d.color + '" onclick="decide(\'' + item.id + '\',\'' + d.key + '\')">' + d.label + '</button>';
    }).join('');
    var sub = [item.location].filter(Boolean).join(' · ');
    return '<div class="item' + (item.disposition ? ' decided' : '') + '">' +
      '<div class="item-head"><span class="item-name">' + escapeHtml(item.name) + '</span>' +
      (sub ? '<span class="item-sub">' + escapeHtml(sub) + '</span>' : '') + '</div>' +
      '<div class="disp-row">' + buttons + '</div></div>';
  }).join('');
}

function decide(itemId, kind) {
  var item = state.items.filter(function (i) { return i.id === itemId; })[0];
  if (!item) return;
  if (kind === 'relocate') { openLocSheet(itemId); return; }
  var mapping = { trash: '扔', donate: '捐', sell: '卖', keep: '留', pending: '待定' };
  var next = mapping[kind];
  var already = item.disposition === next;
  var body = { disposition: already ? null : next };
  var stagingValue = document.getElementById('staging-name').value || '暂存箱A';
  if (!already && kind === 'keep') body.location = stagingValue;
  if (!already && kind === 'pending' && (item.location || '').indexOf('暂存') !== 0) body.location = stagingValue;
  patch('/api/items/' + itemId, body).then(function () {
    item.disposition = body.disposition;
    if (body.location) item.location = body.location;
    renderItems();
    if (!already && (kind === 'trash' || kind === 'donate' || kind === 'sell')) showToast('→ 出口区');
  }).catch(function (e) { showToast('失败：' + e.message); });
}

function openLocSheet(itemId) {
  relocateTarget = itemId;
  document.getElementById('loc-input').value = '';
  document.getElementById('sheet-mask').classList.add('show');
  document.getElementById('loc-sheet').classList.add('show');
  api('/api/bootstrap').then(function (data) {
    var list = document.getElementById('loc-list');
    list.innerHTML = (data.locations || []).map(function (name) { return '<option value="' + escapeHtml(name) + '">'; }).join('');
  }).catch(function () {});
  setTimeout(function () { document.getElementById('loc-input').focus(); }, 50);
}

function closeSheet() {
  document.getElementById('sheet-mask').classList.remove('show');
  document.getElementById('loc-sheet').classList.remove('show');
  relocateTarget = null;
}

function confirmRelocate() {
  var loc = document.getElementById('loc-input').value.trim();
  if (!loc) { showToast('填写归位位置'); return; }
  var itemId = relocateTarget;
  closeSheet();
  patch('/api/items/' + itemId, { disposition: '挪', location: loc }).then(function () {
    var item = state.items.filter(function (i) { return i.id === itemId; })[0];
    if (item) { item.disposition = '挪'; item.location = loc; }
    renderItems();
  }).catch(function (e) { showToast('失败：' + e.message); });
}

function quickAdd() {
  var input = document.getElementById('quick-name');
  var name = input.value.trim();
  if (!name || !state.currentBox) return;
  post('/api/boxes/' + state.currentBox.id + '/items', { name: name }).then(function () {
    input.value = '';
    input.focus();
    loadItems();
  }).catch(function (e) { showToast('录入失败：' + e.message); });
}

document.getElementById('quick-name').addEventListener('keydown', function (event) {
  if (event.key === 'Enter') quickAdd();
});

function saveStaging() {
  try { localStorage.setItem('boxes.stagingName', document.getElementById('staging-name').value); } catch (e) {}
}

// MARK: 计时器（30s 心跳上报，暂停/离开结清）

function toggleTimer() {
  if (timer.running) { pauseTimer(); } else { startTimer(); }
}

function startTimer() {
  if (!state.currentBox) return;
  if (state.currentBox.status === '未开封') {
    patch('/api/boxes/' + state.currentBox.id, { status: '清理中' }).then(function () {
      state.currentBox.status = '清理中';
      document.getElementById('work-status').textContent = '清理中';
    });
  }
  timer.running = true;
  timer.startedAt = Date.now();
  timer.unreported = 0;
  document.getElementById('timer-btn').textContent = '暂停';
  timer.tick = setInterval(function () {
    document.getElementById('timer').textContent = fmtTime(Math.floor((Date.now() - timer.startedAt) / 1000));
    var elapsed = Math.floor((Date.now() - timer.startedAt) / 1000);
    if (elapsed - timer.unreported >= 30) { reportTime(elapsed - timer.unreported); timer.unreported = elapsed; }
  }, 1000);
}

function pauseTimer() {
  if (!timer.running) return;
  var elapsed = Math.floor((Date.now() - timer.startedAt) / 1000);
  flushTimer();
  timer.running = false;
  stopTimerUI();
  if (state.currentBox) {
    state.currentBox.timeSpentSeconds += elapsed;
    document.getElementById('timer-total').textContent = '已累计 ' + fmtTime(state.currentBox.timeSpentSeconds);
  }
}

function flushTimer() {
  if (!timer.running || !state.currentBox) return;
  var elapsed = Math.floor((Date.now() - timer.startedAt) / 1000);
  var delta = elapsed - timer.unreported;
  if (delta > 0) reportTime(delta);
  timer.unreported = elapsed;
}

function reportTime(seconds) {
  if (!state.currentBox || seconds <= 0) return;
  post('/api/boxes/' + state.currentBox.id + '/time', { seconds: seconds }).catch(function () {});
}

function stopTimerUI() {
  if (timer.tick) clearInterval(timer.tick);
  timer.tick = null;
  timer.running = false;
  document.getElementById('timer').textContent = '0:00:00';
  document.getElementById('timer-btn').textContent = '开始计时';
}

function setBoxStatus(status) {
  if (!state.currentBox) return;
  pauseTimer();
  patch('/api/boxes/' + state.currentBox.id, { status: status }).then(function () {
    showToast('已标记「' + status + '」');
    closeBox();
  });
}

function completeBox() {
  if (!state.currentBox) return;
  var undecided = state.items.filter(function (i) { return !i.disposition; }).length;
  var message = undecided > 0 ? '还有 ' + undecided + ' 件未标处置，确定完成？' : '完成这个箱子？';
  if (!confirm(message)) return;
  setBoxStatus('已完成');
}

window.addEventListener('pagehide', flushTimer);

// MARK: 暂存二次清

var lastStaging = null;

function loadStaging() {
  api('/api/staging').then(function (data) {
    lastStaging = data;
    renderStaging();
  }).catch(function (e) { showToast('加载失败：' + e.message); });
}

function renderStaging() {
  var data = lastStaging || { groups: [], total: 0 };
  document.getElementById('staging-stats').innerHTML =
    stat(data.total, '暂存（件）') + stat(data.groups.length, '暂存箱（个）');
  var html = '';
  data.groups.forEach(function (group) {
    html += '<div class="card"><div class="exit-group-title">' + escapeHtml(group.location) + ' · ' + group.count + ' 件</div>';
    group.items.forEach(function (item) {
      var options = (state.cats || []).map(function (c) {
        var selected = c.name === item.category ? ' selected' : '';
        return '<option value="' + escapeHtml(c.name) + '"' + selected + '>' + escapeHtml(c.emoji + ' ' + c.name) + '</option>';
      }).join('');
      html += '<div class="stg-row"><span class="stg-name">' + escapeHtml(item.name) + '</span>' +
        '<select onchange="setStagingCategory(\'' + item.id + '\', this.value)"><option value="">未分类</option>' + options + '</select>' +
        '<button class="btn small" onclick="openLocSheet(\'' + item.id + '\')">归位</button></div>';
    });
    html += '</div>';
  });
  document.getElementById('staging-groups').innerHTML = html || '<div class="empty">没有暂存物品——清箱时按「暂存」就会进这里</div>';
}

function setStagingCategory(itemId, category) {
  patch('/api/items/' + itemId, { category: category }).then(function () {
    showToast('已更新分类');
  }).catch(function (e) { showToast('失败：' + e.message); });
}

// MARK: 出口区

function loadExit() {
  api('/api/exit').then(function (data) {
    state.exit = data;
    renderExit();
  }).catch(function (e) { showToast('加载失败：' + e.message); });
}

function renderExit() {
  var data = state.exit || { groups: [], total: 0 };
  document.getElementById('exit-stats').innerHTML =
    stat(data.total, '待出门（件）') +
    stat(data.groups.filter(function (g) { return g.disposition === '扔'; })[0] ? data.groups[0].count : 0, '扔') +
    stat(data.groups[1] ? data.groups[1].count : 0, '捐') +
    stat(data.groups[2] ? data.groups[2].count : 0, '卖');
  document.getElementById('exit-all-btn').disabled = data.total === 0;
  var html = '';
  data.groups.forEach(function (group) {
    if (!group.items.length) return;
    html += '<div class="card"><div class="exit-group-title">' + group.disposition + ' · ' + group.count + ' 件</div>';
    group.items.forEach(function (item) {
      html += '<div class="exit-row"><span class="box-label">' + escapeHtml(item.name) + '</span>' +
        (item.location ? '<span class="box-meta">' + escapeHtml(item.location) + '</span>' : '') +
        '<button class="btn small secondary" onclick="executeExit([\'' + item.id + '\'])">已带出</button></div>';
    });
    html += '</div>';
  });
  document.getElementById('exit-groups').innerHTML = html || '<div class="empty">出口袋是空的——清箱时点 扔 / 捐 / 卖 就会进这里</div>';
}

function executeExit(ids) {
  post('/api/exit/execute', ids ? { ids: ids } : {}).then(function (data) {
    showToast('已带出 ' + data.count + ' 件，出门一趟！');
    loadExit();
  }).catch(function (e) { showToast('失败：' + e.message); });
}

// MARK: 启动

(function init() {
  api('/api/bootstrap').then(function (data) { state.cats = data.categories || []; }).catch(function () {});
  var staging = '暂存箱A';
  try { staging = localStorage.getItem('boxes.stagingName') || staging; } catch (e) {}
  document.getElementById('staging-name').value = staging;
  loadBoxes();
  api('/api/boxes').then(function (data) {
    var lastId = null;
    try { lastId = localStorage.getItem('boxes.lastBoxId'); } catch (e) {}
    if (lastId && data.boxes.some(function (b) { return b.id === lastId && b.status !== '已完成'; })) {
      state.boxes = data.boxes;
      openBox(lastId);
    }
  }).catch(function () {});
})();
</script>
</body>
</html>
"""##
}
