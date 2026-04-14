package doc

import "core:strings"

write_html_header :: proc(sb: ^strings.Builder) {
	strings.write_string(
		sb,
		`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Odin Doc</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;500;600&display=swap');

:root {
  --bg:          #1c1d18;
  --bg2:         #16170f;
  --bg3:         #222318;
  --card:        #23241a;
  --card-hover:  #282920;
  --border:      #2e2f24;
  --border2:     #3a3b2e;
  --border3:     #454637;
  --text:        #e8e6d9;
  --text-dim:    #9a9880;
  --text-faint:  #5c5a48;
  --accent:      #f92672;
  --accent2:     #fd971f;

  --sb-bg:       #131410;
  --sb-border:   #252619;
  --sb-hover:    #1e1f16;
  --sb-text:     #c8c6b4;

  --file-line:   #3a3b2e;

  /* syntax */
  --kw:          #f92672;
  --ty:          #66d9ef;
  --bi:          #a6e22e;
  --num:         #ae81ff;
  --str:         #e6db74;
  --cm:          #6a6854;
  --br:          #c8c6b4;
  --op:          #6e6d5a;
  --ident:       #e8e6d9;

  /* badges */
  --proc-bg:     #2c2416;   --proc-fg:   #fd971f;
  --struct-bg:   #172514;   --struct-fg: #a6e22e;
  --enum-bg:     #121826;   --enum-fg:   #66d9ef;
  --union-bg:    #22132a;   --union-fg:  #ae81ff;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: 'IBM Plex Sans', system-ui, sans-serif;
  font-size: 14px; /* bumped from 13px */
  display: flex;
  overflow: hidden;
}

/* ════════════════════════════════════════
   SCROLLBAR
════════════════════════════════════════ */
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--border3); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: var(--text-faint); }

/* ════════════════════════════════════════
   SIDEBAR
════════════════════════════════════════ */
#sidebar {
  width: 240px;
  min-width: 200px;
  background: var(--sb-bg);
  border-right: 1px solid var(--sb-border);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  flex-shrink: 0;
  transition: width 0.18s ease, opacity 0.18s ease, min-width 0.18s ease;
}
#sidebar.hidden { width: 0; min-width: 0; opacity: 0; pointer-events: none; }

#sidebar-logo {
  padding: 14px 14px 12px;
  border-bottom: 1px solid var(--sb-border);
  display: flex;
  align-items: center;
  gap: 9px;
  flex-shrink: 0;
}
.logo-mark {
  width: 26px; height: 26px;
  background: var(--accent);
  border-radius: 5px;
  display: flex; align-items: center; justify-content: center;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px; font-weight: 600;
  color: #fff;
  flex-shrink: 0;
}
.logo-text {
  font-family: 'IBM Plex Sans', sans-serif;
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--text);
  letter-spacing: 0.01em;
}

#sidebar-scroll { overflow-y: auto; flex: 1; padding: 8px 0 20px; }

/* sidebar file group */
.sb-file { margin-bottom: 2px; }
.sb-file-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 10px 5px 12px;
  cursor: pointer;
  user-select: none;
  border-left: 2px solid transparent;
  transition: background 0.1s, border-color 0.1s;
}
.sb-file-header:hover { background: var(--sb-hover); }
.sb-file-header.open  { border-left-color: var(--border3); }

.sb-file-chevron {
  font-size: 8px;
  color: var(--text-faint);
  transition: transform 0.15s;
  flex-shrink: 0;
  margin-right: 1px;
}
.sb-file-header.open .sb-file-chevron { transform: rotate(90deg); }

.sb-file-name {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  color: var(--text-dim);
  font-weight: 600;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sb-file-items { display: none; }
.sb-file-items.open { display: block; }

.toc-link {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 3px 10px 3px 28px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.76rem;
  color: var(--sb-text);
  text-decoration: none;
  border-left: 2px solid transparent;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: background 0.08s, color 0.08s, border-color 0.08s;
  opacity: 0.8;
}
.toc-link:hover  { background: var(--sb-hover); color: var(--text); opacity: 1; }
.toc-link.active {
  color: var(--text);
  border-left-color: var(--accent2);
  background: var(--sb-hover);
  opacity: 1;
}
.toc-name { flex: 1; overflow: hidden; text-overflow: ellipsis; }
.toc-dot {
  width: 5px; height: 5px;
  border-radius: 50%;
  flex-shrink: 0;
}
.toc-dot-proc   { background: var(--proc-fg); }
.toc-dot-struct { background: var(--struct-fg); }
.toc-dot-enum   { background: var(--enum-fg); }
.toc-dot-union  { background: var(--union-fg); }

/* ════════════════════════════════════════
   MAIN
════════════════════════════════════════ */
#main { flex: 1; display: flex; flex-direction: column; overflow: hidden; min-width: 0; }

/* top bar */
#topbar {
  padding: 0 16px;
  border-bottom: 1px solid var(--border);
  background: var(--bg2);
  display: flex;
  align-items: center;
  gap: 10px;
  height: 46px;
  flex-shrink: 0;
}

.icon-btn {
  background: none; border: none;
  color: var(--text-faint);
  cursor: pointer;
  padding: 5px;
  border-radius: 4px;
  display: flex; align-items: center; justify-content: center;
  transition: background 0.1s, color 0.1s;
}
.icon-btn:hover { background: var(--border); color: var(--text); }
.icon-btn svg { width: 16px; height: 16px; }

#topbar-title {
  font-family: 'IBM Plex Sans', sans-serif;
  font-weight: 600;
  font-size: 0.88rem;
  color: var(--text);
  letter-spacing: 0.01em;
}

#topbar-actions { margin-left: auto; display: flex; align-items: center; gap: 6px; }

#toggle-all-btn {
  background: var(--bg3);
  border: 1px solid var(--border2);
  border-radius: 4px;
  color: var(--text-dim);
  cursor: pointer;
  padding: 4px 10px;
  font-family: 'IBM Plex Sans', sans-serif;
  font-size: 0.75rem;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 5px;
  transition: background 0.1s, color 0.1s, border-color 0.1s;
  white-space: nowrap;
}
#toggle-all-btn:hover { background: var(--border); color: var(--text); border-color: var(--border3); }
#toggle-all-btn svg { width: 13px; height: 13px; }

/* toolbar */
#toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  border-bottom: 1px solid var(--border);
  background: var(--bg2);
  flex-shrink: 0;
}

#search {
  flex: 1;
  background: var(--bg3);
  border: 1px solid var(--border2);
  border-radius: 5px;
  padding: 6px 12px 6px 32px;
  color: var(--text);
  outline: none;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.78rem;
  transition: border-color 0.15s, background 0.15s;
  min-width: 0;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%235c5a48' stroke-width='2'%3E%3Ccircle cx='11' cy='11' r='8'/%3E%3Cpath d='m21 21-4.35-4.35'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: 10px center;
}
#search:focus { border-color: var(--accent); background-color: var(--card); }
#search::placeholder { color: var(--text-faint); }

#filter-bar { display: flex; gap: 4px; flex-shrink: 0; }

.filter-btn {
  background: var(--bg3);
  border: 1px solid var(--border2);
  border-radius: 4px;
  padding: 4px 10px;
  color: var(--text-faint);
  cursor: pointer;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.70rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  transition: background 0.1s, color 0.1s, border-color 0.1s;
}
.filter-btn:hover { color: var(--text-dim); border-color: var(--border3); }
.filter-btn[data-kind="PROC"].on   { background: var(--proc-bg);   color: var(--proc-fg);   border-color: var(--proc-fg); }
.filter-btn[data-kind="STRUCT"].on { background: var(--struct-bg); color: var(--struct-fg); border-color: var(--struct-fg); }
.filter-btn[data-kind="ENUM"].on   { background: var(--enum-bg);   color: var(--enum-fg);   border-color: var(--enum-fg); }
.filter-btn[data-kind="UNION"].on  { background: var(--union-bg);  color: var(--union-fg);  border-color: var(--union-fg); }

/* ════════════════════════════════════════
   CONTENT AREA
════════════════════════════════════════ */
#api-root {
  overflow-y: auto;
  flex: 1;
  padding: 16px 24px 60px;
}

/* ── file group ── */
.file-group {
  margin-bottom: 10px; /* reduced from 28px */
}

.file-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px 8px 10px;
  cursor: pointer;
  user-select: none;
  border-radius: 6px 6px 0 0;
  background: var(--bg3);
  border: 1px solid var(--border2);
  border-bottom: none;
  position: relative;
  transition: background 0.1s;
}
.file-header:hover { background: var(--card-hover); }

.file-group.collapsed .file-header {
  border-radius: 6px;
  border-bottom: 1px solid var(--border2);
}

.file-chevron {
  font-size: 9px;
  color: var(--text-faint);
  transition: transform 0.18s ease;
  flex-shrink: 0;
}
.file-group.collapsed .file-chevron { transform: rotate(-90deg); }

.file-icon {
  font-size: 12px;
  opacity: 0.6;
  flex-shrink: 0;
}

.file-name {
  font-family: 'JetBrains Mono', monospace;
  font-weight: 600;
  font-size: 0.85rem; /* slightly larger */
  color: var(--text);
  flex: 1;
}

.file-counts {
  display: flex;
  gap: 5px;
  flex-shrink: 0;
}
.file-counts span {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.67rem;
  font-weight: 600;
  padding: 1px 6px;
  border-radius: 3px;
  opacity: 0.85;
}
.fc-struct { background: var(--struct-bg); color: var(--struct-fg); }
.fc-enum   { background: var(--enum-bg);   color: var(--enum-fg); }
.fc-union  { background: var(--union-bg);  color: var(--union-fg); }
.fc-proc   { background: var(--proc-bg);   color: var(--proc-fg); }

.file-body {
  border: 1px solid var(--border2);
  border-top: none;
  border-radius: 0 0 6px 6px;
  overflow: hidden;
}
.file-group.collapsed .file-body { display: none; }

/* ── declaration cards ── */
details {
  background: var(--card);
  border-bottom: 1px solid var(--border);
  transition: background 0.1s;
}
details:last-child { border-bottom: none; }
details[open] { background: var(--card); }

summary {
  padding: 8px 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  list-style: none;
  user-select: none;
  transition: background 0.08s;
}
summary::-webkit-details-marker { display: none; }
summary:hover { background: var(--card-hover); }

.chevron {
  font-size: 7px;
  color: var(--text-faint);
  transition: transform 0.15s ease;
  flex-shrink: 0;
  margin-right: 2px;
}
details[open] > summary .chevron { transform: rotate(90deg); }

.item-name {
  font-family: 'JetBrains Mono', monospace;
  font-weight: 600;
  font-size: 0.88rem; /* bumped from 0.84rem */
  color: var(--text);
}

.badge {
  margin-left: auto;
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.62rem;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: 3px;
  letter-spacing: 0.06em;
}
.badge-proc   { background: var(--proc-bg);   color: var(--proc-fg); }
.badge-struct { background: var(--struct-bg); color: var(--struct-fg); }
.badge-enum   { background: var(--enum-bg);   color: var(--enum-fg); }
.badge-union  { background: var(--union-bg);  color: var(--union-fg); }

/* ── meta bar ── */
.meta-bar {
  padding: 6px 12px;
  border-top: 1px solid var(--border);
  background: var(--bg2);
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.74rem;
  color: var(--text-dim);
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  align-items: center;
}

.meta-tag {
  background: var(--bg3);
  border: 1px solid var(--border2);
  border-radius: 4px;
  padding: 2px 8px;
  display: inline-flex;
  gap: 4px;
  align-items: center;
}
.meta-tag .label { color: var(--text-faint); }
.meta-tag .val   { color: var(--text); }
.meta-tag .type  { color: var(--ty); }
.meta-tag .num   { color: var(--num); }
.meta-tag .attr  { color: var(--bi); }

/* ── code block ── */
/* No more .code-header strip — copy button lives inside .code-wrap */
.code-wrap {
  border-top: 1px solid var(--border);
  background: var(--bg2);
  position: relative;
}

/* copy button floats in the top-right of the code block */
.copy-btn {
  position: absolute;
  top: 7px;
  right: 10px;
  z-index: 2;
  background: var(--bg3);
  border: 1px solid var(--border2);
  color: var(--text-faint);
  cursor: pointer;
  padding: 4px 6px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.15s, background 0.1s, color 0.1s, border-color 0.1s;
  line-height: 0;
}
.copy-btn svg { width: 13px; height: 13px; stroke: currentColor; }
/* show on hover of the whole code-wrap */
.code-wrap:hover .copy-btn { opacity: 1; }
.copy-btn:hover { background: var(--border); color: var(--text); border-color: var(--border3); }
.copy-btn.copied { opacity: 1; color: var(--bi); border-color: var(--bi); background: var(--bg3); }
.copy-btn .check { display: none; }
.copy-btn.copied .copy-icon { display: none; }
.copy-btn.copied .check { display: block; }

pre {
  margin: 0;
  padding: 14px 18px;
  overflow-x: auto;
  tab-size: 4;
}

code {
  font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace;
  font-size: 13.5px; /* bumped from 12.5px */
  line-height: 1.75;
  color: var(--ident);
  white-space: pre;
}

/* ── syntax classes ── */
.kw    { color: var(--kw);  font-weight: 600; }
.ty    { color: var(--ty);  }
.bi    { color: var(--bi);  }
.num   { color: var(--num); }
.str   { color: var(--str); }
.cm    { color: var(--cm);  font-style: italic; }
.br    { color: var(--br);  opacity: 0.7; }
.op    { color: var(--op);  }
.ident { color: var(--ident); }

/* ── flash animation ── */
@keyframes flash-in {
  0%   { box-shadow: inset 0 0 0 2px var(--accent); }
  100% { box-shadow: inset 0 0 0 2px transparent; }
}
details.flash { animation: flash-in 0.9s ease-out forwards; }

/* ── no results ── */
#no-results {
  display: none;
  text-align: center;
  padding: 5rem 2rem;
  color: var(--text-faint);
  font-size: 0.85rem;
}
#no-results svg { width: 32px; height: 32px; margin-bottom: 12px; opacity: 0.3; }
</style>
</head>
<body>

<!-- ══ SIDEBAR ══════════════════════════════════════════ -->
<aside id="sidebar">
  <div id="sidebar-logo">
    <div class="logo-mark">O</div>
    <span class="logo-text">Odin Doc</span>
  </div>
  <div id="sidebar-scroll"></div>
</aside>

<!-- ══ MAIN ═════════════════════════════════════════════ -->
<main id="main">
  <div id="topbar">
    <button class="icon-btn" onclick="toggleSidebar()" title="Toggle sidebar">
      <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5">
        <rect x="1" y="2" width="14" height="12" rx="2"/>
        <path d="M5 2v12"/>
      </svg>
    </button>
    <span id="topbar-title">Odin Doc</span>
    <div id="topbar-actions">
      <button id="toggle-all-btn" onclick="toggleAll()">
        <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M2 5h12M2 8h8M2 11h10"/>
        </svg>
        <span id="toggle-all-label">Expand all</span>
      </button>
    </div>
  </div>
  <div id="toolbar">
    <input type="text" id="search" placeholder="Search symbols..." autocomplete="off" spellcheck="false">
    <div id="filter-bar">
      <button class="filter-btn" data-kind="STRUCT" onclick="toggleKind(this)">STRUCT</button>
      <button class="filter-btn" data-kind="ENUM"   onclick="toggleKind(this)">ENUM</button>
      <button class="filter-btn" data-kind="UNION"  onclick="toggleKind(this)">UNION</button>
      <button class="filter-btn" data-kind="PROC"   onclick="toggleKind(this)">PROC</button>
    </div>
  </div>
  <div id="api-root">
`,
	)
}

write_html_footer :: proc(sb: ^strings.Builder) {
	strings.write_string(
		sb,
		`
    <div id="no-results">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
      <div>No symbols match</div>
    </div>
  </div><!-- #api-root -->
</main>

<script>
// ── state ──────────────────────────────────────────────────────────────────────
var allDetails     = Array.from(document.querySelectorAll("details"));
var allFileGroups  = Array.from(document.querySelectorAll(".file-group"));
var sidebarScroll  = document.getElementById("sidebar-scroll");
var activeKinds    = {};
var allExpanded    = false;

var kindDotClass = {
  PROC:   "toc-dot-proc",
  STRUCT: "toc-dot-struct",
  ENUM:   "toc-dot-enum",
  UNION:  "toc-dot-union",
};

// ── build sidebar ──────────────────────────────────────────────────────────────
allFileGroups.forEach(function(fg) {
  var fileName = fg.dataset.file || "unknown";
  var details  = Array.from(fg.querySelectorAll("details"));
  if (!details.length) return;

  var sbFile = document.createElement("div");
  sbFile.className = "sb-file";

  var header = document.createElement("div");
  header.className = "sb-file-header open";
  header.innerHTML =
    "<span class='sb-file-chevron'>&#9654;</span>" +
    "<span class='sb-file-name'>" + fileName + "</span>";

  var items = document.createElement("div");
  items.className = "sb-file-items open";

  details.forEach(function(d) {
    var nameEl  = d.querySelector(".item-name");
    var badgeEl = d.querySelector(".badge");
    if (!nameEl) return;
    var kind = badgeEl ? badgeEl.textContent.trim() : "";

    var a = document.createElement("a");
    a.className = "toc-link";
    a.href = "#" + d.id;
    a.dataset.kind = kind;

    var dot = document.createElement("span");
    dot.className = "toc-dot " + (kindDotClass[kind] || "");
    a.appendChild(dot);

    var nameSpan = document.createElement("span");
    nameSpan.className   = "toc-name";
    nameSpan.textContent = nameEl.textContent;
    a.appendChild(nameSpan);

    a.onclick = function(e) { e.preventDefault(); navigateTo(d.id); };
    items.appendChild(a);
  });

  header.onclick = function() {
    var open = header.classList.toggle("open");
    items.classList.toggle("open", open);
  };

  sbFile.appendChild(header);
  sbFile.appendChild(items);
  sidebarScroll.appendChild(sbFile);
});

// ── navigation ─────────────────────────────────────────────────────────────────
function navigateTo(id) {
  var el = document.getElementById(id);
  if (!el) return;
  el.open = true;
  var fg = el.closest(".file-group");
  if (fg && fg.classList.contains("collapsed")) {
    fg.classList.remove("collapsed");
  }
  el.scrollIntoView({ behavior: "smooth", block: "start" });
  el.classList.add("flash");
  setTimeout(function() { el.classList.remove("flash"); }, 900);
  document.querySelectorAll(".toc-link").forEach(function(a) {
    a.classList.toggle("active", a.href.endsWith("#" + id));
  });
  history.replaceState(null, "", "#" + id);
}

// ── sidebar toggle ─────────────────────────────────────────────────────────────
function toggleSidebar() {
  document.getElementById("sidebar").classList.toggle("hidden");
}

// ── file group collapse ────────────────────────────────────────────────────────
function toggleFileGroup(headerEl) {
  var fg = headerEl.closest(".file-group");
  if (fg) fg.classList.toggle("collapsed");
}

// ── collapse / expand all ──────────────────────────────────────────────────────
function toggleAll() {
  allExpanded = !allExpanded;
  document.getElementById("toggle-all-label").textContent = allExpanded ? "Collapse all" : "Expand all";
  allDetails.forEach(function(d) { d.open = allExpanded; });
  allFileGroups.forEach(function(fg) {
    fg.classList.toggle("collapsed", !allExpanded);
  });
}

// ── kind filter ────────────────────────────────────────────────────────────────
function toggleKind(btn) {
  var kind = btn.dataset.kind;
  if (activeKinds[kind]) { delete activeKinds[kind]; btn.classList.remove("on"); }
  else                   { activeKinds[kind] = true;  btn.classList.add("on"); }
  applyFilters();
}

// ── search + filter ────────────────────────────────────────────────────────────
function applyFilters() {
  var term    = document.getElementById("search").value.toLowerCase();
  var hasKind = Object.keys(activeKinds).length > 0;
  var anyVisible = false;

  allFileGroups.forEach(function(fg) {
    var groupHas = false;
    var details  = Array.from(fg.querySelectorAll("details"));

    details.forEach(function(d) {
      var nameEl  = d.querySelector(".item-name");
      var badgeEl = d.querySelector(".badge");
      var kind = badgeEl ? badgeEl.textContent.trim() : "";
      var name = nameEl  ? nameEl.textContent.toLowerCase() : "";
      var vis  = (!term || name.includes(term)) && (!hasKind || activeKinds[kind]);
      d.style.display = vis ? "" : "none";
      if (vis) { groupHas = true; anyVisible = true; }
    });

    fg.style.display = groupHas ? "" : "none";
  });

  document.querySelectorAll(".toc-link").forEach(function(a) {
    var kind = a.dataset.kind || "";
    var nameEl = a.querySelector(".toc-name");
    var name   = nameEl ? nameEl.textContent.toLowerCase() : "";
    a.style.display = ((!term || name.includes(term)) && (!hasKind || activeKinds[kind])) ? "" : "none";
  });

  document.getElementById("no-results").style.display = anyVisible ? "none" : "block";
}

document.getElementById("search").addEventListener("input", applyFilters);

// ── copy button ────────────────────────────────────────────────────────────────
function copyCode(btn) {
  var code = btn.closest("details").querySelector("code");
  if (!code) return;
  navigator.clipboard.writeText(code.textContent).then(function() {
    btn.classList.add("copied");
    setTimeout(function() { btn.classList.remove("copied"); }, 1800);
  });
}

// ── anchor on load ─────────────────────────────────────────────────────────────
(function() {
  var hash = window.location.hash.slice(1);
  if (!hash) return;
  var el = document.getElementById(hash);
  if (!el) return;
  el.open = true;
  var fg = el.closest(".file-group");
  if (fg) fg.classList.remove("collapsed");
  setTimeout(function() { el.scrollIntoView({ behavior: "smooth", block: "start" }); }, 100);
}());
</script>
</body>
</html>
`,
	)
}
