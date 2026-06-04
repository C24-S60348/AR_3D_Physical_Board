"""Generate a standalone HTML file simulating the i.-GB Home Screen UI."""
import base64, os

BASE = '/home/user/AR_3D_Physical_Board/assets'

def b64(path):
    full = os.path.join(BASE, path)
    with open(full, 'rb') as f:
        data = base64.b64encode(f.read()).decode()
    ext = path.split('.')[-1]
    mime = 'image/png' if ext == 'png' else 'image/jpeg'
    return f'data:{mime};base64,{data}'

logo    = b64('images/logo_igb.png')
sejarah = b64('images/topics/topic_sejarah_melaka.png')
budaya  = b64('images/topics/topic_budaya.png')
pelanc  = b64('images/topics/topic_pelancongan.png')
math    = b64('images/topics/topic_matematik.png')
seni    = b64('images/topics/topic_seni_bina.png')

html = f"""<!DOCTYPE html>
<html lang="ms">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>i.-GB — Simulated UI</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}

  body {{
    background: #1a1a1a;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-start;
    padding: 32px 16px;
    font-family: -apple-system, 'Segoe UI', Roboto, sans-serif;
  }}

  .page-title {{
    color: #aaa;
    font-size: 12px;
    letter-spacing: 2px;
    text-transform: uppercase;
    margin-bottom: 8px;
  }}
  .page-subtitle {{
    color: #666;
    font-size: 11px;
    margin-bottom: 24px;
    text-align: center;
  }}

  /* Phone frame */
  .phone {{
    width: 390px;
    min-height: 844px;
    background: #111;
    border-radius: 48px;
    border: 6px solid #333;
    box-shadow:
      0 0 0 1px #555,
      0 40px 80px rgba(0,0,0,0.9),
      inset 0 0 0 2px #222;
    overflow: hidden;
    position: relative;
  }}

  /* Status bar */
  .statusbar {{
    height: 44px;
    background: rgba(139,26,26,1);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 24px;
    position: relative;
  }}
  .statusbar-time {{
    color: white;
    font-size: 15px;
    font-weight: 600;
  }}
  .statusbar-icons {{
    display: flex;
    gap: 6px;
    align-items: center;
    color: white;
    font-size: 12px;
  }}
  .notch {{
    position: absolute;
    top: 0; left: 50%;
    transform: translateX(-50%);
    width: 120px; height: 28px;
    background: #111;
    border-radius: 0 0 18px 18px;
  }}

  /* Screen content */
  .screen {{
    background: linear-gradient(180deg, #8B1A1A 0%, #5a1010 40%, #3a0a0a 100%);
    min-height: 800px;
    padding: 16px 20px 32px;
    position: relative;
    overflow-y: auto;
  }}

  /* ? button top right */
  .about-btn {{
    position: absolute;
    top: 16px; right: 16px;
    width: 34px; height: 34px;
    border-radius: 50%;
    border: 1.5px solid rgba(255,255,255,0.38);
    background: rgba(255,255,255,0.15);
    color: white;
    font-size: 16px;
    font-weight: 800;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 10;
  }}

  /* Logo area */
  .logo-wrap {{
    display: flex;
    justify-content: center;
    align-items: center;
    height: 200px;
    margin-top: 16px;
    position: relative;
  }}
  .logo-img {{
    width: 180px;
    height: 180px;
    object-fit: contain;
    filter: drop-shadow(0 8px 24px rgba(0,0,0,0.5));
    cursor: pointer;
    transition: transform 0.15s ease;
  }}
  .logo-img:active {{ transform: scale(1.10); }}
  .star {{
    position: absolute;
    font-size: 16px;
    opacity: 0;
    pointer-events: none;
  }}
  .logo-wrap:hover .star {{ animation: burst 0.7s ease-out forwards; }}
  .star:nth-child(2) {{ animation-delay: 0s !important; top: 10px; left: 50%; }}
  .star:nth-child(3) {{ animation-delay: 0s !important; top: 20px; right: 20%; }}
  .star:nth-child(4) {{ animation-delay: 0s !important; right: 10px; top: 50%; }}
  .star:nth-child(5) {{ animation-delay: 0s !important; bottom: 20px; left: 20%; }}
  .star:nth-child(6) {{ animation-delay: 0s !important; top: 20px; left: 20%; }}
  @keyframes burst {{
    0%   {{ opacity: 1; transform: translate(0,0) scale(0.5); }}
    60%  {{ opacity: 1; }}
    100% {{ opacity: 0; transform: translate(var(--dx), var(--dy)) scale(1); }}
  }}
  .star:nth-child(2)  {{ --dx: 0px;    --dy: -70px; }}
  .star:nth-child(3)  {{ --dx: 50px;   --dy: -50px; }}
  .star:nth-child(4)  {{ --dx: 70px;   --dy: 20px; }}
  .star:nth-child(5)  {{ --dx: -55px;  --dy: 55px; }}
  .star:nth-child(6)  {{ --dx: -60px;  --dy: -40px; }}

  /* White card */
  .card {{
    background: white;
    border-radius: 20px;
    padding: 20px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.4);
    margin-bottom: 20px;
  }}

  .label {{
    font-size: 13px;
    font-weight: 700;
    color: #8B1A1A;
    margin-bottom: 8px;
    display: block;
  }}

  /* Name input */
  .input-wrap {{
    display: flex;
    align-items: center;
    border: 1.5px solid #ccc;
    border-radius: 12px;
    padding: 10px 14px;
    gap: 10px;
    margin-bottom: 18px;
    background: #fafafa;
  }}
  .input-icon {{ color: #8B1A1A; font-size: 18px; }}
  .input-field {{
    border: none;
    background: transparent;
    font-size: 14px;
    color: #333;
    outline: none;
    width: 100%;
    font-family: inherit;
  }}
  .input-field::placeholder {{ color: #aaa; }}

  /* Topic carousel */
  .carousel-wrap {{
    overflow: hidden;
    margin: 0 -4px;
  }}
  .carousel {{
    display: flex;
    gap: 10px;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    -webkit-overflow-scrolling: touch;
    padding: 8px 4px;
    scrollbar-width: none;
  }}
  .carousel::-webkit-scrollbar {{ display: none; }}

  .topic-card {{
    flex: 0 0 140px;
    height: 140px;
    border-radius: 14px;
    overflow: hidden;
    scroll-snap-align: center;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
    border: 2.5px solid transparent;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    position: relative;
  }}
  .topic-card.selected {{
    border-color: #8B1A1A;
    box-shadow: 0 4px 18px rgba(139,26,26,0.5);
    transform: scale(1.0);
  }}
  .topic-card:not(.selected) {{
    transform: scale(0.92);
    opacity: 0.85;
  }}
  .topic-card img {{
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }}

  /* Carousel dots */
  .dots {{
    display: flex;
    justify-content: center;
    gap: 6px;
    margin-top: 8px;
  }}
  .dot {{
    width: 7px; height: 7px;
    border-radius: 50%;
    background: #ddd;
    transition: background 0.2s, transform 0.2s;
    cursor: pointer;
  }}
  .dot.active {{
    background: #8B1A1A;
    transform: scale(1.3);
  }}

  /* Buttons */
  .btn-main {{
    width: 100%;
    padding: 16px;
    border: none;
    border-radius: 14px;
    background: linear-gradient(135deg, #B8860B, #DAA520);
    color: white;
    font-size: 17px;
    font-weight: 800;
    letter-spacing: 1px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    box-shadow: 0 4px 16px rgba(184,134,11,0.4);
    margin-bottom: 10px;
    transition: transform 0.1s, box-shadow 0.1s;
    font-family: inherit;
  }}
  .btn-main:active {{ transform: scale(0.97); }}

  .btn-outline {{
    width: 100%;
    padding: 13px;
    border: 1.5px solid rgba(255,255,255,0.5);
    border-radius: 14px;
    background: transparent;
    color: white;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    margin-bottom: 10px;
    transition: background 0.15s;
    font-family: inherit;
  }}
  .btn-outline:hover {{ background: rgba(255,255,255,0.08); }}

  .btn-row {{
    display: flex;
    gap: 10px;
    margin-bottom: 10px;
  }}
  .btn-row .btn-outline {{
    flex: 1;
    margin-bottom: 0;
  }}

  /* Alert dialog overlay */
  .dialog-overlay {{
    display: none;
    position: absolute;
    inset: 0;
    background: rgba(0,0,0,0.5);
    z-index: 100;
    align-items: center;
    justify-content: center;
    padding: 24px;
  }}
  .dialog-overlay.show {{ display: flex; }}
  .dialog {{
    background: white;
    border-radius: 16px;
    padding: 24px;
    width: 100%;
    max-width: 320px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.3);
  }}
  .dialog-title {{
    font-size: 16px;
    font-weight: 700;
    color: #1a1a1a;
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 10px;
  }}
  .dialog-title .ico {{ color: #8B1A1A; }}
  .dialog-body {{ font-size: 13px; color: #555; line-height: 1.5; margin-bottom: 18px; }}
  .dialog-ok {{
    background: none;
    border: none;
    color: #8B1A1A;
    font-weight: 700;
    font-size: 14px;
    cursor: pointer;
    float: right;
    font-family: inherit;
    padding: 4px 8px;
  }}

  /* Selected topic badge */
  .selected-badge {{
    font-size: 11px;
    color: #8B1A1A;
    font-weight: 600;
    text-align: center;
    margin-top: 4px;
  }}

  /* Annotation labels */
  .annotation-wrap {{
    width: 390px;
    margin-top: 24px;
  }}
  .annotation-title {{
    color: #888;
    font-size: 11px;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    margin-bottom: 12px;
    text-align: center;
  }}
  .annotation {{
    display: flex;
    align-items: flex-start;
    gap: 10px;
    margin-bottom: 8px;
  }}
  .ann-num {{
    min-width: 20px; height: 20px;
    background: #8B1A1A;
    color: white;
    border-radius: 50%;
    font-size: 10px;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: center;
  }}
  .ann-text {{ color: #bbb; font-size: 11px; line-height: 1.5; }}
  .ann-text b {{ color: #eee; }}
</style>
</head>
<body>

<p class="page-title">i.-GB — Simulated UI</p>
<p class="page-subtitle">Home Screen / Main Menu &nbsp;·&nbsp; Scroll inside phone &nbsp;·&nbsp; Tap buttons to interact</p>

<!-- PHONE FRAME -->
<div class="phone">

  <!-- Status bar -->
  <div class="statusbar">
    <div class="notch"></div>
    <span class="statusbar-time">9:41</span>
    <div class="statusbar-icons">
      <span>▲▲▲</span>
      <span>WiFi</span>
      <span>🔋</span>
    </div>
  </div>

  <!-- App screen -->
  <div class="screen" id="screen">

    <!-- ? button -->
    <div class="about-btn" title="About" onclick="alert('About Screen\\n\\nInfo projek & ahli kumpulan')">?</div>

    <!-- Logo -->
    <div class="logo-wrap" id="logoWrap" onclick="triggerStars()">
      <img class="logo-img" src="{logo}" alt="i.-GB Logo" id="logoImg">
      <span class="star" id="s1">⭐</span>
      <span class="star" id="s2">⭐</span>
      <span class="star" id="s3">⭐</span>
      <span class="star" id="s4">⭐</span>
      <span class="star" id="s5">⭐</span>
    </div>

    <!-- White card -->
    <div class="card">
      <span class="label">Nama Pemain</span>
      <div class="input-wrap">
        <span class="input-icon">👤</span>
        <input class="input-field" id="nameInput" type="text" placeholder="Nama">
      </div>

      <span class="label">Pilih Topik</span>
      <div class="carousel-wrap">
        <div class="carousel" id="carousel">
          <div class="topic-card selected" data-idx="0" onclick="selectTopic(0)">
            <img src="{sejarah}" alt="Sejarah Melaka">
          </div>
          <div class="topic-card" data-idx="1" onclick="selectTopic(1)">
            <img src="{seni}" alt="Seni Bina">
          </div>
          <div class="topic-card" data-idx="2" onclick="selectTopic(2)">
            <img src="{budaya}" alt="Budaya">
          </div>
          <div class="topic-card" data-idx="3" onclick="selectTopic(3)">
            <img src="{pelanc}" alt="Pelancongan">
          </div>
          <div class="topic-card" data-idx="4" onclick="selectTopic(4)">
            <img src="{math}" alt="Matematik">
          </div>
        </div>
      </div>
      <div class="dots">
        <div class="dot active" onclick="selectTopic(0)"></div>
        <div class="dot" onclick="selectTopic(1)"></div>
        <div class="dot" onclick="selectTopic(2)"></div>
        <div class="dot" onclick="selectTopic(3)"></div>
        <div class="dot" onclick="selectTopic(4)"></div>
      </div>
      <p class="selected-badge" id="selectedLabel">Sejarah Melaka</p>
    </div>

    <!-- Buttons -->
    <button class="btn-main" onclick="startGame()">
      🎮 &nbsp;MAIN i.-GB
    </button>

    <button class="btn-outline" onclick="showInfo('Demo AR Flutter', 'Buka AR scene demo tanpa game flow.\\n\\n(Memerlukan peranti fizikal dengan ARCore)')">
      📦 &nbsp;Demo AR Flutter
    </button>

    <div class="btn-row">
      <button class="btn-outline" onclick="showInfo('Tutorial', '4 langkah cara guna app:\\n1. Imbas Papan Permainan\\n2. Kad Tempat Muncul\\n3. Jawab Soalan\\n4. Kumpul Ganjaran')">
        📖 &nbsp;Tutorial
      </button>
      <button class="btn-outline" onclick="showInfo('Nota', 'Skrin rujukan & nota untuk pelajar.')">
        📝 &nbsp;Nota
      </button>
    </div>

    <!-- Dialog -->
    <div class="dialog-overlay" id="dialog">
      <div class="dialog">
        <div class="dialog-title">
          <span class="ico" id="dialogIcon">⚠️</span>
          <span id="dialogTitle">Nama Diperlukan</span>
        </div>
        <div class="dialog-body" id="dialogBody">Sila masukkan nama pemain sebelum memulakan permainan.</div>
        <button class="dialog-ok" onclick="closeDialog()">OK</button>
      </div>
    </div>

  </div><!-- /screen -->
</div><!-- /phone -->

<!-- Annotations -->
<div class="annotation-wrap">
  <p class="annotation-title">Screen Annotations</p>
  <div class="annotation"><div class="ann-num">1</div><div class="ann-text"><b>? Button (top-right)</b> — Navigates to About screen (info projek + ahli kumpulan)</div></div>
  <div class="annotation"><div class="ann-num">2</div><div class="ann-text"><b>Logo i.-GB</b> — Tap untuk trigger star burst ⭐ animation + sound effect</div></div>
  <div class="annotation"><div class="ann-num">3</div><div class="ann-text"><b>Nama Pemain</b> — TextField, validation: alert dialog jika kosong masa tekan MAIN</div></div>
  <div class="annotation"><div class="ann-num">4</div><div class="ann-text"><b>Pilih Topik</b> — PageView carousel (swipe / tap), 5 topik: Sejarah, Seni Bina, Budaya, Pelancongan, Matematik</div></div>
  <div class="annotation"><div class="ann-num">5</div><div class="ann-text"><b>MAIN i.-GB</b> (gold button) — Validate nama → Loading screen → Scanner/AR</div></div>
  <div class="annotation"><div class="ann-num">6</div><div class="ann-text"><b>Demo AR Flutter</b> — Terus ke AR demo scene (tanpa game flow)</div></div>
  <div class="annotation"><div class="ann-num">7</div><div class="ann-text"><b>Tutorial / Nota</b> — Side-by-side buttons, outline style</div></div>
</div>

<script>
  const topics = ['Sejarah Melaka','Seni Bina','Budaya','Pelancongan','Matematik'];
  let currentTopic = 0;

  function selectTopic(idx) {{
    currentTopic = idx;
    document.querySelectorAll('.topic-card').forEach((c,i) => {{
      c.classList.toggle('selected', i === idx);
    }});
    document.querySelectorAll('.dot').forEach((d,i) => {{
      d.classList.toggle('active', i === idx);
    }});
    document.getElementById('selectedLabel').textContent = topics[idx];
    const cards = document.querySelectorAll('.topic-card');
    cards[idx].scrollIntoView({{behavior:'smooth', block:'nearest', inline:'center'}});
  }}

  function startGame() {{
    const name = document.getElementById('nameInput').value.trim();
    if (!name) {{
      document.getElementById('dialogIcon').textContent = '👤';
      document.getElementById('dialogTitle').textContent = 'Nama Diperlukan';
      document.getElementById('dialogBody').textContent = 'Sila masukkan nama pemain sebelum memulakan permainan.';
      document.getElementById('dialog').classList.add('show');
      return;
    }}
    document.getElementById('dialogIcon').textContent = '🎮';
    document.getElementById('dialogTitle').textContent = 'Memulakan Permainan';
    document.getElementById('dialogBody').textContent =
      'Pemain: ' + name + '\\nTopik: ' + topics[currentTopic] + '\\n\\n→ Akan navigate ke Loading Screen\\n→ Kemudian Scanner / AR Camera';
    document.getElementById('dialog').classList.add('show');
  }}

  function showInfo(title, body) {{
    document.getElementById('dialogIcon').textContent = 'ℹ️';
    document.getElementById('dialogTitle').textContent = title;
    document.getElementById('dialogBody').textContent = body;
    document.getElementById('dialog').classList.add('show');
  }}

  function closeDialog() {{
    document.getElementById('dialog').classList.remove('show');
  }}

  function triggerStars() {{
    const stars = document.querySelectorAll('.star');
    const logo = document.getElementById('logoImg');
    logo.style.transform = 'scale(1.10)';
    setTimeout(() => logo.style.transform = '', 400);
    stars.forEach(s => {{
      s.style.animation = 'none';
      s.offsetHeight; // reflow
      s.style.animation = '';
      s.style.opacity = '1';
    }});
    setTimeout(() => stars.forEach(s => s.style.opacity = ''), 800);
  }}
</script>

</body>
</html>
"""

out = '/home/user/AR_3D_Physical_Board/home_screen_ui.html'
with open(out, 'w') as f:
    f.write(html)
print(f'Done: {out} ({os.path.getsize(out)/1024/1024:.1f} MB)')
