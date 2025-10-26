// lib/features/labut/labut_models.dart

// Renk tipini esnek yapıyoruz: "Y","G","R","P","K","B","O","C","M"... (ne istersen)
typedef LabutColor =
    String; // örn: "P" (pembe), "K" (siyah/black), "B" (mavi/blue) ...

class GameSpec {
  final int boardLen;
  final Map<String, int> counts; // {"P":7, "K":2} gibi
  const GameSpec({required this.boardLen, required this.counts});
}

class DailyGame {
  final String iso; // YYYY-MM-DD
  final GameSpec spec;
  final List<LabutColor> target; // hedef dizilim (renk kodları)
  final List<LabutColor> start; // başlangıç dizilim
  const DailyGame({
    required this.iso,
    required this.spec,
    required this.target,
    required this.start,
  });
}

class SaveState {
  final List<LabutColor> current;
  final int moves;
  final int seconds;
  final bool solved;
  const SaveState({
    required this.current,
    required this.moves,
    required this.seconds,
    required this.solved,
  });

  Map<String, dynamic> toJson() => {
    "current": current, // zaten String listesi
    "moves": moves,
    "seconds": seconds,
    "solved": solved,
  };

  static SaveState? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final cur = (j["current"] as List).map((e) => e as String).toList();
    return SaveState(
      current: cur,
      moves: j["moves"] as int,
      seconds: j["seconds"] as int,
      solved: j["solved"] as bool,
    );
  }
}
