import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../data/questions_data.dart';
import 'question_screen.dart';

class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen>
    with TickerProviderStateMixin {
  late String _playerName;
  late String _topic;
  late PlayerResult _result;

  int _position = 1;
  int _lastRoll = 0;
  bool _rolling = false;
  bool _gameOver = false;
  String _message = '';

  final _random = Random();
  late AnimationController _diceController;
  late Animation<double> _diceAnim;
  late AnimationController _moveController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    _playerName = args['playerName']!;
    _topic = args['topic']!;
    _result = PlayerResult(playerName: _playerName, topic: _topic);
    _message = 'Selamat datang, $_playerName! Tekan dadu untuk mula.';
  }

  @override
  void initState() {
    super.initState();
    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _diceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _diceController, curve: Curves.elasticOut),
    );
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _diceController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  Future<void> _rollDice() async {
    if (_rolling || _gameOver) return;
    setState(() => _rolling = true);

    _diceController.reset();
    await _diceController.forward();

    final roll = _random.nextInt(6) + 1;
    int newPos = _position + roll;

    if (newPos > 30) newPos = 30 - (newPos - 30);

    setState(() {
      _lastRoll = roll;
      _position = newPos;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    await _handleSquare(newPos);

    setState(() => _rolling = false);
  }

  Future<void> _handleSquare(int pos) async {
    final square = gameBoard[pos - 1];

    if (square.isFinish) {
      _result.finalPosition = pos;
      setState(() {
        _gameOver = true;
        _message = '🏆 Tahniah $_playerName! Anda MENANG!';
      });
      _showEndDialog();
      return;
    }

    if (square.hasSnake) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _position = square.snakeTo!;
        _message = '🐍 ULAR! Turun ke petak ${square.snakeTo}!';
      });
    } else if (square.hasLadder) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _position = square.ladderTo!;
        _message = '🪜 TANGGA! Naik ke petak ${square.ladderTo}!';
      });
    } else if (square.hasQuestion) {
      await Future.delayed(const Duration(milliseconds: 400));
      await _showQuestion(square);
    } else {
      setState(() => _message = 'Petak ${square.id}: ${square.landmark}');
    }

    _result.finalPosition = _position;
  }

  Future<void> _showQuestion(GameSquare square) async {
    final topicToUse = square.topic ?? _topic;
    final questions = getQuestionsForTopic(topicToUse);
    if (questions.isEmpty) return;

    final q = questions[_random.nextInt(questions.length)];

    final correct = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          question: q,
          squareId: square.id,
          landmark: square.landmark,
        ),
      ),
    );

    if (correct == true) {
      _result.correctAnswers++;
      setState(() => _message = '✅ Betul! +10 mata — ${square.landmark}');
    } else {
      _result.wrongAnswers++;
      setState(
        () => _message = 'Salah - ${q.correctAnswer} ialah jawapan betul',
      );
    }
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Permainan Tamat!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _playerName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Topik: $_topic', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 24),
            _ResultRow(
              'Jawapan Betul',
              '${_result.correctAnswers}',
              Colors.green,
            ),
            _ResultRow('Jawapan Salah', '${_result.wrongAnswers}', Colors.red),
            _ResultRow('Mata', '${_result.score}', Colors.amber),
            _ResultRow(
              'Ketepatan',
              '${(_result.accuracy * 100).toStringAsFixed(0)}%',
              Colors.blue,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to home
            },
            child: const Text('Kembali ke Menu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _position = 1;
                _lastRoll = 0;
                _gameOver = false;
                _result = PlayerResult(playerName: _playerName, topic: _topic);
                _message = 'Main semula! Tekan dadu untuk mula.';
              });
            },
            child: const Text('Main Semula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0a00),
      appBar: AppBar(
        title: Text('i.-GB — $_playerName'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8B1A1A),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${_result.score} mata',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF2a1000),
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Game board
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildBoard(),
            ),
          ),

          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    // 5 rows x 6 cols layout (row 0 = squares 25-30, row 4 = squares 1-6)
    // Snake-and-ladder classic zigzag board
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 30,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.85,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (_, gridIndex) {
        final squareId = _gridIndexToSquareId(gridIndex);
        final square = gameBoard[squareId - 1];
        final isPlayer = _position == squareId;
        return _SquareTile(square: square, isPlayer: isPlayer);
      },
    );
  }

  int _gridIndexToSquareId(int gridIndex) {
    final row = gridIndex ~/ 6; // 0 = top row, 4 = bottom row
    final col = gridIndex % 6;
    final boardRow =
        4 - row; // row 4 = row 0 of board (1-6), row 0 = row 4 (25-30)
    final squareInRow = boardRow.isEven ? col : (5 - col);
    return boardRow * 6 + squareInRow + 1;
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFF2a1000),
      child: Row(
        children: [
          // Score summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Petak: $_position / 30',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '✅ ${_result.correctAnswers}  ❌ ${_result.wrongAnswers}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Topik: $_topic',
                  style: const TextStyle(color: Colors.amber, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Dice
          GestureDetector(
            onTap: _rolling || _gameOver ? null : _rollDice,
            child: AnimatedBuilder(
              animation: _diceAnim,
              builder: (_, __) {
                return Transform.scale(
                  scale: _rolling ? (0.9 + _diceAnim.value * 0.1) : 1.0,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _rolling || _gameOver
                          ? Colors.grey.shade700
                          : const Color(0xFF8B1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _lastRoll == 0 ? '🎲' : _diceEmoji(_lastRoll),
                            style: const TextStyle(fontSize: 26),
                          ),
                          Text(
                            _rolling
                                ? '...'
                                : (_lastRoll == 0 ? 'ROLL' : '$_lastRoll'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _diceEmoji(int n) {
    const emojis = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return n >= 1 && n <= 6 ? emojis[n - 1] : '🎲';
  }
}

class _SquareTile extends StatelessWidget {
  final GameSquare square;
  final bool isPlayer;

  const _SquareTile({required this.square, required this.isPlayer});

  Color _bgColor() {
    if (square.isStart) return const Color(0xFF1a6b1a);
    if (square.isFinish) return const Color(0xFFb8860b);
    if (square.hasQuestion) return const Color(0xFF1a2a5a);
    if (square.hasSnake) return const Color(0xFF5a1a1a);
    if (square.hasLadder) return const Color(0xFF1a5a2a);
    return const Color(0xFF2a1a00);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isPlayer ? Colors.amber.withOpacity(0.9) : _bgColor(),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPlayer ? Colors.amber : Colors.white12,
          width: isPlayer ? 2 : 0.5,
        ),
        boxShadow: isPlayer
            ? [BoxShadow(color: Colors.amber.withOpacity(0.6), blurRadius: 8)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isPlayer)
            const Text('🧑', style: TextStyle(fontSize: 16))
          else
            Text(square.emoji, style: const TextStyle(fontSize: 14)),
          Text(
            '${square.id}',
            style: TextStyle(
              color: isPlayer ? Colors.black : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
