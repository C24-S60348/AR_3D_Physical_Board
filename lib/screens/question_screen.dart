import 'package:flutter/material.dart';
import '../data/questions_data.dart';

class QuestionScreen extends StatefulWidget {
  final Question question;
  final int squareId;
  final String landmark;

  const QuestionScreen({
    super.key,
    required this.question,
    required this.squareId,
    required this.landmark,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _answered = false;
  late AnimationController _flipController;
  late Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flip = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
  }

  bool get _isCorrect =>
      _selectedIndex == widget.question.correctIndex;

  void _continue() {
    Navigator.pop(context, _isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _flip,
            builder: (_, __) => Opacity(
              opacity: _flip.value,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY((1 - _flip.value) * 3.14),
                child: _buildCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  'Petak ${widget.squareId}',
                  style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text(
                widget.question.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Landmark
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Text(
                  widget.question.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.landmark,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.question.topic,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1A1A).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.question.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate(widget.question.options.length, (i) {
            return _OptionButton(
              label: widget.question.options[i],
              index: i,
              selected: _selectedIndex == i,
              answered: _answered,
              isCorrect: i == widget.question.correctIndex,
              onTap: () => _select(i),
            );
          }),

          const Spacer(),

          // Result + Continue
          if (_answered) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCorrect ? 'Betul! +10 mata' : 'Salah!',
                          style: TextStyle(
                            color: _isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (!_isCorrect)
                          Text(
                            'Jawapan: ${widget.question.options[widget.question.correctIndex]}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Teruskan ➜',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.index,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
  });

  static const _letters = ['A', 'B', 'C', 'D'];

  Color _bgColor() {
    if (!answered) return Colors.white.withOpacity(0.08);
    if (isCorrect) return Colors.green.withOpacity(0.25);
    if (selected && !isCorrect) return Colors.red.withOpacity(0.25);
    return Colors.white.withOpacity(0.05);
  }

  Color _borderColor() {
    if (!answered) return Colors.white24;
    if (isCorrect) return Colors.green;
    if (selected && !isCorrect) return Colors.red;
    return Colors.white12;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: answered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor()),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _borderColor().withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _letters[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (answered && isCorrect)
              const Icon(Icons.check, color: Colors.green, size: 18),
            if (answered && selected && !isCorrect)
              const Icon(Icons.close, color: Colors.red, size: 18),
          ],
        ),
      ),
    );
  }
}
