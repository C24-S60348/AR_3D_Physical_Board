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
  final TextEditingController _answerController = TextEditingController();
  String? _submittedAnswer;
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
    _answerController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _submit() => _answer(_answerController.text);

  void _answer(String value) {
    final answer = value.trim();
    if (_answered || answer.isEmpty) return;
    setState(() {
      _submittedAnswer = answer;
      _answered = true;
    });
  }

  List<Widget> _buildChoices() {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final options = widget.question.options;

    return List.generate(options.length, (index) {
      final option = options[index];
      final isChosen = _submittedAnswer == option;
      final isAnswer = _answered && widget.question.matchesAnswer(option);

      var border = Colors.white24;
      var background = Colors.white.withOpacity(0.06);
      var badge = Colors.amber;
      if (isAnswer) {
        border = Colors.green;
        background = Colors.green.withOpacity(0.18);
        badge = Colors.green;
      } else if (isChosen) {
        border = Colors.red;
        background = Colors.red.withOpacity(0.18);
        badge = Colors.red;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _answered ? null : () => _answer(option),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: isChosen || isAnswer ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badge,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    index < letters.length ? letters[index] : '${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                if (isAnswer)
                  const Icon(Icons.check_circle, color: Colors.green, size: 22)
                else if (isChosen)
                  const Icon(Icons.cancel, color: Colors.red, size: 22),
              ],
            ),
          ),
        ),
      );
    });
  }

  bool get _isCorrect => widget.question.matchesAnswer(_submittedAnswer ?? '');

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  'Petak ${widget.squareId}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(widget.question.emoji, style: const TextStyle(fontSize: 28)),
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

          if (widget.question.isMultipleChoice)
            ..._buildChoices()
          else ...[
            TextField(
              controller: _answerController,
              enabled: !_answered,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Taip jawapan anda',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Contoh: 0.5 atau 1/2',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.amber,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text(
                    'Hantar Jawapan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 24),

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
                            'Jawapan: ${widget.question.correctAnswer}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
