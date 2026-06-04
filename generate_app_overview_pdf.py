"""
Generate i.-GB App Overview PDF
Shows every screen, what was built, and the app flow.
"""
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether, Image as RLImage
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import Flowable
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Circle
from reportlab.graphics import renderPDF
import os, textwrap

# ── Colours ──────────────────────────────────────────────────────────────────
RED       = colors.HexColor('#8B1A1A')
RED_DARK  = colors.HexColor('#3a0a0a')
RED_LIGHT = colors.HexColor('#f5e6e6')
AMBER     = colors.HexColor('#FFC107')
GREEN     = colors.HexColor('#2e7d32')
GREY_BG   = colors.HexColor('#f5f5f5')
GREY_LINE = colors.HexColor('#dddddd')
WHITE     = colors.white
BLACK     = colors.HexColor('#1a1a1a')
BLUE      = colors.HexColor('#1565C0')
TEAL      = colors.HexColor('#00695C')

W, H = A4

# ── Styles ───────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

def style(name, **kw):
    s = ParagraphStyle(name, **kw)
    return s

TITLE_S   = style('Title2',    fontSize=26, textColor=WHITE,   alignment=TA_CENTER, fontName='Helvetica-Bold', spaceAfter=4)
SUBTITLE_S= style('Sub2',      fontSize=12, textColor=colors.HexColor('#ffcccc'), alignment=TA_CENTER, fontName='Helvetica')
H1        = style('H1',        fontSize=16, textColor=RED,     fontName='Helvetica-Bold', spaceBefore=14, spaceAfter=6)
H2        = style('H2',        fontSize=12, textColor=RED,     fontName='Helvetica-Bold', spaceBefore=8,  spaceAfter=4)
BODY      = style('Body2',     fontSize=9,  textColor=BLACK,   fontName='Helvetica',      leading=14)
BODY_BOLD = style('BodyBold',  fontSize=9,  textColor=BLACK,   fontName='Helvetica-Bold', leading=14)
SMALL     = style('Small',     fontSize=8,  textColor=colors.grey, fontName='Helvetica')
BADGE     = style('Badge',     fontSize=8,  textColor=WHITE,   fontName='Helvetica-Bold', alignment=TA_CENTER)
CAPTION   = style('Caption',   fontSize=8,  textColor=colors.HexColor('#555555'), alignment=TA_CENTER, fontName='Helvetica-Oblique')

BASE = '/home/user/AR_3D_Physical_Board/assets'

def asset(path):
    full = os.path.join(BASE, path)
    return full if os.path.exists(full) else None

# ── Helper: coloured badge ────────────────────────────────────────────────────
def badge(text, bg=GREEN, fg=WHITE, w=3.5*cm, h=0.55*cm):
    d = Drawing(w, h)
    d.add(Rect(0, 0, w, h, rx=4, ry=4, fillColor=bg, strokeColor=None))
    d.add(String(w/2, h/2-3, text, fontSize=7.5, fillColor=fg,
                 fontName='Helvetica-Bold', textAnchor='middle'))
    return d

# ── Helper: phone frame ───────────────────────────────────────────────────────
def phone_frame(content_drawing, frame_w=5.5*cm, frame_h=10*cm):
    """Wrap a Drawing inside a phone outline."""
    pad = 6
    total_w = frame_w + pad*2
    total_h = frame_h + pad*2 + 22  # top notch area
    d = Drawing(total_w, total_h)

    # Phone body
    d.add(Rect(0, 0, total_w, total_h, rx=12, ry=12,
                    fillColor=colors.HexColor('#222222'), strokeColor=None))
    # Screen area
    d.add(Rect(pad, pad, frame_w, frame_h+16, rx=8, ry=8,
                    fillColor=colors.HexColor('#111111'), strokeColor=None))
    # Notch
    notch_w, notch_h = 22, 6
    d.add(Rect((total_w-notch_w)/2, total_h-12, notch_w, notch_h, rx=3, ry=3,
                    fillColor=colors.HexColor('#333333'), strokeColor=None))

    # Embed content_drawing (scale if needed)
    # We just place the content drawing at (pad, pad)
    # Use renderPDF approach — actually just return both
    return d, pad, pad

# ── Helper: screen mockup (as Table cell) ─────────────────────────────────────
def screen_block(title, route, color_top, items, image_path=None, badge_text=None, badge_color=GREEN):
    """
    Returns a KeepTogether block for one screen:
    ┌─────────────────────────────────────────┐
    │  [colored header: title + route]         │
    │  [image if any | feature list]           │
    └─────────────────────────────────────────┘
    """
    elements = []

    # Header bar
    hdr_data = [[
        Paragraph(f'<b>{title}</b>', ParagraphStyle('sh', fontSize=11, textColor=WHITE,
                  fontName='Helvetica-Bold')),
        Paragraph(f'<i>{route}</i>', ParagraphStyle('sr', fontSize=8, textColor=colors.HexColor('#ffcccc'),
                  fontName='Helvetica-Oblique', alignment=TA_RIGHT)),
    ]]
    hdr_tbl = Table(hdr_data, colWidths=[10*cm, 5.5*cm])
    hdr_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), color_top),
        ('ROWBACKGROUNDS', (0,0), (-1,-1), [color_top]),
        ('TOPPADDING',    (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING',   (0,0), (-1,-1), 12),
        ('RIGHTPADDING',  (0,0), (-1,-1), 12),
        ('ROUNDEDCORNERS', [6, 6, 0, 0]),
    ]))
    elements.append(hdr_tbl)

    # Body
    left_col = []
    if image_path and os.path.exists(image_path):
        try:
            img = RLImage(image_path, width=4.5*cm, height=3*cm)
            img.hAlign = 'CENTER'
            left_col.append(img)
        except:
            left_col.append(Paragraph('<i>[ image ]</i>', SMALL))
    else:
        # Draw a placeholder phone screen
        ph = Drawing(4*cm, 3*cm)
        ph.add(Rect(0, 0, 4*cm, 3*cm, rx=6, ry=6, fillColor=colors.HexColor('#1a1a2e'), strokeColor=GREY_LINE, strokeWidth=1))
        ph.add(String(2*cm, 1.35*cm, '📱', fontSize=24, textAnchor='middle'))
        left_col.append(ph)

    if badge_text:
        left_col.append(Spacer(1, 4))
        b = badge(badge_text, bg=badge_color)
        b.hAlign = 'CENTER'
        left_col.append(b)

    right_col = []
    for item in items:
        if item.startswith('##'):
            right_col.append(Paragraph(item[2:].strip(),
                ParagraphStyle('fi', fontSize=8, textColor=colors.HexColor('#555555'),
                               fontName='Helvetica-Bold', spaceBefore=4)))
        elif item.startswith('✅') or item.startswith('🔧') or item.startswith('⚙️'):
            right_col.append(Paragraph(item,
                ParagraphStyle('fc', fontSize=8.5, textColor=BLACK,
                               fontName='Helvetica', leading=13, leftIndent=2)))
        else:
            right_col.append(Paragraph(f'• {item}',
                ParagraphStyle('fb', fontSize=8.5, textColor=BLACK,
                               fontName='Helvetica', leading=13, leftIndent=4)))
        right_col.append(Spacer(1, 1))

    body_data = [[left_col, right_col]]
    body_tbl = Table(body_data, colWidths=[5*cm, 10.5*cm])
    body_tbl.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,-1), GREY_BG),
        ('VALIGN',        (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING',    (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING',   (0,0), (0,-1), 10),
        ('RIGHTPADDING',  (0,0), (0,-1), 6),
        ('LEFTPADDING',   (1,0), (1,-1), 10),
        ('RIGHTPADDING',  (1,0), (1,-1), 10),
        ('LINEBELOW',     (0,0), (-1,-1), 1, GREY_LINE),
        ('ROUNDEDCORNERS', [0, 0, 6, 6]),
    ]))
    elements.append(body_tbl)
    elements.append(Spacer(1, 10))

    return KeepTogether(elements)

# ── Helper: flow step ─────────────────────────────────────────────────────────
def flow_row(steps):
    cells = []
    for i, (emoji, label) in enumerate(steps):
        box = Drawing(2.8*cm, 1.6*cm)
        box.add(Rect(0, 0, 2.8*cm, 1.6*cm, rx=6, ry=6,
                          fillColor=RED if i==0 else colors.HexColor('#f0f0f0'),
                          strokeColor=RED, strokeWidth=0.5))
        box.add(String(1.4*cm, 1.0*cm, emoji, fontSize=16, textAnchor='middle'))
        box.add(String(1.4*cm, 0.18*cm, label, fontSize=6.5,
                       fillColor=WHITE if i==0 else BLACK,
                       fontName='Helvetica-Bold', textAnchor='middle'))
        cells.append(box)
        if i < len(steps)-1:
            arr = Drawing(0.6*cm, 1.6*cm)
            arr.add(String(0.3*cm, 0.7*cm, '→', fontSize=12,
                           fillColor=colors.grey, textAnchor='middle'))
            cells.append(arr)

    widths = []
    for i in range(len(steps)):
        widths.append(2.8*cm)
        if i < len(steps)-1:
            widths.append(0.6*cm)

    t = Table([cells], colWidths=widths)
    t.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 0),
        ('BOTTOMPADDING', (0,0), (-1,-1), 0),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    return t

# ── Main PDF builder ──────────────────────────────────────────────────────────
def build_pdf(out_path):
    doc = SimpleDocTemplate(
        out_path,
        pagesize=A4,
        leftMargin=1.5*cm, rightMargin=1.5*cm,
        topMargin=1.5*cm, bottomMargin=1.5*cm,
        title='i.-GB App Overview',
        author='Claude Code',
    )

    story = []

    # ── COVER ─────────────────────────────────────────────────────────────────
    def cover_bg(canvas, doc):
        canvas.saveState()
        canvas.setFillColor(RED)
        canvas.rect(0, H*0.45, W, H*0.55+1, fill=1, stroke=0)
        canvas.setFillColor(RED_DARK)
        canvas.rect(0, 0, W, H*0.45, fill=1, stroke=0)
        # diagonal stripe
        canvas.setFillColor(colors.HexColor('#6B1414'))
        p = canvas.beginPath()
        p.moveTo(0, H*0.45)
        p.lineTo(W*0.6, H*0.45)
        p.lineTo(W*0.4, H*0.38)
        p.lineTo(0, H*0.38)
        canvas.drawPath(p, fill=1, stroke=0)
        canvas.restoreState()

    # Cover page content
    logo_path = asset('images/logo_igb.png')

    cover_elems = []
    cover_elems.append(Spacer(1, 2.5*cm))

    if logo_path:
        logo = RLImage(logo_path, width=3.5*cm, height=3.5*cm)
        logo.hAlign = 'CENTER'
        cover_elems.append(logo)
        cover_elems.append(Spacer(1, 0.4*cm))

    cover_elems.append(Paragraph('i.-GB', TITLE_S))
    cover_elems.append(Paragraph('Interactive Game Board with AR — Melaka Theme', SUBTITLE_S))
    cover_elems.append(Spacer(1, 0.3*cm))

    sep = Drawing(8*cm, 2)
    sep.add(Line(0, 1, 8*cm, 1, strokeColor=colors.HexColor('#ff8888'), strokeWidth=1.5))
    sep.hAlign = 'CENTER'
    cover_elems.append(sep)
    cover_elems.append(Spacer(1, 0.5*cm))

    cover_elems.append(Paragraph('App Screens Overview & Progress Report', SUBTITLE_S))
    cover_elems.append(Paragraph('Phase 1 & Phase 2 — June 2026', SUBTITLE_S))

    # Info box
    cover_elems.append(Spacer(1, 1.2*cm))
    info = [
        ['Platform', 'Android (Flutter 3.x, Dart 3.x)'],
        ['AR Engine', 'ARCore via ar_flutter_plugin'],
        ['Min SDK', 'Android API 24 (ARCore required)'],
        ['Backend (planned)', 'Flask API + SQLite'],
        ['Total Screens', '9 screens implemented'],
        ['Build', 'GitHub Actions → Release APK'],
    ]
    t = Table(info, colWidths=[4.5*cm, 10*cm])
    t.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (0,-1), colors.HexColor('#5c1010')),
        ('BACKGROUND',    (1,0), (1,-1), colors.HexColor('#7a1515')),
        ('FONTNAME',      (0,0), (0,-1), 'Helvetica-Bold'),
        ('FONTNAME',      (1,0), (1,-1), 'Helvetica'),
        ('FONTSIZE',      (0,0), (-1,-1), 9),
        ('TEXTCOLOR',     (0,0), (-1,-1), WHITE),
        ('TOPPADDING',    (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING',   (0,0), (-1,-1), 12),
        ('GRID',          (0,0), (-1,-1), 0.5, colors.HexColor('#aa3333')),
    ]))
    t.hAlign = 'CENTER'
    cover_elems.append(t)

    story += cover_elems
    story.append(Spacer(1, 0.8*cm))

    # ── SECTION: APP FLOW ─────────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', thickness=1, color=GREY_LINE))
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph('App Flow — User Journey', H1))

    story.append(flow_row([
        ('🚀','Splash'),('📦','Loading'),('🏠','Home'),('📖','Tutorial'),
    ]))
    story.append(Spacer(1, 6))
    story.append(flow_row([
        ('📷','Scanner'),('❓','Soalan AR'),('🎲','Game Board'),('📝','Soal Selidik'),
    ]))
    story.append(Spacer(1, 0.5*cm))

    summary_data = [
        [Paragraph('<b>9 Screens Built</b>', BODY_BOLD),
         Paragraph('<b>GitHub Actions</b>', BODY_BOLD),
         Paragraph('<b>AR Markers</b>', BODY_BOLD),
         Paragraph('<b>Soal Selidik</b>', BODY_BOLD)],
        [Paragraph('Fully implemented\nall routes', SMALL),
         Paragraph('Auto-build APK\non every push', SMALL),
         Paragraph('11 Melaka\nlandmarks', SMALL),
         Paragraph('3-section survey\nwith validation', SMALL)],
    ]
    st = Table(summary_data, colWidths=[3.8*cm]*4)
    st.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,0), RED),
        ('BACKGROUND',    (0,1), (-1,1), RED_LIGHT),
        ('TEXTCOLOR',     (0,0), (-1,0), WHITE),
        ('ALIGN',         (0,0), (-1,-1), 'CENTER'),
        ('TOPPADDING',    (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('GRID',          (0,0), (-1,-1), 0.5, GREY_LINE),
    ]))
    story.append(st)
    story.append(Spacer(1, 0.5*cm))

    # ── SECTION: SCREENS ──────────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', thickness=1, color=GREY_LINE))
    story.append(Paragraph('All Screens — Detailed', H1))

    # 1. Splash Screen
    story.append(Paragraph('1. Splash Screen', H2))
    story.append(screen_block(
        title='Splash Screen',
        route='Route: /  (entry point)',
        color_top=RED,
        image_path=asset('images/logo_igb.png'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Logo i.-GB muncul dengan animasi bounce (1.10x scale)',
            '✅ Star burst effect bila user tap logo (bintang terbang keluar)',
            '✅ Sound effect — blinkingstar.mp3 dimainkan',
            '✅ Auto-navigate ke Home screen selepas animasi selesai',
            '## Tech:',
            'AnimationController (bounce), AudioPlayer, Navigator.pushNamed("/home")',
        ]
    ))

    # 2. Loading Screen
    story.append(Paragraph('2. Loading Screen', H2))
    story.append(screen_block(
        title='Loading Screen',
        route='Route: /loading',
        color_top=RED,
        image_path=asset('images/logo_igb.png'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Animasi coin-flip pada logo (rotateY 360°)',
            '✅ Bintang kecil terbang keluar dari tepi logo',
            '✅ Bintang bermula dari tepi logo, saiz kecil, terbang ke luar sahaja',
            '✅ Logo topic di-flip semasa loading',
            '✅ 5 topic image cards diload (Sejarah, Budaya, Pelancongan, dll)',
            '## Tech:',
            'TweenAnimationBuilder, Transform.rotate, Stack overlay',
        ]
    ))

    # 3. Home Screen
    story.append(Paragraph('3. Home Screen', H2))
    # Use topic images as a collage
    story.append(screen_block(
        title='Home Screen / Main Menu',
        route='Route: /home',
        color_top=colors.HexColor('#1565C0'),
        image_path=asset('images/topics/topic_sejarah_melaka.png'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Input nama pemain (TextField + validation)',
            '✅ Alert dialog jika nama kosong bila mula',
            '✅ 5 Topic Cards dengan imej:',
            '   📚 Sejarah Melaka (topic_sejarah_melaka.png)',
            '   📚 Budaya (topic_budaya.png)',
            '   📚 Pelancongan (topic_pelancongan.png)',
            '   📚 Matematik (topic_matematik.png)',
            '   📚 Seni Bina (topic_seni_bina.png)',
            '✅ Buttons: Tutorial | Nota | About',
            '✅ Score badge ditunjuk (nama pemain)',
            '## Navigates to:',
            'Scanner screen dengan args: {playerName, topic}',
        ]
    ))

    # Topic cards sub-row
    topic_imgs = [
        ('topic_sejarah_melaka.png', 'Sejarah'),
        ('topic_budaya.png', 'Budaya'),
        ('topic_pelancongan.png', 'Pelancongan'),
        ('topic_matematik.png', 'Matematik'),
        ('topic_seni_bina.png', 'Seni Bina'),
    ]
    topic_cells = []
    for fname, label in topic_imgs:
        p = asset(f'images/topics/{fname}')
        cell_items = []
        if p and os.path.exists(p):
            try:
                img = RLImage(p, width=2.8*cm, height=2.2*cm)
                img.hAlign = 'CENTER'
                cell_items.append(img)
            except:
                pass
        cell_items.append(Paragraph(label, ParagraphStyle('tc', fontSize=7, alignment=TA_CENTER,
                                                           fontName='Helvetica-Bold', textColor=RED)))
        topic_cells.append(cell_items)

    tc_tbl = Table([topic_cells], colWidths=[3*cm]*5)
    tc_tbl.setStyle(TableStyle([
        ('ALIGN',         (0,0), (-1,-1), 'CENTER'),
        ('BACKGROUND',    (0,0), (-1,-1), GREY_BG),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('GRID',          (0,0), (-1,-1), 0.5, GREY_LINE),
    ]))
    story.append(tc_tbl)
    story.append(Paragraph('↑ 5 Topic Image Cards yang ada dalam Home Screen', CAPTION))
    story.append(Spacer(1, 10))

    # 4. Tutorial Screen
    story.append(Paragraph('4. Tutorial Screen', H2))
    story.append(screen_block(
        title='Tutorial Screen',
        route='Route: /tutorial',
        color_top=colors.HexColor('#00695C'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ 4-step tutorial dengan PageView (swipe kiri-kanan)',
            '✅ Step 1: "Imbas Papan Permainan" — animasi scan illustration',
            '✅ Step 2: "Kad Tempat Muncul" — animasi flip card',
            '✅ Step 3: "Jawab Soalan" — MCQ illustration',
            '✅ Step 4: "Kumpul Ganjaran" — trophy illustration',
            '✅ Progress dots di bawah',
            '✅ Button "Mula" di step terakhir → ke Scanner',
            '## Illustrations:',
            '_PhoneScanIllustration, _FlipCardIllustration (custom drawn)',
        ]
    ))

    # 5. Scanner Screen
    story.append(Paragraph('5. Scanner / AR Camera Screen', H2))
    story.append(screen_block(
        title='Scanner Screen (AR)',
        route='Route: /scanner',
        color_top=colors.HexColor('#212121'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ ARCore camera view (live camera feed)',
            '✅ Viewfinder overlay — 4 bracket corners (custom painter)',
            '✅ 11 AR image markers didaftarkan:',
            '   A\'Famosa, Cheng Hoon Teng, Christ Church,',
            '   Jonker Street, Masjid Selat, Menara Taming Sari,',
            '   Muzium Kapal Selam, Stadthuys, St. Paul\'s Hill,',
            '   Beca Melaka, Tempat Melaka',
            '✅ Soal Selidik button (top-right, pill putih)',
            '✅ Back button (top-left, bulat hitam)',
            '✅ Arahan scan di bahagian bawah',
            '✅ Emulator fallback screen (kamera tidak tersedia)',
            '## On marker detected:',
            '→ Trigger 3D Flip Card animation',
        ]
    ))

    # 6. Flip Card
    story.append(Paragraph('6. AR Flip Place Card (dalam Scanner)', H2))
    scan_imgs = ['afamosa.png', 'stadhuysmelaka.png', 'christchurchmelaka.png']
    scan_cells = []
    for fname in scan_imgs:
        p = asset(f'imagesscan/{fname}')
        cell_items = []
        if p and os.path.exists(p):
            try:
                img = RLImage(p, width=3.8*cm, height=2.8*cm)
                img.hAlign = 'CENTER'
                cell_items.append(img)
            except:
                pass
        label = fname.replace('.png','').replace('melaka','').title()
        cell_items.append(Paragraph(label, ParagraphStyle('sc', fontSize=7, alignment=TA_CENTER,
                                                           fontName='Helvetica-Bold')))
        scan_cells.append(cell_items)

    sc_tbl = Table([scan_cells], colWidths=[5*cm]*3)
    sc_tbl.setStyle(TableStyle([
        ('ALIGN',         (0,0), (-1,-1), 'CENTER'),
        ('BACKGROUND',    (0,0), (-1,-1), colors.HexColor('#1a1a2e')),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('GRID',          (0,0), (-1,-1), 0.5, colors.HexColor('#333333')),
    ]))
    story.append(sc_tbl)
    story.append(Paragraph('↑ Contoh 3 dari 11 gambar marker AR yang digunakan dalam Scanner', CAPTION))
    story.append(Spacer(1, 6))

    story.append(screen_block(
        title='3D Flip Place Card',
        route='(popup dalam Scanner)',
        color_top=colors.HexColor('#212121'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Muka depan: Gambar tempat + nama landmark',
            '✅ Auto-flip ke belakang selepas 1.8 saat',
            '✅ Muka belakang: Quiz icon + soalan prompt',
            '✅ Button "Teruskan ke Soalan" (amber)',
            '✅ Background blur (ImageFilter.blur sigma=18)',
            '✅ 3D flip animation (rotateY, perspective matrix)',
            '## Tap manual:',
            'User boleh tap kad untuk flip sendiri',
        ]
    ))

    # 7. Question Overlay
    story.append(Paragraph('7. Soalan AR Overlay (dalam Scanner)', H2))
    story.append(screen_block(
        title='Question Overlay (MCQ)',
        route='(overlay dalam Scanner)',
        color_top=RED,
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Header merah: emoji + nama landmark + topik badge',
            '✅ Soalan ditunjuk (teks penuh)',
            '✅ 4 pilihan jawapan (A, B, C, D) — animated buttons',
            '✅ Colour feedback: hijau=betul, merah=salah',
            '✅ Icon ✓ / ✗ selepas jawab',
            '✅ Mesej "✅ Betul! Markah ditambah!" atau "❌ Salah"',
            '✅ Button "Imbas Seterusnya" selepas jawab',
            '✅ Scale animation (elasticOut) masa muncul',
            '## Questions data:',
            'lib/data/questions_data.dart — soalan untuk setiap topik',
        ]
    ))

    # 8. Soal Selidik
    story.append(Paragraph('8. Soal Selidik Sheet (BARU)', H2))
    story.append(screen_block(
        title='Soal Selidik / Survey',
        route='(modal bottom sheet dari Scanner)',
        color_top=RED,
        badge_text='✅ BARU DIBUAT',
        badge_color=BLUE,
        items=[
            '✅ Button "Soal Selidik" (pill putih, top-right scanner)',
            '✅ Drag-up modal bottom sheet (DraggableScrollableSheet)',
            '## Bahagian A — Maklumat Responden:',
            '   Q1: Status (Pelajar/Guru/Pelancong/Lain-lain)',
            '   Q2: Peringkat Umur (7-12 / 13-17 / 18-25 / 26+)',
            '## Bahagian B — Pengalaman App:',
            '   Q3: Kemudahan guna app (Sangat Mudah → Sukar)',
            '   Q4: Pengalaman AR (Sangat Menarik → Tidak Menarik)',
            '   Q5: Kesesuaian soalan (Sangat Sesuai → Tidak Sesuai)',
            '## Bahagian C — Penilaian:',
            '   Q6: Star rating 1–5 bintang (interactive tap)',
            '   Q7: Komen terbuka (TextField, optional)',
            '✅ Validation: semua * wajib sebelum boleh hantar',
            '✅ Thank you screen selepas submit',
            '⚙️ NOTE: Soalan dummy — akak akan bagi soalan sebenar',
        ]
    ))

    # 9. Game Board
    story.append(Paragraph('9. Game Board Screen', H2))
    story.append(screen_block(
        title='Game Board (Snake & Ladder)',
        route='Route: /game',
        color_top=colors.HexColor('#1565C0'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Papan snake & ladder (zigzag klasik)',
            '✅ Player token bergerak ikut skor',
            '✅ Nama pemain dalam AppBar: "i.-GB — [Nama]"',
            '✅ Square tiles dengan nombor + emoji landmark',
            '✅ "Permainan Tamat!" popup dengan skor akhir',
            '✅ Button: Kembali ke Menu | Main Semula',
            '## Scoring:',
            'Skor dari Scanner → move token di board',
        ]
    ))

    # 10. Supporting screens
    story.append(Paragraph('10. Skrin Sokongan', H2))

    support_data = [
        [
            Paragraph('<b>Nota Screen</b>\n/nota', ParagraphStyle('ns', fontSize=9, fontName='Helvetica-Bold', textColor=RED)),
            Paragraph('<b>About Screen</b>\n/about', ParagraphStyle('as', fontSize=9, fontName='Helvetica-Bold', textColor=RED)),
            Paragraph('<b>AR Demo Screen</b>\n/ar-demo', ParagraphStyle('ad', fontSize=9, fontName='Helvetica-Bold', textColor=RED)),
        ],
        [
            Paragraph('✅ Rujukan / nota\nuntuk pelajar', BODY),
            Paragraph('✅ Info projek +\nnamiahli kumpulan', BODY),
            Paragraph('✅ Demo AR scene\ntanpa game flow', BODY),
        ],
    ]
    s_tbl = Table(support_data, colWidths=[5*cm, 5*cm, 5.5*cm])
    s_tbl.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,0), RED_LIGHT),
        ('BACKGROUND',    (0,1), (-1,1), GREY_BG),
        ('TOPPADDING',    (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING',   (0,0), (-1,-1), 10),
        ('GRID',          (0,0), (-1,-1), 0.5, GREY_LINE),
    ]))
    story.append(s_tbl)
    story.append(Spacer(1, 0.5*cm))

    # ── SECTION: CI/CD ────────────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', thickness=1, color=GREY_LINE))
    story.append(Paragraph('GitHub Actions — Auto Build APK', H1))
    story.append(screen_block(
        title='GitHub Actions Workflow',
        route='.github/workflows/build-apk.yml',
        color_top=colors.HexColor('#1a1a1a'),
        badge_text='✅ DONE',
        badge_color=GREEN,
        items=[
            '✅ Trigger: push to main / manual "Run workflow"',
            '✅ Flutter latest stable (auto — fixes Dart version)',
            '✅ Java 17 (temurin)',
            '✅ flutter pub get → flutter build apk --release',
            '✅ Upload artifact: app-release-apk (30 hari)',
            '## How to download APK:',
            'GitHub → Actions tab → Build Release APK',
            '→ Click run → Artifacts → Download app-release-apk',
            '## Fix applied:',
            'Removed flutter-version pin (was 3.32.1/Dart 3.8.1)',
            'Now uses latest stable → satisfies sdk: ^3.11.5',
        ]
    ))

    # ── SECTION: ASSETS ───────────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', thickness=1, color=GREY_LINE))
    story.append(Paragraph('AR Scan Images — 11 Melaka Landmarks', H1))

    all_scans = [
        ('afamosa.png', "A'Famosa"),
        ('chenghoontengtemple.png', 'Cheng Hoon Teng'),
        ('christchurchmelaka.png', 'Christ Church'),
        ('junkerstreetmelaka.png', 'Jonker Street'),
        ('masjidselatmelaka.png', 'Masjid Selat'),
        ('menaratamingsari.png', 'Menara Taming Sari'),
        ('muziumkapalselammelaka.png', 'Muzium Kapal Selam'),
        ('stadhuysmelaka.png', 'Stadthuys'),
        ('stpaulhillchurch.png', "St. Paul's Hill"),
        ('trishaw.png', 'Beca Melaka'),
        ('sampleimagetoscan.png', 'Sample Scan'),
    ]

    # Build rows of 4
    row_cells = []
    all_rows = []
    for i, (fname, label) in enumerate(all_scans):
        p = asset(f'imagesscan/{fname}')
        cell_items = []
        if p and os.path.exists(p):
            try:
                img = RLImage(p, width=3.2*cm, height=2.4*cm)
                img.hAlign = 'CENTER'
                cell_items.append(img)
            except:
                cell_items.append(Paragraph('[ img ]', SMALL))
        cell_items.append(Paragraph(label, ParagraphStyle('sl', fontSize=6.5, alignment=TA_CENTER,
                                                           fontName='Helvetica-Bold', textColor=BLACK)))
        row_cells.append(cell_items)
        if len(row_cells) == 4 or i == len(all_scans)-1:
            while len(row_cells) < 4:
                row_cells.append([Paragraph('', SMALL)])
            all_rows.append(row_cells)
            row_cells = []

    for row in all_rows:
        sc_t = Table([row], colWidths=[3.8*cm]*4)
        sc_t.setStyle(TableStyle([
            ('ALIGN',         (0,0), (-1,-1), 'CENTER'),
            ('BACKGROUND',    (0,0), (-1,-1), GREY_BG),
            ('TOPPADDING',    (0,0), (-1,-1), 6),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
            ('GRID',          (0,0), (-1,-1), 0.5, GREY_LINE),
        ]))
        story.append(sc_t)
        story.append(Spacer(1, 3))

    # ── SECTION: TODO / NEXT ─────────────────────────────────────────────────
    story.append(Spacer(1, 0.3*cm))
    story.append(HRFlowable(width='100%', thickness=1, color=GREY_LINE))
    story.append(Paragraph('Status Summary & What\'s Next', H1))

    status_data = [
        ['#', 'Feature / Screen', 'Status', 'Notes'],
        ['1',  'Splash Screen',              '✅ Done',   'Bounce + star burst + sound'],
        ['2',  'Loading Screen',             '✅ Done',   'Coin flip + flying stars'],
        ['3',  'Home Screen',                '✅ Done',   '5 topic cards + name input'],
        ['4',  'Tutorial Screen',            '✅ Done',   '4-step swipe tutorial'],
        ['5',  'Scanner / AR Camera',        '✅ Done',   'ARCore + 11 markers'],
        ['6',  'Flip Place Card',            '✅ Done',   '3D flip animation'],
        ['7',  'MCQ Question Overlay',       '✅ Done',   'Colour feedback + scoring'],
        ['8',  'Soal Selidik Survey',        '✅ Done',   'Dummy — akak akan update'],
        ['9',  'Game Board (Snake & Ladder)','✅ Done',   'Token movement + end screen'],
        ['10', 'Nota Screen',                '✅ Done',   'Reference notes'],
        ['11', 'About Screen',               '✅ Done',   'Team info'],
        ['12', 'AR Demo Screen',             '✅ Done',   'Demo tanpa game flow'],
        ['13', 'GitHub Actions (APK build)', '✅ Done',   'Latest stable Flutter'],
        ['14', 'Backend Flask API',          '🔜 Planned','Phase 3 — online leaderboard'],
        ['15', 'SQLite score history',       '🔜 Planned','Phase 3'],
        ['16', 'iOS support',                '🔜 Planned','ARKit needed'],
        ['17', 'Real Soal Selidik questions','⏳ Pending', 'Akak bagi soalan → update'],
    ]

    col_w = [0.8*cm, 6.5*cm, 2.5*cm, 5.7*cm]
    s_tbl2 = Table(status_data, colWidths=col_w, repeatRows=1)
    s_tbl2.setStyle(TableStyle([
        ('BACKGROUND',    (0,0), (-1,0), RED),
        ('TEXTCOLOR',     (0,0), (-1,0), WHITE),
        ('FONTNAME',      (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE',      (0,0), (-1,-1), 8.5),
        ('TOPPADDING',    (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('GRID',          (0,0), (-1,-1), 0.5, GREY_LINE),
        ('ROWBACKGROUNDS',(0,1), (-1,-1), [WHITE, GREY_BG]),
        ('TEXTCOLOR',     (2,14),(2,-1), colors.HexColor('#1565C0')),
        ('TEXTCOLOR',     (2,16),(2,16), colors.HexColor('#E65100')),
    ]))
    story.append(s_tbl2)
    story.append(Spacer(1, 0.5*cm))

    # ── FOOTER NOTE ───────────────────────────────────────────────────────────
    story.append(HRFlowable(width='100%', thickness=1, color=GREY_LINE))
    story.append(Spacer(1, 0.2*cm))
    story.append(Paragraph(
        'i.-GB — Interactive Game Board with AR (Melaka Theme) | Generated by Claude Code | June 2026',
        ParagraphStyle('footer', fontSize=7.5, textColor=colors.grey, alignment=TA_CENTER,
                       fontName='Helvetica-Oblique')
    ))

    doc.build(story)
    print(f'✅ PDF saved: {out_path}')

if __name__ == '__main__':
    out = '/home/user/AR_3D_Physical_Board/i-GB_App_Overview.pdf'
    build_pdf(out)
