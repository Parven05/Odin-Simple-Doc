"""
gen.py — Silicon doc generator
Reads config.json and odin_syntax.json, parses Odin source, emits index.html.

CSS is handled by two static files committed to the repo:
  style.css          — layout, sidebar, UI colours
  theme_monokai.css  — Monokai syntax colours and token rules

To swap themes: create a new theme_*.css and update the <link> in template.html.

File ordering: define "file_order" in config.json as a list of filenames
(e.g. ["window.odin", "renderer.odin"]). Files not listed sort alphabetically
after the listed ones.

Doc comments: place // or /* */ comments directly above a declaration (no
blank line gap) and they will appear as a readable description in the docs.
Comments separated by a blank line or inside the body are ignored.
Doc comments are stripped from the code block — they appear as text only.
"""

import json
import re
import textwrap
from datetime import datetime, timezone
from html import escape
from pathlib import Path

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).parent.resolve()


def _load_json(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"Error: required file not found -> {path}")
    with path.open(encoding="utf-8") as f:
        return json.load(f)


CFG    = _load_json(BASE_DIR / "config.json")
SYNTAX = _load_json(BASE_DIR / CFG["paths"]["syntax"])

SOURCE_DIR    = (BASE_DIR / CFG["paths"]["source_dir"]).resolve()
OUTPUT_HTML   = BASE_DIR / CFG["paths"]["output_html"]
TEMPLATE_PATH = BASE_DIR / CFG["paths"]["template"]
SORT_ORDER    = CFG["sort_order"]
PROJ          = CFG["project"]

# Build a filename -> index lookup from config.json "file_order" list.
# Files not listed get index 999_999 and fall back to alphabetical sorting.
FILE_ORDER = {name: i for i, name in enumerate(CFG.get("file_order", []))}


# ---------------------------------------------------------------------------
# JS highlight rules — built from odin_syntax.json at gen time
# ---------------------------------------------------------------------------
def _build_highlight_rules() -> str:
    """Generate the JS RULES array from odin_syntax.json token_classes."""
    tc   = SYNTAX["token_classes"]
    kws  = "|".join(re.escape(k) for k in SYNTAX["keywords"])
    typs = "|".join(re.escape(t) for t in SYNTAX["builtin_types"])
    bis  = "|".join(re.escape(b) for b in SYNTAX["builtin_procs"])
    lits = "|".join(re.escape(lit) for lit in SYNTAX["literals"])

    cm   = tc["comment"]
    st   = tc["string"]
    fn   = tc["fn_name"]
    ty   = tc["type_name"]
    kw   = tc["keyword"]
    bi   = tc["builtin"]
    bl   = tc["literal"]
    nm   = tc["number"]
    dr   = tc["directive"]
    at   = tc["attribute"]
    dc   = tc["decl_sep"]
    asgn = tc["assign"]
    pt   = tc["pointer"]
    ar   = tc["arrow"]
    op   = tc["operator"]

    return f"""    var RULES = [
        // Strings & comments first — protect internals from keyword matches
        {{ cls: "{cm}",  re: /\\/\\*[\\s\\S]*?\\*\\//g }},
        {{ cls: "{cm}",  re: /\\/\\/[^\\n]*/g }},
        {{ cls: "{st}",  re: /`[^`]*`/g }},
        {{ cls: "{st}",  re: /"(?:[^"\\\\]|\\\\.)*"/g }},
        {{ cls: "{st}",  re: /'(?:[^'\\\\]|\\\\.)*'/g }},
        // Declaration names — before keywords to avoid double-colour
        {{ cls: "{fn}",  re: /\\b([A-Za-z_]\\w*)(\\s*::\\s*proc\\b)/g,                  cap: true }},
        {{ cls: "{ty}",  re: /\\b([A-Za-z_]\\w*)(\\s*::\\s*(?:struct|enum|union)\\b)/g, cap: true }},
        // Directives & attributes
        {{ cls: "{dr}",  re: /#[a-z_]+/g }},
        {{ cls: "{at}",  re: /@(?:\\([^)]*\\)|\\w+)/g }},
        // Keywords
        {{ cls: "{kw}",  re: /\\b(?:{kws})\\b/g }},
        // Built-in types
        {{ cls: "{ty}",  re: /\\b(?:{typs})\\b/g }},
        // Literals
        {{ cls: "{bl}",  re: /\\b(?:{lits})\\b/g }},
        // Built-in procedures
        {{ cls: "{bi}",  re: /\\b(?:{bis})\\b/g }},
        // Numeric literals
        {{ cls: "{nm}",  re: /\\b(?:0x[\\da-fA-F][\\da-fA-F_]*|0b[01][01_]*|0o[0-7][0-7_]*|\\d[\\d_]*(?:\\.[\\d_]+)?(?:[eE][+-]?\\d[\\d_]*)?i?)\\b/g }},
        // Operators
        {{ cls: "{dc}",  re: /::/g }},
        {{ cls: "{asgn}", re: /:=/g }},
        {{ cls: "{pt}",  re: /\\^/g }},
        {{ cls: "{ar}",  re: /->/g }},
        {{ cls: "{op}",  re: /\\.\\./g }},
        {{ cls: "{op}",  re: /[+\\-*/%=<>!&|~?]+/g }},
    ];"""


# ---------------------------------------------------------------------------
# Template substitution
# ---------------------------------------------------------------------------
_TMPL_RE = re.compile(
    r"\{\{(content|toc_json|item_count|generated_at"
    r"|project_name|project_subtitle|project_tagline|github_url"
    r"|highlight_rules|page_title|style_css|theme_css)\}\}"
)


def _apply(text: str, subs: dict) -> str:
    return _TMPL_RE.sub(lambda m: subs[m.group(1)], text)


# ---------------------------------------------------------------------------
# Compiled patterns
# ---------------------------------------------------------------------------
_DECL_RE      = re.compile(r"(\w+)\s*::\s*(struct|proc|enum|union)")
_RET_RE       = re.compile(r"->\s*([^{]+)")
_ATTR_RE      = re.compile(r"@(?:\([^)]*\)|\w+)\s*$")
_WS_RE        = re.compile(r"\s+")
_ID_UNSAFE_RE = re.compile(r"[^A-Za-z0-9]")


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
def get_file_order(pkg: str) -> int:
    """Return sort index for a package path, matched on filename only.
    Files listed in config.json 'file_order' get their list index;
    everything else gets 999_999 and sorts alphabetically after them."""
    filename = Path(pkg).name
    return FILE_ORDER.get(filename, 999_999)


def get_block(text: str, start: int) -> str | None:
    n        = len(text)
    line_end = text.find("\n", start)
    if line_end == -1:
        line_end = n
    depth = 0
    found = False
    i     = start
    while i < n:
        ch = text[i]
        if ch == "{":
            depth += 1
            found  = True
        elif ch == "}" and found:
            depth -= 1
            if depth == 0:
                return text[start : i + 1]
        i += 1
    return text[start:line_end] if not found else None


def _proc_params(line: str) -> str:
    idx = line.find(":: proc")
    if idx == -1:
        return ""
    ps = line.find("(", idx + 7)
    if ps == -1:
        return ""
    depth = 0
    i     = ps
    while i < len(line):
        ch = line[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return _WS_RE.sub(" ", line[ps + 1 : i].strip())
        i += 1
    return ""


def extract_signature(block: str, cat: str) -> dict[str, str]:
    if cat != "PROC":
        return {"params": "", "returns": ""}
    first = block.split("\n", 1)[0]
    rm    = _RET_RE.search(first)
    return {
        "params":  _proc_params(first),
        "returns": _WS_RE.sub(" ", rm.group(1).strip().rstrip("{").strip()) if rm else "",
    }


def preceding_metadata(text: str, match_start: int) -> tuple[list[str], list[str]]:
    """Collect comments and attributes immediately above a declaration.
    Stops at the first blank line — does not cross blank lines."""
    region = text.rfind("\n", 0, match_start)
    for _ in range(59):
        pos = text.rfind("\n", 0, region)
        if pos == -1:
            region = 0
            break
        region = pos

    comments: list[str] = []
    attrs:    list[str] = []

    for line in reversed(text[region:match_start].splitlines()):
        stripped = line.strip()
        if _ATTR_RE.search(stripped):
            attrs.insert(0, stripped)
        elif stripped.startswith(("//", "/*")) or stripped.endswith("*/"):
            comments.insert(0, stripped)
        elif not stripped:
            # blank line — stop; don't cross blank lines
            break
        else:
            break

    return comments, attrs


def _extract_doc(comments: list[str]) -> str:
    """Strip comment markers and return clean doc description text.
    Handles both // single-line and /* */ block comment styles."""
    lines = []
    for line in comments:
        s = line.strip()
        s = re.sub(r"^//\s?", "", s)           # strip // prefix
        s = re.sub(r"^/\*+\s*|\s*\*+/$", "", s)  # strip /* */ markers
        s = re.sub(r"^\*\s?", "", s)            # strip leading * in block comments
        s = s.strip()
        if s:
            lines.append(s)
    return " ".join(lines).strip()


def format_snippet(attrs: list[str], block: str) -> str:
    """Build the code snippet shown in the doc — attrs + block only.
    Doc comments are intentionally excluded; they appear as .doc-text instead."""
    return "\n".join(attrs + [textwrap.dedent(block).rstrip()]).strip()


def package_path(fp: Path, src: Path) -> str:
    try:
        return str(fp.relative_to(src))
    except ValueError:
        return fp.name


def make_item_id(pkg: str, name: str) -> str:
    return _ID_UNSAFE_RE.sub("-", pkg) + "--" + name


# ---------------------------------------------------------------------------
# Param highlighting
# ---------------------------------------------------------------------------
def _split_params(raw: str) -> list[str]:
    """Split a param string on commas that are outside brackets.
    Handles types like ^matrix[4, 4]f32 or proc(a, b) without breaking them."""
    segments: list[str] = []
    depth     = 0
    current:  list[str] = []
    for ch in raw:
        if ch in "([{":
            depth += 1
            current.append(ch)
        elif ch in ")]}":
            depth -= 1
            current.append(ch)
        elif ch == "," and depth == 0:
            segments.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        segments.append("".join(current).strip())
    return segments


def _format_params(raw: str) -> str:
    """Wrap param names and types in coloured spans."""
    parts: list[str] = []
    for segment in _split_params(raw):
        if not segment:
            continue
        if ":" in segment:
            name, _, typ = segment.partition(":")
            parts.append(
                f"<span class='sig-param-name'>{escape(name.strip())}</span>"
                f"<span class='sig-colon'>:</span> "
                f"<span class='sig-param-type'>{escape(typ.strip())}</span>"
            )
        else:
            parts.append(
                f"<span class='sig-param-name'>{escape(segment)}</span>"
            )
    return "<span class='sig-comma'>, </span>".join(parts)


# ---------------------------------------------------------------------------
# HTML builders
# ---------------------------------------------------------------------------
def _doc_html(doc: str) -> str:
    """Render the doc comment as a description bar below the summary."""
    if not doc:
        return ""
    return f"\n            <div class='doc-text'>{escape(doc)}</div>"


def _sig_html(item: dict) -> str:
    if item["cat"] != "PROC":
        return ""
    p = item["sig"]["params"]
    r = item["sig"]["returns"]
    if not p and not r:
        return ""
    parts: list[str] = []
    if p:
        parts.append(
            f"<span class='sig-label'>params</span> "
            f"<span class='sig-val'>{_format_params(p)}</span>"
        )
    if r:
        parts.append(
            f"<span class='sig-label'>returns</span> "
            f"<span class='sig-val sig-ret'>{escape(r)}</span>"
        )
    return (
        "\n            <div class='sig-bar'>"
        + " &nbsp;&middot;&nbsp; ".join(parts)
        + "</div>"
    )


def _refs_html(refs: list[str]) -> str:
    if not refs:
        return ""
    links = " ".join(
        f"<a class='ref-link' href='#{escape(r)}'>{escape(r.split('--')[-1])}</a>"
        for r in refs
    )
    return (
        f"\n            <div class='refs-bar'>"
        f"<span class='refs-label'>used by</span> {links}</div>"
    )


def _item_html(item: dict) -> str:
    attrs_html = "".join(
        f"<span class='attr'>{escape(a)}</span>" for a in item["attrs"]
    )
    return (
        f"\n        <details id='{escape(item['id'])}'>"
        f"\n            <summary>"
        f"<span class='item-name'>{escape(item['name'])}</span>"
        f"{attrs_html}"
        f"<span class='badge badge-{item['cat'].lower()}'>{item['cat']}</span>"
        f"</summary>"
        f"{_doc_html(item.get('doc', ''))}"
        f"{_sig_html(item)}"
        f"{_refs_html(item.get('used_by', []))}"
        f"\n            <div class='content'>"
        f"<div class='code-header'>"
        f"<span class='code-file'>{escape(item['pkg'])}</span>"
        f"<button class='copy-btn' onclick='copyCode(this)' title='Copy'>&#x2398;</button>"
        f"</div>"
        f"<pre class='language-odin'>"
        f"<code class='language-odin'>{escape(item['code'])}</code>"
        f"</pre>"
        f"</div>\n        </details>"
    )


def build_html(items: list[dict]) -> str:
    parts: list[str] = []
    last_pkg: str | None = None
    for item in items:
        pkg = item["pkg"]
        if pkg != last_pkg:
            if last_pkg:
                parts.append("</div>")
            safe_id = escape(_ID_UNSAFE_RE.sub("-", pkg))
            parts.append(
                f"<div class='file-section' id='sec-{safe_id}'>"
                f"<div class='file-header' data-pkg='{escape(pkg)}'>"
                f"{escape(Path(pkg).stem)}"
                f"<span class='file-sym-count'>{item['pkg_count']}</span>"
                f"</div>"
            )
            last_pkg = pkg
        parts.append(_item_html(item))
    if last_pkg:
        parts.append("</div>")
    return "".join(parts)


# ---------------------------------------------------------------------------
# Core parsing
# ---------------------------------------------------------------------------
def parse_source(source_dir: Path) -> list[dict]:
    file_data: list[tuple[int, str, Path, str]] = []
    for path in source_dir.rglob("*.odin"):
        content = path.read_text(encoding="utf-8")
        pkg     = package_path(path, source_dir)
        file_data.append((get_file_order(pkg), pkg, path, content))
    file_data.sort(key=lambda x: (x[0], x[1]))

    items: list[dict] = []
    for order, pkg, _path, content in file_data:
        for m in _DECL_RE.finditer(content):
            name  = m.group(1)
            cat   = m.group(2).upper()
            block = get_block(content, m.start())
            if not block:
                continue
            comments, attrs = preceding_metadata(content, m.start())
            items.append({
                "id":         make_item_id(pkg, name),
                "name":       name,
                "cat":        cat,
                "pkg":        pkg,
                "file_order": order,
                "attrs":      attrs,
                "doc":        _extract_doc(comments),
                "sig":        extract_signature(block, cat),
                "code":       format_snippet(attrs, block),
                "raw_code":   block,
                "used_by":    [],
            })

    items.sort(key=lambda x: (
        x["file_order"], x["pkg"], SORT_ORDER.get(x["cat"], 4), x["name"]
    ))

    # Used-by analysis
    name_to_id: dict[str, str] = {}
    for item in items:
        name_to_id.setdefault(item["name"], item["id"])

    used_by: dict[str, set[str]] = {item["id"]: set() for item in items}
    ident_re = re.compile(r"\b([A-Za-z_]\w*)\b")
    for item in items:
        cid = item["id"]
        for match in ident_re.finditer(item["raw_code"]):
            word = match.group(1)
            if word != item["name"] and word in name_to_id and name_to_id[word] != cid:
                used_by[name_to_id[word]].add(cid)

    pkg_counts: dict[str, int] = {}
    for item in items:
        pkg_counts[item["pkg"]] = pkg_counts.get(item["pkg"], 0) + 1

    for item in items:
        item["used_by"]   = sorted(used_by.get(item["id"], set()))
        item["pkg_count"] = pkg_counts[item["pkg"]]
        del item["raw_code"]

    return items


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
def main() -> None:
    if not SOURCE_DIR.exists():
        raise SystemExit(f"Error: source directory not found -> {SOURCE_DIR}")

    items        = parse_source(SOURCE_DIR)
    html_content = build_html(items)

    toc_data: dict[str, list[dict]] = {}
    for item in items:
        toc_data.setdefault(item["pkg"], []).append(
            {"id": item["id"], "name": item["name"], "cat": item["cat"]}
        )

    subs = {
        "content":          html_content,
        "toc_json":         json.dumps(toc_data, ensure_ascii=False),
        "item_count":       str(len(items)),
        "generated_at":     datetime.now(timezone.utc).strftime("%B %d, %Y at %H:%M UTC"),
        "project_name":     escape(PROJ["name"]),
        "project_subtitle": escape(PROJ["subtitle"]),
        "project_tagline":  escape(PROJ["tagline"]),
        "github_url":       escape(PROJ["github_url"]),
        "page_title":       escape(PROJ["page_title"]),
        "highlight_rules":  _build_highlight_rules(),
        "style_css":        CFG["paths"]["style_css"],
        "theme_css":        CFG["paths"]["theme_css"],
    }

    output = _apply(TEMPLATE_PATH.read_text(encoding="utf-8"), subs)
    OUTPUT_HTML.write_text(output, encoding="utf-8")
    print(f"Done: {len(items)} items -> {OUTPUT_HTML}")


if __name__ == "__main__":
    main()
