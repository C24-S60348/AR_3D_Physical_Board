import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1A1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/images/logo_igb.png',
                            width: 130,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // About title
                        const Text(
                          'Tentang i.-GB',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Terima kasih kerana bermain permainan i.‑GB! '
                          'i.‑GB (Interactive Game Board) adalah sebuah permainan papan interaktif '
                          'berasaskan teknologi Augmented Reality (AR) yang direka untuk dimainkan '
                          'menggunakan papan fizikal. Pelajari sejarah dan budaya Melaka sambil '
                          'menikmati pengalaman permainan yang menyeronokkan dan bermakna.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Divider
                        const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
                        const SizedBox(height: 20),

                        // Team title
                        const Text(
                          'Kumpulan Kami',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _red,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _TeamMember(name: 'Pn. Jehan', role: 'Penyelia'),
                        _TeamMember(name: 'Pn. Faiizah', role: 'Penyelia'),
                        _TeamMember(
                          name: 'AF1 Productions',
                          role: 'Pembangun Aplikasi',
                          onTap: () => Navigator.pushNamed(context, '/ar-demo'),
                        ),

                        const SizedBox(height: 28),
                        Center(
                          child: Text(
                            'i.-GB © 2026 • AF1 Productions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final bool highlight;
  final VoidCallback? onTap;

  const _TeamMember({required this.name, required this.role, this.highlight = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF8B1A1A).withOpacity(0.07) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFF8B1A1A).withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: highlight
                ? const Color(0xFF8B1A1A)
                : const Color(0xFF8B1A1A).withOpacity(0.12),
            child: Text(
              name[0],
              style: TextStyle(
                color: highlight ? Colors.white : const Color(0xFF8B1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
              ),
              Text(
                role,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    ),   // Container
    );   // GestureDetector
  }
}
