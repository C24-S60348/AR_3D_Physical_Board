#!/usr/bin/env python3
"""
generate_simulatedui.py
Generates simulatedui/ folder with 12 standalone HTML files simulating
the i.-GB Flutter AR app screens.
"""

import os
import base64
import mimetypes

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR  = os.path.join(BASE_DIR, "simulatedui")

# ── helpers ──────────────────────────────────────────────────────────────────

def b64img(rel_path: str) -> str:
    """Return a base64 data URI for the image at rel_path (relative to BASE_DIR)."""
    abs_path = os.path.join(BASE_DIR, rel_path)
    if not os.path.exists(abs_path):
        # Return a grey placeholder SVG
        svg = '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#555"/><text x="50%" y="50%" fill="#fff" font-size="12" text-anchor="middle" dy=".3em">Missing</text></svg>'
        enc = base64.b64encode(svg.encode()).decode()
        return f"data:image/svg+xml;base64,{enc}"
    mime, _ = mimetypes.guess_type(abs_path)
    mime = mime or "image/png"
    with open(abs_path, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    return f"data:{mime};base64,{data}"

def write_html(filename: str, content: str):
    path = os.path.join(OUT_DIR, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    size = os.path.getsize(path)
    print(f"  {filename:30s}  {size:,} bytes")

# ── shared pieces ─────────────────────────────────────────────────────────────

BACK_LINK = """<div style="text-align:center;margin-bottom:12px">
  <a href="index.html" style="color:#888;font-size:13px;text-decoration:none">← Back to Index</a>
</div>"""

PHONE_OPEN = """<div class="phone-wrap">
  <div class="phone">
    <div class="status-bar">
      <span>9:41</span>
      <span style="display:flex;gap:4px;align-items:center">
        <svg width="14" height="10" viewBox="0 0 14 10" fill="white">
          <path d="M7 2C9.2 2 11.2 2.9 12.6 4.4L14 3C12.2 1.1 9.7 0 7 0S1.8 1.1 0 3l1.4 1.4C2.8 2.9 4.8 2 7 2z"/>
          <path d="M7 6c1.1 0 2.1.5 2.8 1.2L11.2 5.8C10.1 4.7 8.6 4 7 4s-3.1.7-4.2 1.8l1.4 1.4C4.9 6.5 5.9 6 7 6z"/>
          <circle cx="7" cy="9" r="1"/>
        </svg>
        <svg width="22" height="10" viewBox="0 0 22 10" fill="none">
          <rect x="0.5" y="0.5" width="18" height="9" rx="2" stroke="white" stroke-opacity="0.5"/>
          <rect x="1.5" y="1.5" width="14" height="7" rx="1.5" fill="white"/>
          <path d="M20 3.5v3a1.5 1.5 0 000-3z" fill="white" opacity="0.4"/>
        </svg>
      </span>
    </div>
    <div class="screen">"""

PHONE_CLOSE = """    </div>
    <div class="home-indicator"></div>
  </div>
</div>"""

PAGE_CSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: #1a1a1a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
       display: flex; flex-direction: column; align-items: center; min-height: 100vh;
       padding: 24px 16px; }
.phone-wrap { display:flex; justify-content:center; }
.phone {
  width: 390px;
  min-height: 844px;
  border: 6px solid #222;
  border-radius: 48px;
  background: #111;
  box-shadow: 0 0 0 2px #333, 0 24px 60px rgba(0,0,0,.8), inset 0 0 0 1px #444;
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
}
.status-bar {
  background: #8B1A1A;
  padding: 12px 20px 6px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: white;
  font-size: 12px;
  font-weight: 700;
  flex-shrink: 0;
}
.screen {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  position: relative;
}
.home-indicator {
  height: 20px;
  background: #1a1a1a;
  display: flex;
  align-items: center;
  justify-content: center;
}
.home-indicator::after {
  content: '';
  width: 120px; height: 4px;
  background: #555;
  border-radius: 2px;
}
"""

def full_page(title: str, css: str, body: str, extra_head: str = "") -> str:
    return f"""<!DOCTYPE html>
<html lang="ms">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title} — i.-GB Simulated UI</title>
<style>
{PAGE_CSS}
{css}
</style>
{extra_head}
</head>
<body>
{BACK_LINK}
{PHONE_OPEN}
{body}
{PHONE_CLOSE}
</body>
</html>"""

# ═══════════════════════════════════════════════════════════════════════════════
# index.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_index():
    screens = [
        ("01_splash.html",     "01 Splash",        "Auto-navigate to Home. Logo coin-flip animation."),
        ("02_loading.html",    "02 Loading",        "Topic image flipping while app loads."),
        ("03_home.html",       "03 Home",           "Player name, topic picker, start game."),
        ("04_tutorial.html",   "04 Tutorial",       "4-step walkthrough with illustrations."),
        ("05_scanner.html",    "05 Scanner",        "Camera view with AR scan viewfinder."),
        ("06_flipcard.html",   "06 Flip Card",      "3D flip card revealing landmark info."),
        ("07_question.html",   "07 Question MCQ",   "Multiple-choice question with feedback."),
        ("08_soalselidik.html","08 Soal Selidik",   "Survey / questionnaire bottom sheet."),
        ("09_gameboard.html",  "09 Game Board",     "5×6 snakes-and-ladders board game."),
        ("10_nota.html",       "10 Nota",           "Reference notes: Melaka places + game tips."),
        ("11_about.html",      "11 About",          "App info and team credits."),
    ]

    cards_html = ""
    for href, name, desc in screens:
        cards_html += f"""
      <div class="card" onclick="location.href='{href}'">
        <div class="phone-icon">
          <div class="pi-frame"><div class="pi-screen"></div></div>
        </div>
        <div class="card-body">
          <div class="card-name">{name}</div>
          <div class="card-desc">{desc}</div>
          <a href="{href}" class="open-btn">Open →</a>
        </div>
      </div>"""

    html = f"""<!DOCTYPE html>
<html lang="ms">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>i.-GB — Simulated UI Gallery</title>
<style>
* {{ box-sizing: border-box; margin:0; padding:0; }}
body {{ background:#1a1a1a; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
        color:#eee; min-height:100vh; padding:40px 24px; }}
h1 {{ text-align:center; font-size:28px; font-weight:800; margin-bottom:6px;
     background: linear-gradient(135deg, #B8860B, #FFD700);
     -webkit-background-clip:text; -webkit-text-fill-color:transparent; }}
.subtitle {{ text-align:center; color:#888; font-size:14px; margin-bottom:36px; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr));
         gap:20px; max-width:900px; margin:0 auto; }}
.card {{ background:#252525; border:1px solid #333; border-radius:16px;
         padding:20px; display:flex; gap:16px; align-items:flex-start;
         cursor:pointer; transition:transform 0.15s, border-color 0.15s; }}
.card:hover {{ transform:translateY(-3px); border-color:#B8860B; }}
.phone-icon {{ flex-shrink:0; }}
.pi-frame {{ width:36px; height:64px; border:3px solid #555; border-radius:8px;
             background:#111; display:flex; flex-direction:column;
             align-items:center; justify-content:center; padding:4px; }}
.pi-screen {{ width:100%; flex:1; background:#8B1A1A; border-radius:3px; }}
.card-body {{ flex:1; }}
.card-name {{ font-weight:700; font-size:15px; color:#fff; margin-bottom:4px; }}
.card-desc {{ font-size:12px; color:#999; line-height:1.5; margin-bottom:10px; }}
.open-btn {{ display:inline-block; background:#8B1A1A; color:#fff; padding:5px 14px;
             border-radius:6px; font-size:12px; font-weight:700; text-decoration:none; }}
.open-btn:hover {{ background:#B8860B; }}
</style>
</head>
<body>
<h1>i.-GB — Simulated UI Gallery</h1>
<p class="subtitle">11 app screens · Standalone HTML · Interactive simulations</p>
<div class="grid">
{cards_html}
</div>
</body>
</html>"""
    write_html("index.html", html)

# ═══════════════════════════════════════════════════════════════════════════════
# 01_splash.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_splash():
    logo_b64 = b64img("assets/images/logo_igb.png")
    css = """
.splash { background:#8B1A1A; height:100%; display:flex; flex-direction:column;
           align-items:center; justify-content:center; gap:24px; min-height:780px; }
.logo-wrap { animation: coinFlip 2.6s ease-in-out infinite; }
@keyframes coinFlip {
  0%   { transform: rotateY(0deg);   }
  45%  { transform: rotateY(360deg); }
  100% { transform: rotateY(360deg); }
}
.app-title { color:white; font-size:28px; font-weight:800; letter-spacing:2px; }
"""
    body = f"""<div class="splash">
  <div class="logo-wrap">
    <img src="{logo_b64}" width="200" height="200" alt="i.-GB Logo" style="border-radius:100px">
  </div>
  <div class="app-title">i.-GB</div>
</div>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 01 — Splash</strong><br>
  Auto-navigate to Home after <b>3.2 s</b>. The i.-GB logo plays a CSS <b>rotateY(0→360°)</b> coin-flip animation repeating every 2.6 s. Red background (#8B1A1A). No user interaction required.
</div>"""
    page = full_page("Splash", css, body)
    # inject annotation before </body>
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("01_splash.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 02_loading.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_loading():
    topics = {
        "Sejarah Melaka": "assets/images/topics/topic_sejarah_melaka.png",
        "Seni Bina":      "assets/images/topics/topic_seni_bina.png",
        "Budaya":         "assets/images/topics/topic_budaya.png",
        "Pelancongan":    "assets/images/topics/topic_pelancongan.png",
        "Matematik":      "assets/images/topics/topic_matematik.png",
    }
    imgs_js = "{" + ",".join(f'"{k}":"{b64img(v)}"' for k,v in topics.items()) + "}"

    css = """
.loading-screen { background:#8B1A1A; height:100%; min-height:780px;
  display:flex; flex-direction:column; align-items:center; justify-content:center; gap:20px; padding:24px; }
.img-flip { animation: coinFlip 2.6s ease-in-out infinite; border-radius:16px; overflow:hidden; }
@keyframes coinFlip {
  0%   { transform: rotateY(0deg);   }
  45%  { transform: rotateY(360deg); }
  100% { transform: rotateY(360deg); }
}
.dots { display:flex; gap:12px; }
.dot { width:10px; height:10px; border-radius:50%; background:white; opacity:0.3;
       animation: pulse 1.2s ease-in-out infinite; }
.dot:nth-child(2) { animation-delay:.4s; }
.dot:nth-child(3) { animation-delay:.8s; }
@keyframes pulse { 0%,100%{opacity:.3;transform:scale(1)} 50%{opacity:1;transform:scale(1.3)} }
select { background:#3a0a0a; color:white; border:1px solid #B8860B; border-radius:8px;
         padding:6px 12px; font-size:13px; margin-top:8px; }
"""
    body = f"""<div class="loading-screen">
  <div class="img-flip">
    <img id="topicImg" src="{b64img('assets/images/topics/topic_sejarah_melaka.png')}" width="180" height="180" style="border-radius:16px;object-fit:cover" alt="Topic">
  </div>
  <div class="dots"><div class="dot"></div><div class="dot"></div><div class="dot"></div></div>
  <select onchange="switchTopic(this.value)">
    <option value="Sejarah Melaka">Sejarah Melaka</option>
    <option value="Seni Bina">Seni Bina</option>
    <option value="Budaya">Budaya</option>
    <option value="Pelancongan">Pelancongan</option>
    <option value="Matematik">Matematik</option>
  </select>
</div>
<script>
var imgs = {imgs_js};
function switchTopic(t) {{
  document.getElementById('topicImg').src = imgs[t];
}}
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 02 — Loading</strong><br>
  Topic image flips (coin-flip CSS animation) while the AR session loads. Three animated pulsing white dots below. Navigates to the next screen after ~1.8 s. Use the dropdown to preview all 5 topic images.
</div>"""
    page = full_page("Loading", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("02_loading.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 03_home.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_home():
    logo = b64img("assets/images/logo_igb.png")
    topics_data = [
        ("Sejarah Melaka", b64img("assets/images/topics/topic_sejarah_melaka.png")),
        ("Seni Bina",      b64img("assets/images/topics/topic_seni_bina.png")),
        ("Budaya",         b64img("assets/images/topics/topic_budaya.png")),
        ("Pelancongan",    b64img("assets/images/topics/topic_pelancongan.png")),
        ("Matematik",      b64img("assets/images/topics/topic_matematik.png")),
    ]
    topic_cards_html = ""
    for i, (name, img) in enumerate(topics_data):
        selected = "selected" if i == 0 else ""
        topic_cards_html += f"""<div class="topic-card {selected}" onclick="selectTopic(this,'{name}')" data-name="{name}">
  <img src="{img}" alt="{name}">
</div>"""

    css = """
.home-screen { background: linear-gradient(180deg,#8B1A1A 0%,#3a0a0a 100%);
               min-height:780px; padding:16px 20px 24px; position:relative; overflow-x:hidden; }
.q-btn { position:absolute; top:16px; right:16px; width:34px; height:34px;
         background:rgba(255,255,255,.24); border:1.5px solid rgba(255,255,255,.38);
         border-radius:50%; display:flex; align-items:center; justify-content:center;
         color:white; font-weight:800; font-size:16px; cursor:pointer; z-index:10;
         text-decoration:none; }
.logo-area { display:flex; justify-content:center; margin:16px 0 24px; position:relative; }
.logo-wrap { position:relative; width:200px; height:200px; cursor:pointer; transition:transform 0.2s; }
.logo-wrap:active { transform:scale(1.08); }
.star { position:absolute; font-size:16px; pointer-events:none; opacity:0;
        animation: none; }
.logo-wrap.burst .star { animation: flyout 0.7s ease-out forwards; }
.logo-wrap.burst .s1 { animation-delay:0s;   --dx:-80px; --dy:-80px; }
.logo-wrap.burst .s2 { animation-delay:.05s; --dx:80px;  --dy:-70px; }
.logo-wrap.burst .s3 { animation-delay:.10s; --dx:95px;  --dy:20px;  }
.logo-wrap.burst .s4 { animation-delay:.15s; --dx:-75px; --dy:75px;  }
.logo-wrap.burst .s5 { animation-delay:.20s; --dx:-85px; --dy:-40px; }
@keyframes flyout {
  0%   { opacity:1; transform:translate(0,0) scale(1); }
  100% { opacity:0; transform:translate(var(--dx),var(--dy)) scale(0.5); }
}
.card { background:white; border-radius:20px; padding:20px;
        box-shadow:0 8px 20px rgba(0,0,0,.3); margin-bottom:20px; }
.label { font-size:13px; font-weight:700; color:#8B1A1A; margin-bottom:6px; }
.name-input { width:100%; border:1.5px solid #ccc; border-radius:12px;
              padding:10px 12px 10px 36px; font-size:14px; outline:none;
              transition:border-color 0.2s; }
.name-input:focus { border-color:#8B1A1A; box-shadow:0 0 0 2px rgba(139,26,26,.15); }
.input-wrap { position:relative; }
.input-wrap::before { content:'👤'; position:absolute; left:10px; top:50%; transform:translateY(-50%); font-size:16px; }
.topics-scroll { display:flex; gap:10px; overflow-x:auto; padding:4px 0 8px;
                 scrollbar-width:none; }
.topics-scroll::-webkit-scrollbar { display:none; }
.topic-card { flex-shrink:0; width:130px; height:130px; border-radius:14px; overflow:hidden;
              border:3px solid transparent; cursor:pointer; transition:border-color 0.2s, box-shadow 0.2s; }
.topic-card img { width:100%; height:100%; object-fit:cover; }
.topic-card.selected { border-color:#8B1A1A; box-shadow:0 4px 14px rgba(139,26,26,.5); }
.dots-row { display:flex; justify-content:center; gap:6px; margin:8px 0 4px; }
.dot-ind { width:6px; height:6px; border-radius:3px; background:#ccc; transition:all .3s; }
.dot-ind.active { width:16px; background:#8B1A1A; }
.topic-label { text-align:center; font-size:12px; font-weight:700; color:#8B1A1A; }
.btn-gold { background:#B8860B; color:white; border:none; border-radius:14px;
            padding:14px; width:100%; font-size:17px; font-weight:800; letter-spacing:.5px;
            cursor:pointer; transition:opacity .2s; margin-bottom:10px; }
.btn-gold:hover { opacity:.9; }
.btn-outline { background:transparent; color:white; border:1.5px solid rgba(255,255,255,.54);
               border-radius:14px; padding:12px; width:100%; font-size:15px; font-weight:600;
               cursor:pointer; margin-bottom:10px; }
.btn-row { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
/* Dialog */
.dialog-overlay { position:fixed; inset:0; background:rgba(0,0,0,.6);
                  display:none; align-items:center; justify-content:center; z-index:999; }
.dialog-overlay.show { display:flex; }
.dialog-box { background:white; border-radius:16px; padding:24px; max-width:320px; width:90%; }
.dialog-title { display:flex; align-items:center; gap:8px; font-size:17px; font-weight:700;
                color:#333; margin-bottom:12px; }
.dialog-body { font-size:14px; color:#555; line-height:1.6; margin-bottom:20px; }
.dialog-ok { background:transparent; color:#8B1A1A; font-weight:700; border:none;
             font-size:15px; cursor:pointer; float:right; }
"""
    body = f"""<div class="home-screen">
  <a class="q-btn" href="11_about.html" title="About">?</a>
  <div class="logo-area">
    <div class="logo-wrap" id="logoWrap" onclick="burstStars()">
      <img src="{logo}" width="200" height="200" alt="i.-GB" style="border-radius:100px">
      <span class="star s1">⭐</span>
      <span class="star s2">⭐</span>
      <span class="star s3">⭐</span>
      <span class="star s4">⭐</span>
      <span class="star s5">⭐</span>
    </div>
  </div>

  <div class="card">
    <div class="label">Nama Pemain</div>
    <div class="input-wrap" style="margin-bottom:16px">
      <input class="name-input" id="nameInput" placeholder="Nama" type="text">
    </div>
    <div class="label">Pilih Topik</div>
    <div class="topics-scroll" id="topicsScroll">
      {topic_cards_html}
    </div>
    <div class="dots-row" id="dotsRow">
      <div class="dot-ind active" id="dot0"></div>
      <div class="dot-ind" id="dot1"></div>
      <div class="dot-ind" id="dot2"></div>
      <div class="dot-ind" id="dot3"></div>
      <div class="dot-ind" id="dot4"></div>
    </div>
    <div class="topic-label" id="topicLabel">Sejarah Melaka</div>
  </div>

  <button class="btn-gold" onclick="startGame()">🎮 MAIN i.-GB</button>
  <button class="btn-outline" onclick="alert('Demo AR Flutter — Buka AR Flutter viewer')">📦 Demo AR Flutter</button>
  <div class="btn-row">
    <button class="btn-outline" onclick="location.href='04_tutorial.html'">📖 Tutorial</button>
    <button class="btn-outline" onclick="location.href='10_nota.html'">📝 Nota</button>
  </div>
</div>

<!-- Dialog: name required -->
<div class="dialog-overlay" id="dlgName">
  <div class="dialog-box">
    <div class="dialog-title"><span style="color:#8B1A1A">👤</span> Nama Diperlukan</div>
    <div class="dialog-body">Sila masukkan nama pemain sebelum memulakan permainan.</div>
    <button class="dialog-ok" onclick="closeDialog('dlgName')">OK</button>
    <div style="clear:both"></div>
  </div>
</div>
<!-- Dialog: game start -->
<div class="dialog-overlay" id="dlgStart">
  <div class="dialog-box">
    <div class="dialog-title">🎮 Mulakan Permainan</div>
    <div class="dialog-body" id="dlgStartBody"></div>
    <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:8px">
      <button onclick="closeDialog('dlgStart')" style="background:transparent;border:1px solid #ccc;padding:8px 16px;border-radius:8px;cursor:pointer">Batal</button>
      <a href="09_gameboard.html"><button style="background:#B8860B;color:white;border:none;padding:8px 16px;border-radius:8px;font-weight:700;cursor:pointer">Mula!</button></a>
    </div>
  </div>
</div>
<script>
var currentTopic = 'Sejarah Melaka';
function selectTopic(el, name) {{
  document.querySelectorAll('.topic-card').forEach((c,i) => {{
    c.classList.remove('selected');
    document.getElementById('dot'+i).classList.remove('active');
  }});
  el.classList.add('selected');
  var idx = Array.from(document.querySelectorAll('.topic-card')).indexOf(el);
  document.getElementById('dot'+idx).classList.add('active');
  document.getElementById('topicLabel').textContent = name;
  currentTopic = name;
}}
function startGame() {{
  var name = document.getElementById('nameInput').value.trim();
  if (!name) {{ document.getElementById('dlgName').classList.add('show'); return; }}
  document.getElementById('dlgStartBody').innerHTML =
    '<b>' + name + '</b> sedang memulakan permainan topik <b>' + currentTopic + '</b>. Selamat bermain!';
  document.getElementById('dlgStart').classList.add('show');
}}
function closeDialog(id) {{ document.getElementById(id).classList.remove('show'); }}
function burstStars() {{
  var w = document.getElementById('logoWrap');
  w.classList.remove('burst');
  void w.offsetWidth;
  w.classList.add('burst');
  setTimeout(function(){{ w.classList.remove('burst'); }}, 900);
}}
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 03 — Home</strong><br>
  Entry point. Tap the logo for a ⭐ star-burst animation. Type a name, swipe/tap topic cards (5 topics). Tap <b>🎮 MAIN i.-GB</b> — validates name (dialog if empty), then shows game-start confirmation. Buttons: Demo AR, Tutorial, Nota.
</div>"""
    page = full_page("Home", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("03_home.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 04_tutorial.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_tutorial():
    steps = [
        {
            "num": "01",
            "title": "Imbas Papan Permainan",
            "desc": "Arahkan kamera telefon ke atas papan permainan fizikal i.-GB. Cari kotak AR yang ditanda dan pastikan pencahayaan mencukupi.",
            "illus": """<div style="background:#1a1a1a;border-radius:16px;width:200px;height:180px;
              display:flex;align-items:center;justify-content:center;position:relative;margin:0 auto">
              <div style="width:140px;height:140px;position:relative">
                <div style="position:absolute;top:0;left:0;width:30px;height:30px;
                  border-top:3px solid #4CAF50;border-left:3px solid #4CAF50"></div>
                <div style="position:absolute;top:0;right:0;width:30px;height:30px;
                  border-top:3px solid #4CAF50;border-right:3px solid #4CAF50"></div>
                <div style="position:absolute;bottom:0;left:0;width:30px;height:30px;
                  border-bottom:3px solid #4CAF50;border-left:3px solid #4CAF50"></div>
                <div style="position:absolute;bottom:0;right:0;width:30px;height:30px;
                  border-bottom:3px solid #4CAF50;border-right:3px solid #4CAF50"></div>
                <div style="position:absolute;inset:0;display:flex;align-items:center;
                  justify-content:center;color:white;font-size:28px">📱</div>
              </div>
              <div style="position:absolute;bottom:12px;background:#4CAF50;color:white;
                font-size:11px;padding:3px 10px;border-radius:20px">Mengimbas...</div>
            </div>"""
        },
        {
            "num": "02",
            "title": "Kad Tempat Muncul",
            "desc": "Kad AR akan muncul di skrin anda dengan gambar tempat bersejarah Melaka. Ketik kad untuk meneruskan ke soalan.",
            "illus": """<div style="display:flex;flex-direction:column;align-items:center;gap:10px">
              <div style="background:white;border-radius:12px;width:160px;padding:10px;
                box-shadow:0 4px 16px rgba(0,0,0,.3)">
                <div style="background:#8B1A1A;height:80px;border-radius:8px;display:flex;
                  align-items:center;justify-content:center;color:white;font-size:28px">🏰</div>
                <div style="background:#8B1A1A;margin-top:6px;border-radius:6px;padding:4px;
                  text-align:center;color:white;font-size:11px;font-weight:700">A'Famosa</div>
              </div>
              <div style="color:#4CAF50;font-size:20px">↻ Ketik untuk soalan →</div>
            </div>"""
        },
        {
            "num": "03",
            "title": "Jawab Soalan",
            "desc": "Pilih jawapan yang betul daripada 4 pilihan. Jawapan betul menambah markah anda. Jawapan salah tiada penalti.",
            "illus": """<div style="background:white;border-radius:12px;width:200px;padding:12px;
              box-shadow:0 4px 16px rgba(0,0,0,.3)">
              <div style="font-size:11px;font-weight:700;color:#8B1A1A;margin-bottom:8px">
                Siapakah pengasas Melaka?</div>
              <div style="font-size:11px;background:#f5f5f5;border-radius:8px;
                padding:6px 8px;margin-bottom:4px;border-left:3px solid #8B1A1A">A. Parameswara</div>
              <div style="font-size:11px;background:#f5f5f5;border-radius:8px;
                padding:6px 8px;margin-bottom:4px">B. Sultan Mahmud</div>
              <div style="font-size:11px;background:#f5f5f5;border-radius:8px;
                padding:6px 8px">C. Hang Tuah</div>
            </div>"""
        },
        {
            "num": "04",
            "title": "Kumpul Ganjaran",
            "desc": "Kumpulkan markah dengan menjawab soalan dengan betul. Naik tangga dan elak ular untuk mencapai petak TAMAT!",
            "illus": """<div style="display:flex;flex-direction:column;align-items:center;gap:12px">
              <div style="font-size:48px">🏆</div>
              <div style="background:#8B1A1A;color:white;border-radius:20px;
                padding:8px 20px;font-size:13px;font-weight:700">+10 Markah!</div>
              <div style="color:#B8860B;font-size:22px">⭐⭐⭐</div>
            </div>"""
        },
    ]

    steps_js = "var steps = " + str(len(steps)) + ";\n"
    css = """
.tut-screen { background:#8B1A1A; min-height:780px; display:flex; flex-direction:column; }
.tut-topbar { display:flex; align-items:center; gap:12px; padding:12px 16px 8px;
              background:rgba(0,0,0,.2); flex-shrink:0; }
.back-circle { width:36px; height:36px; border-radius:50%; background:rgba(255,255,255,.24);
               display:flex; align-items:center; justify-content:center;
               color:white; font-size:18px; cursor:pointer; text-decoration:none; }
.tut-title { color:white; font-size:18px; font-weight:800; }
.tut-content { flex:1; display:flex; flex-direction:column; }
.step { display:none; flex:1; flex-direction:column; }
.step.active { display:flex; }
.illus-area { background:#FFF3E0; flex:0 0 56%; display:flex; align-items:center;
              justify-content:center; padding:24px; }
.text-area { background:white; flex:1; padding:20px; position:relative; }
.step-badge { background:#8B1A1A; color:white; font-size:10px; font-weight:800;
              padding:4px 12px; border-radius:20px; display:inline-block; margin-bottom:10px; }
.step-heading { font-size:18px; font-weight:800; color:#1a1a1a; margin-bottom:8px; }
.step-desc { font-size:13px; color:#555; line-height:1.7; }
.tut-bottom { padding:16px 20px; background:white; display:flex; flex-direction:column;
              align-items:center; gap:14px; flex-shrink:0; }
.dots-tut { display:flex; gap:8px; }
.dot-tut { height:8px; border-radius:4px; background:rgba(255,255,255,.38); transition:all .3s; }
.dot-tut.active { width:24px; background:#FFB300; }
.dot-tut:not(.active) { width:8px; }
.btn-next { background:#8B1A1A; color:white; border:none; border-radius:14px;
            padding:14px 32px; font-size:15px; font-weight:700; cursor:pointer;
            width:100%; transition:background .2s; }
.btn-next.gold { background:#B8860B; }
.btn-next:hover { opacity:.9; }
"""
    steps_html = ""
    for i, s in enumerate(steps):
        steps_html += f"""<div class="step {'active' if i==0 else ''}" id="step{i}">
  <div class="illus-area">{s['illus']}</div>
  <div class="text-area">
    <div class="step-badge">LANGKAH {s['num']}</div>
    <div class="step-heading">{s['title']}</div>
    <div class="step-desc">{s['desc']}</div>
  </div>
</div>"""

    dots_html = "".join(f'<div class="dot-tut {"active" if i==0 else ""}" id="dtut{i}"></div>' for i in range(len(steps)))

    body = f"""<div class="tut-screen">
  <div class="tut-topbar">
    <a href="03_home.html" class="back-circle">←</a>
    <div class="tut-title">Tutorial</div>
  </div>
  <div class="tut-content">
{steps_html}
  </div>
  <div class="tut-bottom" style="background:#8B1A1A">
    <div class="dots-tut">{dots_html}</div>
    <button class="btn-next" id="nextBtn" onclick="nextStep()">Seterusnya</button>
  </div>
</div>
<script>
var cur = 0; var total = {len(steps)};
function nextStep() {{
  if (cur >= total-1) {{ location.href='05_scanner.html'; return; }}
  document.getElementById('step'+cur).classList.remove('active');
  document.getElementById('dtut'+cur).classList.remove('active');
  cur++;
  document.getElementById('step'+cur).classList.add('active');
  document.getElementById('dtut'+cur).classList.add('active');
  var btn = document.getElementById('nextBtn');
  if (cur === total-1) {{ btn.textContent = 'Mula Bermain!'; btn.classList.add('gold'); }}
  else {{ btn.textContent = 'Seterusnya'; btn.classList.remove('gold'); }}
}}
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 04 — Tutorial</strong><br>
  4-step illustrated walkthrough: Scan Board → Flip Card appears → Answer Question → Collect Rewards. Tap <b>Seterusnya</b> to advance steps. Last step button becomes gold "Mula Bermain!" and navigates to Scanner.
</div>"""
    page = full_page("Tutorial", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("04_tutorial.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 05_scanner.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_scanner():
    css = """
.scanner-screen { background:#111; min-height:780px; position:relative;
                  display:flex; flex-direction:column; overflow:hidden; }
.cam-bg { position:absolute; inset:0;
          background: radial-gradient(ellipse at center, #1a2a1a 0%, #0a0a0a 70%); }
.scan-top { position:relative; z-index:10; display:flex; justify-content:space-between;
            align-items:center; padding:12px 16px; }
.circle-btn { width:40px; height:40px; background:rgba(255,255,255,.18); border-radius:50%;
              display:flex; align-items:center; justify-content:center; color:white;
              font-size:18px; cursor:pointer; text-decoration:none; border:none; }
.pill-btn { background:rgba(255,255,255,.9); color:#1a1a1a; border:none; border-radius:20px;
            padding:8px 16px; font-size:13px; font-weight:700; cursor:pointer; }
.viewfinder-wrap { position:relative; z-index:10; display:flex; align-items:center;
                   justify-content:center; flex:1; }
.viewfinder { width:220px; height:220px; position:relative; }
.vf-corner { position:absolute; width:36px; height:36px; border-color:white; border-style:solid; }
.vf-tl { top:0; left:0;  border-width:3px 0 0 3px; }
.vf-tr { top:0; right:0; border-width:3px 3px 0 0; }
.vf-bl { bottom:0; left:0; border-width:0 0 3px 3px; }
.vf-br { bottom:0; right:0; border-width:0 3px 3px 0; }
.scan-line { position:absolute; left:0; right:0; height:2px;
             background:rgba(100,255,100,.7);
             animation: scanline 2s ease-in-out infinite; }
@keyframes scanline { 0%{top:0} 50%{top:calc(100% - 2px)} 100%{top:0} }
.scan-bottom { position:relative; z-index:10; background:rgba(0,0,0,.7);
               margin:0 16px 16px; border-radius:16px; padding:16px;
               display:flex; flex-direction:column; align-items:center; gap:6px; }
.scan-icon { font-size:28px; }
.scan-bold { color:white; font-size:15px; font-weight:700; }
.scan-sub  { color:rgba(255,255,255,.6); font-size:12px; text-align:center; }
.sim-btn { background:#8B1A1A; color:white; border:none; border-radius:12px;
           padding:10px 24px; font-size:14px; font-weight:700; margin-top:8px;
           cursor:pointer; }
/* flip card overlay */
.fc-overlay { position:fixed; inset:0; background:rgba(0,0,0,.85);
              display:none; align-items:center; justify-content:center; z-index:100; }
.fc-overlay.show { display:flex; }
"""
    # we'll embed a mini flip-card inside scanner overlay
    afamosa = b64img("assets/imagesscan/afamosa.png")
    body = f"""<div class="scanner-screen">
  <div class="cam-bg"></div>
  <div class="scan-top">
    <a href="03_home.html" class="circle-btn">←</a>
    <button class="pill-btn" onclick="location.href='08_soalselidik.html'">Soal Selidik</button>
  </div>
  <div class="viewfinder-wrap">
    <div class="viewfinder">
      <div class="vf-corner vf-tl"></div>
      <div class="vf-corner vf-tr"></div>
      <div class="vf-corner vf-bl"></div>
      <div class="vf-corner vf-br"></div>
      <div class="scan-line"></div>
    </div>
  </div>
  <div class="scan-bottom">
    <div class="scan-icon">🔍</div>
    <div class="scan-bold">Hala kamera ke papan permainan</div>
    <div class="scan-sub">Imbas kotak papan untuk dapatkan soalan</div>
    <button class="sim-btn" onclick="document.getElementById('fcOverlay').classList.add('show')">SIMULATE SCAN</button>
  </div>
</div>
<!-- Flip card overlay triggered by simulate scan -->
<div class="fc-overlay" id="fcOverlay" onclick="if(event.target===this) this.classList.remove('show')">
  <div style="background:white;border-radius:20px;width:300px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.5)">
    <img src="{afamosa}" style="width:100%;height:180px;object-fit:cover" alt="A'Famosa">
    <div style="background:#8B1A1A;padding:10px 16px;display:flex;justify-content:space-between;align-items:center">
      <span style="color:white;font-weight:700;font-size:14px">🏰 A'Famosa</span>
      <span style="color:rgba(255,255,255,.7);font-size:11px">Ketik untuk soalan →</span>
    </div>
    <div style="padding:12px 16px 16px;text-align:center">
      <a href="06_flipcard.html" style="background:#B8860B;color:white;border:none;border-radius:10px;
        padding:10px 24px;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-block">
        Teruskan ke Soalan →
      </a>
      <button onclick="document.getElementById('fcOverlay').classList.remove('show')"
        style="display:block;margin:8px auto 0;background:none;border:none;color:#888;cursor:pointer;font-size:12px">
        Tutup
      </button>
    </div>
  </div>
</div>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 05 — Scanner</strong><br>
  Simulates the ARCore camera view with a green scanning line inside white bracket corners (220×220 viewfinder). "Soal Selidik" pill button top-right. Tap <b>SIMULATE SCAN</b> to show a flip-card overlay (A'Famosa). Tap "Teruskan ke Soalan" to navigate to the flip-card screen.
</div>"""
    page = full_page("Scanner", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("05_scanner.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 06_flipcard.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_flipcard():
    landmarks = [
        ("A'Famosa",              "assets/imagesscan/afamosa.png"),
        ("Cheng Hoon Teng Temple","assets/imagesscan/chenghoontengtemple.png"),
        ("Christ Church Melaka",  "assets/imagesscan/christchurchmelaka.png"),
        ("Jonker Street Melaka",  "assets/imagesscan/junkerstreetmelaka.png"),
        ("Masjid Selat Melaka",   "assets/imagesscan/masjidselatmelaka.png"),
        ("Menara Taming Sari",    "assets/imagesscan/menaratamingsari.png"),
        ("Muzium Kapal Selam",    "assets/imagesscan/muziumkapalselammelaka.png"),
        ("Stadthuys Melaka",      "assets/imagesscan/stadhuysmelaka.png"),
        ("St. Paul's Hill Church","assets/imagesscan/stpaulhillchurch.png"),
        ("Beca Melaka",           "assets/imagesscan/trishaw.png"),
    ]
    imgs_js = "{" + ",".join(f'"{name}":"{b64img(path)}"' for name,path in landmarks) + "}"
    opts_html = "".join(f'<option value="{n}">{n}</option>' for n,_ in landmarks)

    css = """
.fc-screen { background:#1a1a1a; min-height:780px; display:flex; flex-direction:column;
             align-items:center; justify-content:flex-start; padding:16px; }
.fc-top { width:100%; display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; }
.circle-btn { width:40px; height:40px; background:rgba(255,255,255,.18); border-radius:50%;
              display:flex; align-items:center; justify-content:center;
              color:white; font-size:18px; cursor:pointer; text-decoration:none; border:none; }
select { background:#2a2a2a; color:white; border:1px solid #B8860B; border-radius:8px;
         padding:6px 10px; font-size:13px; }
.scene { width:300px; height:360px; perspective:1000px; margin:20px 0; }
.card-3d { width:100%; height:100%; position:relative; transform-style:preserve-3d;
           transition:transform 0.7s ease-in-out; cursor:pointer; }
.card-3d.flipped { transform: rotateY(180deg); }
.card-face { position:absolute; inset:0; backface-visibility:hidden; border-radius:20px; overflow:hidden;
             box-shadow:0 16px 48px rgba(0,0,0,.6); }
.card-back { transform: rotateY(180deg); }
.hint { color:rgba(255,255,255,.6); font-size:12px; margin-top:8px; }
"""
    first_img = b64img("assets/imagesscan/afamosa.png")
    body = f"""<div class="fc-screen">
  <div class="fc-top">
    <a href="05_scanner.html" class="circle-btn">←</a>
    <select onchange="changeLandmark(this.value)">{opts_html}</select>
  </div>
  <div class="scene">
    <div class="card-3d" id="card3d" onclick="flipCard()">
      <!-- FRONT -->
      <div class="card-face">
        <img id="frontImg" src="{first_img}" style="width:100%;height:260px;object-fit:cover" alt="Place">
        <div style="background:#8B1A1A;padding:12px 16px;display:flex;justify-content:space-between;align-items:center">
          <span id="frontName" style="color:white;font-weight:700;font-size:15px">🏰 A'Famosa</span>
          <span style="color:rgba(255,255,255,.7);font-size:11px">Ketik untuk soalan →</span>
        </div>
        <div style="background:white;padding:12px 16px;text-align:center">
          <span style="font-size:12px;color:#555">Ketik kad untuk melihat soalan</span>
        </div>
      </div>
      <!-- BACK -->
      <div class="card-face card-back" style="background:linear-gradient(135deg,#8B1A1A,#3a0a0a)">
        <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;padding:24px;gap:16px">
          <div style="font-size:48px">❓</div>
          <div id="backName" style="color:white;font-size:18px;font-weight:800;text-align:center">A'Famosa</div>
          <div style="color:rgba(255,255,255,.75);font-size:14px;text-align:center;line-height:1.6">
            Adakah anda bersedia untuk menjawab soalan tentang tempat ini?
          </div>
          <a href="07_question.html" style="background:#B8860B;color:white;border:none;border-radius:14px;
            padding:12px 24px;font-size:14px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-block;margin-top:8px">
            Teruskan ke Soalan →
          </a>
        </div>
      </div>
    </div>
  </div>
  <div class="hint">Ketik kad untuk flip 3D</div>
</div>
<script>
var imgs = {imgs_js};
var flipped = false;
function flipCard() {{
  flipped = !flipped;
  document.getElementById('card3d').classList.toggle('flipped', flipped);
}}
function changeLandmark(name) {{
  document.getElementById('frontImg').src = imgs[name] || '';
  document.getElementById('frontName').textContent = '🏛️ ' + name;
  document.getElementById('backName').textContent = name;
  if (flipped) {{
    document.getElementById('card3d').classList.remove('flipped');
    flipped = false;
    setTimeout(function(){{
      document.getElementById('card3d').classList.add('flipped');
      flipped = true;
    }}, 100);
  }}
}}
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 06 — Flip Card</strong><br>
  CSS 3D perspective card flip (rotateY 180°). Front shows the place image + red title bar. Back shows red gradient, quiz icon, place name, "Adakah anda bersedia?" prompt, and amber "Teruskan ke Soalan" button. Use the dropdown to preview all 10 landmarks.
</div>"""
    page = full_page("Flip Card", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("06_flipcard.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 07_question.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_question():
    questions_by_topic = {
        "Sejarah Melaka": [
            {"q": "Siapakah pengasas Kesultanan Melaka?",
             "opts": ["Parameswara", "Sultan Mahmud Shah", "Hang Tuah", "Tun Perak"],
             "correct": 0, "landmark": "Muzium Kesultanan Melaka", "emoji": "👑"},
            {"q": "Pada tahun berapa Portugis menakluki Melaka?",
             "opts": ["1511", "1641", "1824", "1957"],
             "correct": 0, "landmark": "Kota A-Famosa", "emoji": "🏰"},
            {"q": "Kuasa Eropah manakah yang membina Kota A-Famosa?",
             "opts": ["Portugis", "Belanda", "British", "Sepanyol"],
             "correct": 0, "landmark": "Kota A-Famosa", "emoji": "🏰"},
            {"q": "Pada tahun berapa Melaka diisytiharkan Tapak Warisan UNESCO?",
             "opts": ["2008", "2000", "1995", "2012"],
             "correct": 0, "landmark": "Pusat Bandar Melaka", "emoji": "🌏"},
            {"q": "Kuasa manakah yang menawan Melaka dari Portugis pada 1641?",
             "opts": ["Belanda", "British", "Sepanyol", "Perancis"],
             "correct": 0, "landmark": "Stadthuys", "emoji": "🏛️"},
        ],
        "Budaya": [
            {"q": "Apakah yang dimaksudkan dengan komuniti 'Baba Nyonya'?",
             "opts": ["Peranakan Cina", "Peranakan India", "Peranakan Arab", "Peranakan Bugis"],
             "correct": 0, "landmark": "Muzium Baba Nyonya", "emoji": "🎎"},
            {"q": "Apakah makanan Melaka yang paling terkenal?",
             "opts": ["Nasi Ayam Bola", "Nasi Lemak", "Char Kuey Teow", "Laksa Penang"],
             "correct": 0, "landmark": "Jalan Hang Jebat", "emoji": "🍚"},
            {"q": "Apakah kenderaan ikonik di bandar Melaka?",
             "opts": ["Beca berhias", "Kereta lembu", "Bot nelayan", "Monorail"],
             "correct": 0, "landmark": "Bandar Hilir", "emoji": "🛺"},
        ],
    }
    import json
    qs_js = json.dumps(questions_by_topic)
    opts_html = '<option value="Sejarah Melaka">Sejarah Melaka</option><option value="Budaya">Budaya</option>'

    css = """
.q-screen { background:rgba(0,0,0,.85); min-height:780px; display:flex;
            flex-direction:column; padding:12px; gap:10px; }
.q-topbar { display:flex; align-items:center; gap:10px; padding:4px 0; }
.back-circle { width:36px; height:36px; background:rgba(255,255,255,.2); border-radius:50%;
               display:flex; align-items:center; justify-content:center;
               color:white; font-size:16px; text-decoration:none; }
select { background:#2a2a2a; color:white; border:1px solid #B8860B; border-radius:8px;
         padding:5px 10px; font-size:12px; }
.q-card { background:white; border-radius:16px; overflow:hidden;
          box-shadow:0 12px 40px rgba(0,0,0,.5); }
.q-header { background:#8B1A1A; padding:14px 16px; }
.q-header-row { display:flex; justify-content:space-between; align-items:center; }
.q-emoji { font-size:22px; }
.q-land { color:white; font-weight:700; font-size:14px; }
.q-badge { background:rgba(255,255,255,.2); color:white; font-size:10px; padding:3px 10px;
           border-radius:10px; }
.q-body { padding:16px; }
.q-num { font-size:11px; color:#888; margin-bottom:8px; }
.q-text { font-size:15px; font-weight:700; color:#1a1a1a; line-height:1.5; margin-bottom:14px; }
.opt-btn { width:100%; text-align:left; background:#f5f5f5; border:1.5px solid #e0e0e0;
           border-radius:10px; padding:10px 14px; font-size:13px; margin-bottom:8px;
           cursor:pointer; transition:all .2s; font-family:inherit; }
.opt-btn:hover:not(:disabled) { border-color:#8B1A1A; background:#faf0f0; }
.opt-btn.correct { background:#E8F5E9; border-color:#4CAF50; color:#1B5E20; font-weight:700; }
.opt-btn.wrong   { background:#FFEBEE; border-color:#f44336; color:#B71C1C; }
.feedback { border-radius:10px; padding:12px 14px; margin:8px 0; font-size:13px;
            font-weight:600; line-height:1.5; }
.feedback.good { background:#E8F5E9; color:#2E7D32; border:1px solid #4CAF50; }
.feedback.bad  { background:#FFEBEE; color:#C62828; border:1px solid #f44336; }
.next-btn { background:#8B1A1A; color:white; border:none; border-radius:12px;
            padding:11px; width:100%; font-size:14px; font-weight:700; cursor:pointer;
            margin-top:4px; }
.q-idx { color:rgba(255,255,255,.7); font-size:12px; }
"""
    body = f"""<div class="q-screen">
  <div class="q-topbar">
    <a href="06_flipcard.html" class="back-circle">←</a>
    <span class="q-idx" id="qIdx">Soalan 1 / 5</span>
    <span style="flex:1"></span>
    <select onchange="changeTopic(this.value)">{opts_html}</select>
  </div>
  <div class="q-card">
    <div class="q-header">
      <div class="q-header-row">
        <div style="display:flex;align-items:center;gap:8px">
          <span class="q-emoji" id="qEmoji">👑</span>
          <span class="q-land" id="qLand">Muzium Kesultanan Melaka</span>
        </div>
        <span class="q-badge" id="qTopic">Sejarah Melaka</span>
      </div>
    </div>
    <div class="q-body">
      <div class="q-text" id="qText">Siapakah pengasas Kesultanan Melaka?</div>
      <div id="optsContainer"></div>
      <div id="feedback" style="display:none"></div>
      <button id="nextBtn" class="next-btn" style="display:none" onclick="nextQuestion()">Imbas Seterusnya →</button>
    </div>
  </div>
</div>
<script>
var allQs = {qs_js};
var topic = 'Sejarah Melaka';
var qList = allQs[topic];
var qIdx = 0;
var answered = false;

function renderQuestion() {{
  var q = qList[qIdx];
  document.getElementById('qIdx').textContent = 'Soalan ' + (qIdx+1) + ' / ' + qList.length;
  document.getElementById('qEmoji').textContent = q.emoji;
  document.getElementById('qLand').textContent = q.landmark;
  document.getElementById('qTopic').textContent = topic;
  document.getElementById('qText').textContent = q.q;
  var labels = ['A','B','C','D'];
  var html = '';
  q.opts.forEach(function(o,i) {{
    html += '<button class="opt-btn" id="opt'+i+'" onclick="answer('+i+')">'+labels[i]+'. '+o+'</button>';
  }});
  document.getElementById('optsContainer').innerHTML = html;
  document.getElementById('feedback').style.display = 'none';
  document.getElementById('nextBtn').style.display = 'none';
  answered = false;
}}

function answer(idx) {{
  if (answered) return;
  answered = true;
  var q = qList[qIdx];
  var btns = document.querySelectorAll('.opt-btn');
  btns.forEach(function(b) {{ b.disabled = true; }});
  if (idx === q.correct) {{
    btns[idx].classList.add('correct');
    document.getElementById('feedback').className = 'feedback good';
    document.getElementById('feedback').innerHTML = '✅ Betul! Markah ditambah! <b>+10 mata</b>';
  }} else {{
    btns[idx].classList.add('wrong');
    btns[q.correct].classList.add('correct');
    document.getElementById('feedback').className = 'feedback bad';
    document.getElementById('feedback').innerHTML = '❌ Salah. Jawapan betul: <b>' + q.opts[q.correct] + '</b>';
  }}
  document.getElementById('feedback').style.display = 'block';
  document.getElementById('nextBtn').style.display = 'block';
}}

function nextQuestion() {{
  qIdx = (qIdx + 1) % qList.length;
  renderQuestion();
}}

function changeTopic(t) {{
  topic = t;
  qList = allQs[t];
  qIdx = 0;
  renderQuestion();
}}

renderQuestion();
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 07 — Question MCQ</strong><br>
  White card with red header (emoji + landmark name + topic badge). Question text + 4 A/B/C/D option buttons. Click to answer: correct turns green, wrong turns red, correct answer highlighted. Feedback box + "Imbas Seterusnya" button appear. Switch topics via dropdown. Loops through all questions.
</div>"""
    page = full_page("Question MCQ", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("07_question.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 08_soalselidik.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_soalselidik():
    css = """
.ss-screen { background:#f5f5f5; min-height:780px; display:flex; flex-direction:column; }
.ss-header { background:#8B1A1A; padding:18px 16px 16px; flex-shrink:0; }
.ss-header-top { display:flex; justify-content:space-between; align-items:flex-start; }
.ss-icon { font-size:28px; }
.ss-title { color:white; font-size:17px; font-weight:800; margin:4px 0 2px; }
.ss-sub { color:rgba(255,255,255,.75); font-size:12px; }
.close-btn { background:rgba(255,255,255,.2); border:none; color:white; width:32px; height:32px;
             border-radius:50%; font-size:16px; cursor:pointer; display:flex; align-items:center; justify-content:center; }
.ss-body { flex:1; overflow-y:auto; padding:16px; }
.section { background:white; border-radius:14px; padding:16px; margin-bottom:14px;
           box-shadow:0 2px 8px rgba(0,0,0,.08); }
.sec-title { font-size:14px; font-weight:800; color:#8B1A1A; margin-bottom:12px; }
.q-row { margin-bottom:12px; }
.q-label { font-size:13px; color:#333; font-weight:600; margin-bottom:6px; }
.req { color:#8B1A1A; }
.radio-group { display:flex; flex-direction:column; gap:4px; }
.radio-opt { display:flex; align-items:center; gap:8px; padding:6px 8px; border-radius:8px;
             cursor:pointer; font-size:13px; color:#555; transition:background .15s; }
.radio-opt:hover { background:#fdf0f0; }
.radio-opt input { accent-color:#8B1A1A; }
.stars-row { display:flex; gap:8px; margin-top:6px; }
.star-btn { font-size:28px; cursor:pointer; transition:transform .15s; filter:grayscale(1); }
.star-btn.lit { filter:none; transform:scale(1.15); }
.rating-label { font-size:12px; color:#888; margin-top:4px; }
textarea { width:100%; border:1.5px solid #e0e0e0; border-radius:10px; padding:10px;
           font-size:13px; font-family:inherit; resize:vertical; min-height:80px; outline:none; }
textarea:focus { border-color:#8B1A1A; }
.submit-btn { background:#ccc; color:white; border:none; border-radius:14px;
              padding:14px; width:100%; font-size:16px; font-weight:700; cursor:not-allowed;
              transition:background .2s, cursor .2s; }
.submit-btn.ready { background:#8B1A1A; cursor:pointer; }
.thankyou { display:none; flex-direction:column; align-items:center; justify-content:center;
            padding:40px 24px; gap:16px; min-height:600px; }
.thankyou.show { display:flex; }
"""
    body = """<div class="ss-screen">
  <div class="ss-header">
    <div class="ss-header-top">
      <div>
        <div class="ss-icon">📋</div>
        <div class="ss-title">Soal Selidik i.-GB</div>
        <div class="ss-sub">Maklum balas anda amat kami hargai</div>
      </div>
      <button class="close-btn" onclick="location.href='05_scanner.html'">✕</button>
    </div>
  </div>
  <div class="ss-body" id="ssBody">
    <!-- Section A -->
    <div class="section">
      <div class="sec-title">A. Maklumat Am</div>
      <div class="q-row">
        <div class="q-label">Status <span class="req">*</span></div>
        <div class="radio-group">
          <label class="radio-opt"><input type="radio" name="status" value="Pelajar" onchange="checkReady()"> Pelajar</label>
          <label class="radio-opt"><input type="radio" name="status" value="Guru" onchange="checkReady()"> Guru</label>
          <label class="radio-opt"><input type="radio" name="status" value="Pelancong" onchange="checkReady()"> Pelancong</label>
          <label class="radio-opt"><input type="radio" name="status" value="Lain-lain" onchange="checkReady()"> Lain-lain</label>
        </div>
      </div>
      <div class="q-row">
        <div class="q-label">Kumpulan Umur <span class="req">*</span></div>
        <div class="radio-group">
          <label class="radio-opt"><input type="radio" name="age" value="<12" onchange="checkReady()"> Bawah 12 tahun</label>
          <label class="radio-opt"><input type="radio" name="age" value="13-17" onchange="checkReady()"> 13 – 17 tahun</label>
          <label class="radio-opt"><input type="radio" name="age" value="18-25" onchange="checkReady()"> 18 – 25 tahun</label>
          <label class="radio-opt"><input type="radio" name="age" value=">25" onchange="checkReady()"> Lebih 25 tahun</label>
        </div>
      </div>
    </div>
    <!-- Section B -->
    <div class="section">
      <div class="sec-title">B. Pengalaman Aplikasi</div>
      <div class="q-row">
        <div class="q-label">Sejauh mana aplikasi ini mudah digunakan? <span class="req">*</span></div>
        <div class="radio-group">
          <label class="radio-opt"><input type="radio" name="ease" value="1" onchange="checkReady()"> Sangat Sukar</label>
          <label class="radio-opt"><input type="radio" name="ease" value="2" onchange="checkReady()"> Sukar</label>
          <label class="radio-opt"><input type="radio" name="ease" value="3" onchange="checkReady()"> Mudah</label>
          <label class="radio-opt"><input type="radio" name="ease" value="4" onchange="checkReady()"> Sangat Mudah</label>
        </div>
      </div>
      <div class="q-row">
        <div class="q-label">Bagaimana pengalaman AR dalam aplikasi ini? <span class="req">*</span></div>
        <div class="radio-group">
          <label class="radio-opt"><input type="radio" name="ar" value="1" onchange="checkReady()"> Sangat Lemah</label>
          <label class="radio-opt"><input type="radio" name="ar" value="2" onchange="checkReady()"> Lemah</label>
          <label class="radio-opt"><input type="radio" name="ar" value="3" onchange="checkReady()"> Baik</label>
          <label class="radio-opt"><input type="radio" name="ar" value="4" onchange="checkReady()"> Sangat Baik</label>
        </div>
      </div>
      <div class="q-row">
        <div class="q-label">Adakah soalan sesuai dengan topik? <span class="req">*</span></div>
        <div class="radio-group">
          <label class="radio-opt"><input type="radio" name="fit" value="1" onchange="checkReady()"> Tidak Sesuai Langsung</label>
          <label class="radio-opt"><input type="radio" name="fit" value="2" onchange="checkReady()"> Kurang Sesuai</label>
          <label class="radio-opt"><input type="radio" name="fit" value="3" onchange="checkReady()"> Sesuai</label>
          <label class="radio-opt"><input type="radio" name="fit" value="4" onchange="checkReady()"> Sangat Sesuai</label>
        </div>
      </div>
    </div>
    <!-- Section C -->
    <div class="section">
      <div class="sec-title">C. Penilaian Keseluruhan</div>
      <div class="q-row">
        <div class="q-label">Rating Keseluruhan <span class="req">*</span></div>
        <div class="stars-row" id="starsRow">
          <span class="star-btn" id="star1" onclick="setStar(1)">⭐</span>
          <span class="star-btn" id="star2" onclick="setStar(2)">⭐</span>
          <span class="star-btn" id="star3" onclick="setStar(3)">⭐</span>
          <span class="star-btn" id="star4" onclick="setStar(4)">⭐</span>
          <span class="star-btn" id="star5" onclick="setStar(5)">⭐</span>
        </div>
        <div class="rating-label" id="ratingLabel">Ketik untuk beri rating</div>
      </div>
      <div class="q-row">
        <div class="q-label">Komen / Cadangan</div>
        <textarea placeholder="Kongsi pendapat anda..."></textarea>
      </div>
    </div>
    <button class="submit-btn" id="submitBtn" onclick="submitForm()">Hantar Maklum Balas</button>
  </div>
  <div class="thankyou" id="thankyou">
    <div style="font-size:64px">🎉</div>
    <div style="font-size:22px;font-weight:800;color:#8B1A1A">Terima Kasih!</div>
    <div style="font-size:14px;color:#666;text-align:center;line-height:1.7">
      Maklum balas anda telah berjaya dihantar.<br>Kami menghargai masa dan pendapat anda.
    </div>
    <a href="05_scanner.html" style="background:#8B1A1A;color:white;border:none;border-radius:12px;
      padding:12px 32px;font-size:15px;font-weight:700;text-decoration:none;display:inline-block;margin-top:8px">
      Kembali ke Pengimbas
    </a>
  </div>
</div>
<script>
var starVal = 0;
var ratingTexts = ['','Sangat Lemah','Lemah','Sederhana','Baik','Cemerlang'];
function setStar(n) {
  starVal = n;
  for (var i=1;i<=5;i++) {
    document.getElementById('star'+i).classList.toggle('lit', i<=n);
  }
  document.getElementById('ratingLabel').textContent = ratingTexts[n];
  checkReady();
}
function checkReady() {
  var ok = document.querySelector('[name=status]:checked') &&
           document.querySelector('[name=age]:checked') &&
           document.querySelector('[name=ease]:checked') &&
           document.querySelector('[name=ar]:checked') &&
           document.querySelector('[name=fit]:checked') &&
           starVal > 0;
  var btn = document.getElementById('submitBtn');
  btn.classList.toggle('ready', !!ok);
  btn.style.cursor = ok ? 'pointer' : 'not-allowed';
}
function submitForm() {
  if (!document.getElementById('submitBtn').classList.contains('ready')) return;
  document.getElementById('ssBody').style.display='none';
  document.getElementById('thankyou').classList.add('show');
}
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 08 — Soal Selidik</strong><br>
  Full-page survey sheet with red header. Section A: Status + Age group radios. Section B: 3 experience questions (4 options each). Section C: 5-star clickable rating + comments textarea. Submit button is grey/disabled until all required (*) fields are filled — turns red when ready. Shows thank-you screen on submit.
</div>"""
    page = full_page("Soal Selidik", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("08_soalselidik.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 09_gameboard.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_gameboard():
    # Board squares data
    board = [
        (1,  "MULA",          "🚩", "start"),
        (2,  "Stadthuys",     "🏛️", "normal"),
        (3,  "Gereja Christ", "⛪", "normal"),
        (4,  "SOALAN",        "❓", "question"),
        (5,  "Jalan Jonker",  "🐍", "snake"),
        (6,  "Baba Nyonya",   "🎎", "normal"),
        (7,  "Sungai Melaka", "🚤", "normal"),
        (8,  "SOALAN",        "❓", "question"),
        (9,  "A-Famosa",      "🏰", "normal"),
        (10, "Bukit St.Paul", "⛰️", "normal"),
        (11, "TANGGA",        "🪜", "ladder"),
        (12, "SOALAN",        "❓", "question"),
        (13, "Taming Sari",   "🗼", "normal"),
        (14, "Melaka Eye",    "🎡", "normal"),
        (15, "Cheng Hoon",    "🛕", "normal"),
        (16, "SOALAN",        "❓", "question"),
        (17, "Masjid Kling",  "🕌", "normal"),
        (18, "ULAR!",         "🐍", "snake"),
        (19, "Masjid Selat",  "🕌", "normal"),
        (20, "Proklamasi",    "🏛️", "normal"),
        (21, "SOALAN",        "❓", "question"),
        (22, "Istana Lama",   "🐍", "snake"),
        (23, "Taman Bunga",   "🌺", "normal"),
        (24, "SOALAN",        "❓", "question"),
        (25, "TANGGA",        "🪜", "ladder"),
        (26, "Zoo Melaka",    "🦁", "normal"),
        (27, "SOALAN",        "❓", "question"),
        (28, "Pantai Klebang","🏖️", "normal"),
        (29, "Muzium Negeri", "🏛️", "normal"),
        (30, "TAMAT!",        "🏆", "finish"),
    ]
    snakes  = {5:1, 18:7, 22:14}
    ladders = {11:20, 25:29}

    color_map = {
        "start":    "#1B5E20",
        "finish":   "#B8860B",
        "question": "#1A237E",
        "snake":    "#7B1818",
        "ladder":   "#1B4A1B",
        "normal":   "#2a1500",
    }

    # Build 5x6 grid (rows of 6, row 0=top=squares 25-30, row 4=bottom=squares 1-6)
    # Boustrophedon: row4=1-6(L>R), row3=7-12(R>L), row2=13-18(L>R), row1=19-24(R>L), row0=25-30(L>R)
    rows_sq = [
        [25,26,27,28,29,30],
        [24,23,22,21,20,19],
        [13,14,15,16,17,18],
        [12,11,10,9,8,7],
        [1,2,3,4,5,6],
    ]
    board_dict = {sq[0]: sq for sq in board}

    grid_html = ""
    for row in rows_sq:
        grid_html += '<div class="gb-row">'
        for sq_id in row:
            sq = board_dict[sq_id]
            bg = color_map[sq[3]]
            emoji = sq[2]
            name = sq[1]
            grid_html += f'<div class="gb-sq" id="sq{sq_id}" style="background:{bg}" onclick="sqClick({sq_id})" title="{name}">'
            grid_html += f'<div class="sq-num">{sq_id}</div>'
            grid_html += f'<div class="sq-emoji">{emoji}</div>'
            grid_html += f'<div class="sq-name">{name[:6]}</div>'
            grid_html += '</div>'
        grid_html += '</div>'

    import json
    snakes_js  = json.dumps(snakes)
    ladders_js = json.dumps(ladders)
    questions_js = json.dumps([
        {"q": "Siapakah pengasas Kesultanan Melaka?", "opts": ["Parameswara","Sultan Mahmud","Hang Tuah","Tun Perak"], "correct":0},
        {"q": "Pada tahun berapa Portugis menakluki Melaka?", "opts": ["1511","1641","1824","1957"], "correct":0},
        {"q": "Apakah warna Stadthuys yang terkenal?", "opts": ["Merah","Putih","Kuning","Biru"], "correct":0},
        {"q": "Apakah kenderaan ikonik Melaka?", "opts": ["Beca","Kereta lembu","Bot nelayan","Monorail"], "correct":0},
    ])

    css = """
.gb-wrap { display:flex; flex-direction:column; min-height:780px; background:#1a0a00; }
.gb-appbar { background:#8B1A1A; padding:10px 14px; display:flex;
             justify-content:space-between; align-items:center; flex-shrink:0; }
.gb-title { color:white; font-weight:800; font-size:15px; }
.gb-score-top { color:#FFB300; font-weight:700; font-size:14px; }
.gb-msg { background:#2a1500; padding:8px 14px; flex-shrink:0; }
.gb-msg-text { color:#FFB300; font-size:12px; text-align:center; }
.gb-board { flex:1; padding:8px; display:flex; flex-direction:column; gap:3px; justify-content:center; }
.gb-row { display:flex; gap:3px; }
.gb-sq { flex:1; min-height:55px; border-radius:6px; display:flex; flex-direction:column;
         align-items:center; justify-content:center; cursor:pointer; transition:opacity .2s;
         border:1.5px solid rgba(255,255,255,.1); position:relative; padding:2px; }
.gb-sq:hover { opacity:.85; }
.gb-sq.player { border:2.5px solid #FFB300 !important; box-shadow:0 0 10px #FFB30066; }
.sq-num  { font-size:8px; color:rgba(255,255,255,.5); position:absolute; top:2px; left:4px; }
.sq-emoji { font-size:14px; line-height:1; }
.sq-name  { font-size:7px; color:rgba(255,255,255,.7); text-align:center; word-break:break-all; margin-top:1px; }
.gb-controls { background:#2a1500; padding:10px 14px; display:flex;
               justify-content:space-between; align-items:center; flex-shrink:0; }
.score-info { color:white; font-size:12px; }
.dice-btn { background:#8B1A1A; border:2px solid #B8860B; border-radius:50%;
            width:56px; height:56px; font-size:24px; cursor:pointer; color:white;
            display:flex; align-items:center; justify-content:center;
            box-shadow:0 4px 14px rgba(0,0,0,.4); transition:transform .15s; }
.dice-btn:active { transform:scale(.92); }
/* Popup */
.popup { position:fixed; inset:0; background:rgba(0,0,0,.75); display:none;
         align-items:center; justify-content:center; z-index:200; }
.popup.show { display:flex; }
.popup-box { background:white; border-radius:16px; padding:20px; max-width:280px; width:90%;
             box-shadow:0 20px 60px rgba(0,0,0,.5); }
.popup-title { font-weight:800; font-size:16px; color:#1a1a1a; margin-bottom:10px; }
.popup-body  { font-size:13px; color:#555; margin-bottom:16px; line-height:1.6; }
.popt-btn { width:100%; background:#f5f5f5; border:1.5px solid #e0e0e0;
            border-radius:8px; padding:9px; font-size:12px; text-align:left;
            cursor:pointer; margin-bottom:6px; font-family:inherit; }
.popt-btn:hover:not(:disabled) { border-color:#8B1A1A; }
.popt-btn.pcorrect { background:#E8F5E9; border-color:#4CAF50; font-weight:700; }
.popt-btn.pwrong   { background:#FFEBEE; border-color:#f44336; }
.popup-close { background:#8B1A1A; color:white; border:none; border-radius:10px;
               padding:9px 20px; font-size:13px; font-weight:700; cursor:pointer; float:right; }
"""
    body = f"""<div class="gb-wrap">
  <div class="gb-appbar">
    <a href="03_home.html" style="color:white;font-size:18px;text-decoration:none">←</a>
    <div class="gb-title">i.-GB — Ahmad</div>
    <div class="gb-score-top" id="scoreTop">🏆 0</div>
  </div>
  <div class="gb-msg"><div class="gb-msg-text" id="msgText">Selamat datang, Ahmad! Tekan dadu untuk mula.</div></div>
  <div class="gb-board">
{grid_html}
  </div>
  <div class="gb-controls">
    <div class="score-info">
      <div id="posInfo" style="color:#FFB300;font-weight:700">Petak: 1</div>
      <div id="rollInfo" style="color:rgba(255,255,255,.6)">Dadu: -</div>
      <div id="correctInfo" style="color:#4CAF50">Betul: 0</div>
    </div>
    <button class="dice-btn" id="diceBtn" onclick="rollDice()">🎲</button>
  </div>
</div>
<!-- Question popup -->
<div class="popup" id="qPopup">
  <div class="popup-box">
    <div class="popup-title" id="pTitle">Soalan</div>
    <div class="popup-body" id="pBody"></div>
    <div id="pOpts"></div>
    <div id="pFeedback" style="display:none;margin-bottom:10px;font-size:12px;font-weight:600"></div>
    <button class="popup-close" id="pCloseBtn" style="display:none" onclick="closeQPopup()">Teruskan</button>
  </div>
</div>
<!-- Game over popup -->
<div class="popup" id="goPopup">
  <div class="popup-box" style="text-align:center">
    <div style="font-size:40px;margin-bottom:10px">🏆</div>
    <div class="popup-title" style="font-size:20px;color:#B8860B">Permainan Tamat!</div>
    <div class="popup-body" id="goBody"></div>
    <a href="03_home.html"><button style="background:#8B1A1A;color:white;border:none;border-radius:10px;padding:10px 24px;font-size:14px;font-weight:700;cursor:pointer;margin-right:8px">Menu</button></a>
    <button onclick="restartGame()" style="background:#B8860B;color:white;border:none;border-radius:10px;padding:10px 24px;font-size:14px;font-weight:700;cursor:pointer">Main Semula</button>
  </div>
</div>
<script>
var snakes = {snakes_js};
var ladders = {ladders_js};
var qs = {questions_js};
var pos = 1;
var score = 0;
var correct = 0;
var pAnswered = false;
var pCorrectIdx = 0;

function markPlayer() {{
  document.querySelectorAll('.gb-sq').forEach(function(el){{ el.classList.remove('player'); }});
  var el = document.getElementById('sq'+pos);
  if (el) {{
    el.classList.add('player');
    el.innerHTML = el.innerHTML.replace(/<.*>.*<\/.*>/s, '');
    el.innerHTML = '<div class="sq-num">'+pos+'</div><div class="sq-emoji">🧑</div><div class="sq-name">Kamu</div>';
  }}
  document.getElementById('posInfo').textContent = 'Petak: '+pos;
  document.getElementById('scoreTop').textContent = '🏆 ' + score;
  document.getElementById('correctInfo').textContent = 'Betul: ' + correct;
}}

function rollDice() {{
  var btn = document.getElementById('diceBtn');
  btn.disabled = true;
  var roll = Math.floor(Math.random()*6)+1;
  document.getElementById('rollInfo').textContent = 'Dadu: ' + roll;
  btn.textContent = roll;
  var newPos = pos + roll;
  if (newPos > 30) newPos = 30 - (newPos - 30);
  pos = newPos;
  markPlayer();
  setTimeout(function() {{
    handleSquare();
    btn.disabled = false;
    btn.textContent = '🎲';
  }}, 600);
}}

function handleSquare() {{
  if (pos === 30) {{
    document.getElementById('goBody').innerHTML = '<b>Ahmad</b><br>Markah: <b>'+score+'</b><br>Betul: '+correct;
    document.getElementById('goPopup').classList.add('show');
    return;
  }}
  if (snakes[pos]) {{
    var to = snakes[pos];
    document.getElementById('msgText').textContent = '🐍 ULAR! Turun ke petak ' + to + '!';
    setTimeout(function(){{ pos = to; markPlayer(); }}, 500);
    return;
  }}
  if (ladders[pos]) {{
    var to2 = ladders[pos];
    document.getElementById('msgText').textContent = '🪜 TANGGA! Naik ke petak ' + to2 + '!';
    setTimeout(function(){{ pos = to2; markPlayer(); }}, 500);
    return;
  }}
  // Check if question square
  var qSqs = [4,8,12,16,21,24,27];
  if (qSqs.indexOf(pos) >= 0) {{
    showQuestion();
    return;
  }}
  document.getElementById('msgText').textContent = 'Petak ' + pos + ' — teruskan permainan!';
}}

function showQuestion() {{
  var q = qs[Math.floor(Math.random()*qs.length)];
  pAnswered = false;
  pCorrectIdx = q.correct;
  document.getElementById('pTitle').textContent = '❓ Soalan — Petak ' + pos;
  document.getElementById('pBody').textContent = q.q;
  var labels = ['A','B','C','D'];
  var html = '';
  q.opts.forEach(function(o,i) {{
    html += '<button class="popt-btn" id="popt'+i+'" onclick="answerQ('+i+','+q.correct+')">' + labels[i] + '. ' + o + '</button>';
  }});
  document.getElementById('pOpts').innerHTML = html;
  document.getElementById('pFeedback').style.display = 'none';
  document.getElementById('pCloseBtn').style.display = 'none';
  document.getElementById('qPopup').classList.add('show');
}}

function answerQ(idx, correctIdx) {{
  if (pAnswered) return;
  pAnswered = true;
  var btns = document.querySelectorAll('.popt-btn');
  btns.forEach(function(b){{ b.disabled = true; }});
  var fb = document.getElementById('pFeedback');
  if (idx === correctIdx) {{
    btns[idx].classList.add('pcorrect');
    score += 10; correct++;
    fb.textContent = '✅ Betul! +10 Markah!';
    fb.style.color = '#2E7D32';
    document.getElementById('msgText').textContent = '✅ Betul! +10 mata!';
  }} else {{
    btns[idx].classList.add('pwrong');
    btns[correctIdx].classList.add('pcorrect');
    fb.textContent = '❌ Salah.';
    fb.style.color = '#C62828';
    document.getElementById('msgText').textContent = '❌ Salah. Cuba lagi!';
  }}
  fb.style.display = 'block';
  document.getElementById('pCloseBtn').style.display = 'block';
  document.getElementById('scoreTop').textContent = '🏆 ' + score;
  document.getElementById('correctInfo').textContent = 'Betul: ' + correct;
}}

function closeQPopup() {{
  document.getElementById('qPopup').classList.remove('show');
}}

function sqClick(id) {{
  document.getElementById('msgText').textContent = 'Petak ' + id + ' — ' + (id===pos?'Kamu berada di sini!':'Bukan petak kamu');
}}

function restartGame() {{
  pos=1; score=0; correct=0;
  document.getElementById('goPopup').classList.remove('show');
  document.getElementById('rollInfo').textContent = 'Dadu: -';
  markPlayer();
  document.getElementById('msgText').textContent = 'Main semula! Tekan dadu untuk mula.';
}}

markPlayer();
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 09 — Game Board</strong><br>
  5×6 boustrophedon grid (30 squares). Color-coded: Start=dark green, Finish=gold, Question=dark blue, Snake=dark red, Ladder=dark green. Player token 🧑 highlighted with amber border. Tap 🎲 to roll dice (1-6), move player, handle snakes/ladders, show MCQ popup on question squares. "Permainan Tamat!" dialog at square 30.
</div>"""
    page = full_page("Game Board", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("09_gameboard.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 10_nota.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_nota():
    places = [
        ("A'Famosa",             "assets/imagesscan/afamosa.png",
         "Kubu Portugis yang dibina pada 1512. Salah satu tinggalan Eropah tertua di Asia Tenggara."),
        ("Cheng Hoon Teng Temple","assets/imagesscan/chenghoontengtemple.png",
         "Kuil Cina tertua di Malaysia, dibina pada 1646. Diiktiraf sebagai Warisan Budaya UNESCO."),
        ("Christ Church Melaka",  "assets/imagesscan/christchurchmelaka.png",
         "Gereja Belanda yang dibina pada 1753 dan merupakan salah satu gereja Protestant tertua di Malaysia."),
        ("Jonker Street",         "assets/imagesscan/junkerstreetmelaka.png",
         "Jalan ikonik di Pekan Cina Melaka, terkenal dengan barangan antik dan pelbagai hidangan tempatan."),
        ("Masjid Selat Melaka",   "assets/imagesscan/masjidselatmelaka.png",
         "Masjid unik yang dibina di atas air, kelihatan terapung di Selat Melaka ketika air pasang."),
        ("Menara Taming Sari",    "assets/imagesscan/menaratamingsari.png",
         "Menara giroskop berputar 360° ke ketinggian 80 meter untuk menikmati pemandangan Melaka."),
        ("Muzium Kapal Selam",    "assets/imagesscan/muziumkapalselammelaka.png",
         "Muzium berasaskan kapal selam sebenar KD Oumanoff yang boleh diterokai oleh pengunjung."),
        ("Stadthuys",             "assets/imagesscan/stadhuysmelaka.png",
         "Bangunan Belanda tertua di Asia Tenggara, dibina pada 1650. Kini berfungsi sebagai muzium."),
        ("St. Paul Hill Church",  "assets/imagesscan/stpaulhillchurch.png",
         "Gereja Portugis bersejarah di atas Bukit St. Paul, dibina pada 1521."),
        ("Beca Melaka",           "assets/imagesscan/trishaw.png",
         "Kenderaan ikonik Melaka yang dihiasi bunga warna-warni. Simbol pelancongan unik bandar ini."),
    ]
    notes = [
        ("📜","Sejarah Melaka",[
            "Melaka diasaskan oleh Parameswara pada tahun 1400.",
            "Portugis menakluki Melaka pada tahun 1511.",
            "Belanda mengambil alih Melaka pada tahun 1641.",
            "British mengambil alih Melaka melalui Perjanjian 1824.",
        ]),
        ("🏛️","Seni Bina",[
            "Stadthuys adalah bangunan Belanda tertua di Asia Tenggara.",
            "A'Famosa dibina oleh Alfonso de Albuquerque pada 1512.",
            "Christ Church Melaka dibina pada tahun 1753.",
            "Menara Taming Sari berputar 360° sambil naik ke atas.",
        ]),
        ("🎎","Budaya",[
            "Budaya Baba-Nyonya adalah perpaduan Melayu dan Cina.",
            "Beca adalah simbol pelancongan Melaka yang terkenal.",
            "Jonker Street terkenal dengan barangan antik dan makanan.",
            "Melaka merupakan tapak warisan dunia UNESCO sejak 2008.",
        ]),
        ("🗺️","Pelancongan",[
            "Masjid Selat Melaka dibina di atas air, kelihatan terapung.",
            "Muzium Kapal Selam KD Oumanoff adalah kapal selam sebenar.",
            "Bukit St. Paul mempunyai gereja dan makam bersejarah.",
            "Cheng Hoon Teng adalah kuil Cina tertua di Malaysia.",
        ]),
        ("🔢","Matematik",[
            "Luas = panjang × lebar (segi empat tepat).",
            "Luas = sisi × sisi (segi empat sama).",
            "Peratusan: bahagi dengan 100, kemudian darab.",
            "Punca kuasa dua: √169 = 13 kerana 13 × 13 = 169.",
        ]),
    ]

    # Build place cards HTML
    place_cards = ""
    for name, asset, desc in places:
        img = b64img(asset)
        place_cards += f"""<div style="background:white;border-radius:20px;overflow:hidden;
          box-shadow:0 6px 16px rgba(0,0,0,.28);margin-bottom:14px">
  <img src="{img}" style="width:100%;aspect-ratio:16/9;object-fit:cover" alt="{name}">
  <div style="padding:12px 14px">
    <div style="color:#8B1A1A;font-weight:800;font-size:14px;margin-bottom:4px">{name}</div>
    <div style="font-size:12px;color:#444;line-height:1.6">{desc}</div>
  </div>
</div>"""

    # Build nota cards
    nota_cards = ""
    for emoji, topic, pts in notes:
        pts_html = "".join(f"""<div style="display:flex;align-items:flex-start;gap:8px;margin-bottom:8px">
  <div style="width:7px;height:7px;background:#8B1A1A;border-radius:50%;flex-shrink:0;margin-top:5px"></div>
  <div style="font-size:12px;color:#444;line-height:1.5">{p}</div>
</div>""" for p in pts)
        nota_cards += f"""<div style="background:white;border-radius:20px;overflow:hidden;
          box-shadow:0 6px 16px rgba(0,0,0,.25);margin-bottom:14px">
  <div style="background:#8B1A1A;padding:12px 16px;display:flex;align-items:center;gap:10px">
    <span style="font-size:20px">{emoji}</span>
    <span style="color:white;font-weight:800;font-size:14px">{topic}</span>
  </div>
  <div style="padding:14px 16px">{pts_html}</div>
</div>"""

    css = """
.nota-screen { background:linear-gradient(180deg,#8B1A1A 0%,#3a0a0a 100%);
               min-height:780px; display:flex; flex-direction:column; }
.nota-topbar { display:flex; align-items:center; gap:12px; padding:12px 16px 8px; flex-shrink:0; }
.back-circle { width:36px; height:36px; background:rgba(255,255,255,.24); border-radius:50%;
               display:flex; align-items:center; justify-content:center;
               color:white; font-size:18px; text-decoration:none; }
.nota-title { color:white; font-size:19px; font-weight:800; }
.tab-bar { margin:0 16px 8px; background:rgba(255,255,255,.12); border-radius:14px;
           display:flex; overflow:hidden; flex-shrink:0; }
.tab-btn { flex:1; padding:10px 6px; border:none; background:transparent; cursor:pointer;
           font-size:13px; font-weight:700; color:rgba(255,255,255,.7); transition:all .2s;
           font-family:inherit; border-radius:12px; }
.tab-btn.active { background:white; color:#8B1A1A; }
.tab-content { flex:1; overflow-y:auto; padding:0 14px 20px; }
.tab-pane { display:none; }
.tab-pane.active { display:block; padding-top:4px; }
"""
    body = f"""<div class="nota-screen">
  <div class="nota-topbar">
    <a href="03_home.html" class="back-circle">←</a>
    <div class="nota-title">Nota</div>
  </div>
  <div class="tab-bar">
    <button class="tab-btn active" id="tab0" onclick="switchTab(0)">🏛️ Melaka</button>
    <button class="tab-btn" id="tab1" onclick="switchTab(1)">📚 Nota Permainan</button>
  </div>
  <div class="tab-content">
    <div class="tab-pane active" id="pane0">
{place_cards}
    </div>
    <div class="tab-pane" id="pane1">
{nota_cards}
    </div>
  </div>
</div>
<script>
function switchTab(idx) {{
  [0,1].forEach(function(i){{
    document.getElementById('tab'+i).classList.toggle('active',i===idx);
    document.getElementById('pane'+i).classList.toggle('active',i===idx);
  }});
}}
</script>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 10 — Nota</strong><br>
  Two-tab layout on red gradient background. Tab 1 (Melaka): 10 place cards with actual scan images (16:9) + red title + description. Tab 2 (Nota Permainan): 5 topic cards with red header and 4 bullet points each. Tabs switch instantly.
</div>"""
    page = full_page("Nota", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("10_nota.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# 11_about.html
# ═══════════════════════════════════════════════════════════════════════════════

def gen_about():
    logo = b64img("assets/images/logo_igb.png")
    team = [
        ("Pn. Jehan",        "Penyelia",            False),
        ("Pn. Faiizah",      "Penyelia",            False),
        ("En. Nik",          "Penyelia",            False),
        ("AF1 Productions",  "Pembangun Aplikasi",  True),
    ]
    members_html = ""
    for name, role, highlight in team:
        bg     = "rgba(139,26,26,.07)" if highlight else "#fafafa"
        border = "rgba(139,26,26,.3)"  if highlight else "#e0e0e0"
        avbg   = "#8B1A1A"             if highlight else "rgba(139,26,26,.12)"
        avcol  = "white"               if highlight else "#8B1A1A"
        members_html += f"""<div style="background:{bg};border:1px solid {border};border-radius:10px;
  padding:12px 14px;display:flex;align-items:center;gap:12px;margin-bottom:10px">
  <div style="width:36px;height:36px;border-radius:50%;background:{avbg};
    display:flex;align-items:center;justify-content:center;
    color:{avcol};font-weight:700;font-size:14px;flex-shrink:0">{name[0]}</div>
  <div>
    <div style="font-weight:700;font-size:14px;color:#1a1a1a">{name}</div>
    <div style="font-size:12px;color:#999">{role}</div>
  </div>
</div>"""

    css = """
.about-screen { background:#8B1A1A; min-height:780px; display:flex; flex-direction:column; padding:12px 16px 24px; }
.back-circle { width:36px; height:36px; background:rgba(255,255,255,.24); border-radius:50%;
               display:flex; align-items:center; justify-content:center;
               color:white; font-size:18px; text-decoration:none; align-self:flex-start; margin-bottom:14px; }
.content-card { background:white; border-radius:12px; padding:22px; flex:1;
                overflow-y:auto; }
"""
    body = f"""<div class="about-screen">
  <a href="03_home.html" class="back-circle">←</a>
  <div class="content-card">
    <div style="text-align:center;margin-bottom:18px">
      <img src="{logo}" width="130" height="130" alt="i.-GB" style="border-radius:65px">
    </div>
    <div style="font-size:19px;font-weight:800;color:#8B1A1A;margin-bottom:10px">Tentang i.-GB</div>
    <div style="font-size:13px;color:#444;line-height:1.7;text-align:justify;margin-bottom:24px">
      Terima kasih kerana bermain permainan i.‑GB! i.‑GB (Interactive Game Board) adalah sebuah
      permainan papan interaktif berasaskan teknologi Augmented Reality (AR) yang direka untuk dimainkan
      menggunakan papan fizikal. Pelajari sejarah dan budaya Melaka sambil menikmati pengalaman permainan
      yang menyeronokkan dan bermakna.
    </div>
    <div style="border-top:1.5px solid #eee;margin-bottom:18px"></div>
    <div style="font-size:17px;font-weight:800;color:#8B1A1A;margin-bottom:14px">Kumpulan Kami</div>
{members_html}
    <div style="text-align:center;margin-top:20px;font-size:12px;color:#bbb">
      i.-GB © 2026 • AF1 Productions
    </div>
  </div>
</div>"""
    annotation = """<div style="max-width:390px;margin:20px auto;color:#aaa;font-size:13px;line-height:1.7;padding:0 8px">
  <strong style="color:#B8860B">Skrin 11 — About</strong><br>
  Solid red background with back button. White content card: logo (130px), "Tentang i.-GB" title, description paragraph, divider, "Kumpulan Kami" section with 4 team members. AF1 Productions highlighted with red border. Footer copyright text.
</div>"""
    page = full_page("About", css, body)
    page = page.replace("</body>", annotation + "\n</body>")
    write_html("11_about.html", page)

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"\nGenerating files in: {OUT_DIR}\n")

    gen_index()
    gen_splash()
    gen_loading()
    gen_home()
    gen_tutorial()
    gen_scanner()
    gen_flipcard()
    gen_question()
    gen_soalselidik()
    gen_gameboard()
    gen_nota()
    gen_about()

    files = sorted(os.listdir(OUT_DIR))
    total_bytes = sum(os.path.getsize(os.path.join(OUT_DIR, f)) for f in files)
    print(f"\n{'─'*52}")
    print(f"Generated {len(files)} files  |  Total: {total_bytes/1024/1024:.1f} MB")
    print(f"Output directory: {OUT_DIR}")
    print(f"Open simulatedui/index.html in a browser to start.\n")

if __name__ == "__main__":
    main()
