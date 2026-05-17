import 'package:flutter/material.dart';
import '../data/questions_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  String _selectedTopic = 'Sejarah Melaka';
  final _formKey = GlobalKey<FormState>();
  late final PageController _topicPageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _topicPageController = PageController(viewportFraction: 0.58);
    _topicPageController.addListener(() {
      setState(() => _currentPage = _topicPageController.page ?? 0);
    });
  }

  static const _red = Color(0xFF8B1A1A);
  static const _gold = Color(0xFFB8860B);

  @override
  void dispose() {
    _nameController.dispose();
    _topicPageController.dispose();
    super.dispose();
  }

  void _startGame() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_off, color: _red),
              SizedBox(width: 8),
              Text('Nama Diperlukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: const Text('Sila masukkan nama pemain sebelum memulakan permainan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/scanner', arguments: {
      'playerName': name,
      'topic': _selectedTopic,
    });
  }

  void _openARDemo() {
    Navigator.pushNamed(context, '/ar-demo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3a0a0a),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_red, Color(0xFF3a0a0a)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  const Text(
                    'i.-GB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const Text(
                    'Interactive Game Board',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nama Pemain',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Nama anda (pilihan)',
                            prefixIcon: const Icon(Icons.person, color: _red),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _red, width: 2),
                            ),
                          ),
                          validator: null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pilih Topik',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _topicPageController,
                            itemCount: allTopics.length,
                            onPageChanged: (i) => setState(() => _selectedTopic = allTopics[i]),
                            itemBuilder: (context, i) {
                              final distance = (_currentPage - i).abs();
                              final scale = (1 - distance * 0.18).clamp(0.82, 1.0);
                              return GestureDetector(
                                onTap: () => _topicPageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                                child: Transform.scale(
                                  scale: scale,
                                  child: _TopicCard(
                                    topic: allTopics[i],
                                    selected: _selectedTopic == allTopics[i],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Play button
                  ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.sports_esports, size: 24),
                    label: const Text(
                      'MAIN i.-GB',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AR Demo button
                  OutlinedButton.icon(
                    onPressed: _openARDemo,
                    icon: const Icon(Icons.view_in_ar, size: 22),
                    label: const Text(
                      'Demo AR Flutter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info chips
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: const [
                      _InfoChip(icon: '🏰', label: 'Melaka Theme'),
                      _InfoChip(icon: '📱', label: 'AR Camera'),
                      _InfoChip(icon: '❓', label: 'Quiz Questions'),
                      _InfoChip(icon: '🎲', label: 'Roll Dice'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String topic;
  final bool selected;

  const _TopicCard({required this.topic, required this.selected});

  static const _topicEmojis = {
    'Sejarah Melaka': '📜',
    'Seni Bina': '🏛️',
    'Budaya': '🎎',
    'Pelancongan': '🗺️',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8B1A1A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF8B1A1A) : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [BoxShadow(color: const Color(0xFF8B1A1A).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _topicEmojis[topic] ?? '📚',
            style: const TextStyle(fontSize: 44),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              topic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
