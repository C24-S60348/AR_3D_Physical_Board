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

class _MelakaTab extends StatelessWidget {
  const _MelakaTab();

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

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _PlaceCard(place: _places[i]),
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
  const _PlaceCard({required this.place});

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Place image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              place.asset,
              fit: BoxFit.fitHeight,
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
          // Name + description
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  place.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
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
  static const _fallbackNotes = [
    GameNote(
      emoji: '📜',
      title: 'Sejarah Melaka',
      points: [
        'Melaka diasaskan oleh Parameswara pada tahun 1400.',
        'Portugis menakluki Melaka pada tahun 1511.',
        'Belanda mengambil alih Melaka pada tahun 1641.',
        'British mengambil alih Melaka pada tahun 1824 melalui Perjanjian Inggeris-Belanda.',
      ],
    ),
    GameNote(
      emoji: '🏛️',
      title: 'Seni Bina',
      points: [
        'Stadthuys adalah bangunan Belanda tertua di Asia Tenggara.',
        "A'Famosa dibina oleh Alfonso de Albuquerque pada tahun 1512.",
        'Christ Church Melaka dibina pada tahun 1753.',
        'Menara Taming Sari berputar 360° sambil naik ke atas.',
      ],
    ),
    GameNote(
      emoji: '🎎',
      title: 'Budaya',
      points: [
        'Budaya Baba-Nyonya adalah perpaduan Melayu dan Cina.',
        'Beca adalah simbol pelancongan Melaka yang terkenal.',
        'Jonker Street terkenal dengan barangan antik dan makanan.',
        'Melaka merupakan tapak warisan dunia UNESCO sejak 2008.',
      ],
    ),
    GameNote(
      emoji: '🗺️',
      title: 'Pelancongan',
      points: [
        'Masjid Selat Melaka dibina di atas air, kelihatan terapung.',
        'Muzium Kapal Selam KD Oumanoff adalah kapal selam sebenar.',
        'Bukit St. Paul mempunyai gereja dan makam bersejarah.',
        'Cheng Hoon Teng adalah kuil Cina tertua di Malaysia.',
      ],
    ),
    GameNote(
      emoji: '🔢',
      title: 'Matematik',
      points: [
        'Luas = panjang × lebar (segi empat tepat).',
        'Luas = sisi × sisi (segi empat sama).',
        'Peratusan: bahagi dengan 100, kemudian darab.',
        'Punca kuasa dua: √169 = 13 kerana 13 × 13 = 169.',
      ],
      imageAsset: 'assets/images/secondary_school_note.jpg',
    ),
  ];

  List<GameNote> _notes = _fallbackNotes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (!Ar3dApi.isConfigured) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await Ar3dApi.getNotes();
      if (!mounted) return;
      setState(() {
        if (notes.isNotEmpty) _notes = notes;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Showing saved app notes. Pull down to try the server again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: _notes.length + (_loading || _error != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          if (i == 0 && (_loading || _error != null)) {
            if (_loading) return const LinearProgressIndicator();
            return Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            );
          }
          final noteIndex = i - (_loading || _error != null ? 1 : 0);
          return _NotaCard(nota: _notes[noteIndex]);
        },
      ),
    );
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
                Text(
                  nota.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (nota.imageUrl != null)
            Image.network(
              nota.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          else if (nota.imageAsset != null)
            Image.asset(nota.imageAsset!, fit: BoxFit.cover),
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
