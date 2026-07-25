import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ar3d_api.dart';

class NotaScreen extends StatefulWidget {
  const NotaScreen({super.key});

  @override
  State<NotaScreen> createState() => _NotaScreenState();
}

class _NotaScreenState extends State<NotaScreen>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFF8B1A1A);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_red, Color(0xFF3a0a0a)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nota',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: _red,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: '🏛️  Melaka'),
                    Tab(text: '📚  Nota Permainan'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [_MelakaTab(), _NotaPermainanTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 1: Melaka places ──────────────────────────────────────────────────────

class _MelakaTab extends StatefulWidget {
  const _MelakaTab();

  @override
  State<_MelakaTab> createState() => _MelakaTabState();
}

class _MelakaTabState extends State<_MelakaTab>
    with SingleTickerProviderStateMixin {
  static const _places = [
    _Place(
      name: "Kota A'Famosa",
      asset: 'assets/imagesscan/kotaafamosa-new.png',
      description:
          'Kubu Portugis yang dibina pada 1512 oleh Alfonso de Albuquerque. Salah satu tinggalan Eropah tertua di Asia Tenggara.',
    ),
    _Place(
      name: 'Masjid Cina Melaka',
      asset: 'assets/imagesscan/masjidcina-new.png',
      description:
          'Masjid unik bergaya seni bina Cina, menggabungkan elemen budaya Melayu dan Tionghoa dalam satu binaan yang indah.',
    ),
    _Place(
      name: 'Masjid Selat Melaka',
      asset: 'assets/imagesscan/masjidselatmelaka-new.png',
      description:
          'Masjid unik yang dibina di atas air, kelihatan terapung di Selat Melaka ketika air pasang.',
    ),
    _Place(
      name: 'Menara Taming Sari',
      asset: 'assets/imagesscan/menaratamingsari-new.png',
      description:
          'Menara giroskop berputar 360° yang membawa pelancong ke ketinggian 80 meter untuk menikmati pemandangan Melaka.',
    ),
    _Place(
      name: 'Muzium Samudera',
      asset: 'assets/imagesscan/muziumsamudera-new.png',
      description:
          'Muzium bertemakan kapal layar sejarah, memaparkan replika kapal dan kisah kegemilangan pelabuhan Melaka sebagai pusat perdagangan maritim.',
    ),
    _Place(
      name: 'Pantai Klebang',
      asset: 'assets/imagesscan/pantaiklebang-new.png',
      description:
          'Pantai terkenal di Melaka dengan pemandangan matahari terbenam yang indah serta gerai makanan tepi pantai yang popular.',
    ),
    _Place(
      name: 'Stadium Hang Jebat',
      asset: 'assets/imagesscan/stadiumhangjebat-new.png',
      description:
          'Stadium utama negeri Melaka, menjadi tuan rumah pelbagai acara sukan dan perlawanan bola sepak peringkat kebangsaan.',
    ),
  ];

  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        // Stagger: each card fades in and slides up slightly after the last.
        final start = (i * 0.09).clamp(0.0, 0.6);
        final animation = CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - animation.value)),
              child: child,
            ),
          ),
          child: _PlaceCard(place: _places[i], index: i),
        );
      },
    );
  }
}

class _Place {
  final String name;
  final String asset;
  final String description;
  const _Place({
    required this.name,
    required this.asset,
    required this.description,
  });
}

class _PlaceCard extends StatelessWidget {
  final _Place place;
  final int index;
  const _PlaceCard({required this.place, required this.index});

  static const _red = Color(0xFF8B1A1A);
  static const _gold = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with gradient scrim, numbered badge, and name overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  place.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Row(
                  children: [
                    const Icon(Icons.place, color: _gold, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Description with gold accent bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_red, _gold],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    place.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Nota Permainan ─────────────────────────────────────────────────────

class _NotaPermainanTab extends StatefulWidget {
  const _NotaPermainanTab();

  @override
  State<_NotaPermainanTab> createState() => _NotaPermainanTabState();
}

class _NotaPermainanTabState extends State<_NotaPermainanTab> {
  List<GameNote> _notes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await Ar3dApi.getNotes();
      if (!mounted) return;
      setState(() => _notes = notes);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Tidak dapat memuatkan nota dari pelayan.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _statusMessage({
    required IconData icon,
    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 24),
      children: [
        Icon(icon, color: Colors.white54, size: 56),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Cuba Semula'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    Widget child;
    if (_error != null) {
      child = _statusMessage(icon: Icons.cloud_off, message: _error!);
    } else if (_notes.isEmpty) {
      child = _statusMessage(
        icon: Icons.note_alt_outlined,
        message: 'Tiada nota buat masa ini. Tarik ke bawah untuk muat semula.',
      );
    } else {
      child = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) => _NotaCard(nota: _notes[i]),
      );
    }
    return RefreshIndicator(onRefresh: _loadNotes, child: child);
  }
}

class _NotaCard extends StatelessWidget {
  final GameNote nota;
  const _NotaCard({required this.nota});

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(nota.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nota.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...nota.points.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 5, right: 10),
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (nota.externalUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(nota.externalUrl!);
                        if (uri == null ||
                            !await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open the note link.'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
