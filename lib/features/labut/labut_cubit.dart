// lib/features/labut/labut_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'labut_models.dart';
import 'labut_rng.dart';

class LabutState {
  final String iso;
  final List<LabutColor> target;
  final List<LabutColor> current;
  // Stable identity list for pins (same length as current)
  final List<int> ids;
  final int correct;
  final int moves;
  final int seconds;
  final int? selected; // swap iÃ§in
  final bool solved;
  final bool loading;
  final bool played; // bugÃ¼n zaten bitirdin mi?

  const LabutState({
    required this.iso,
    required this.target,
    required this.current,
    required this.ids,
    required this.correct,
    required this.moves,
    required this.seconds,
    required this.solved,
    required this.loading,
    required this.played,
    this.selected,
  });

  LabutState copy({
    List<LabutColor>? target,
    List<LabutColor>? current,
    List<int>? ids,
    int? correct,
    int? moves,
    int? seconds,
    int? selected,
    bool? solved,
    bool? loading,
    bool? played,
    bool dropSelection = false, // << yeni
  }) => LabutState(
    iso: iso,
    target: target ?? this.target,
    current: current ?? this.current,
    ids: ids ?? this.ids,
    correct: correct ?? this.correct,
    moves: moves ?? this.moves,
    seconds: seconds ?? this.seconds,
    selected: dropSelection ? null : (selected ?? this.selected), // << kritik
    solved: solved ?? this.solved,
    loading: loading ?? this.loading,
    played: played ?? this.played,
  );

  factory LabutState.initial() => LabutState(
    iso: todayIso(),
    target: const [],
    current: const [],
    ids: const [],
    correct: 0,
    moves: 0,
    seconds: 0,
    solved: false,
    loading: true,
    played: false,
  );
}

class LabutCubit extends Cubit<LabutState> {
  LabutCubit() : super(LabutState.initial());
  Timer? _timer;

  String get _kPlayed => "labut:${state.iso}:played";
  String get _kProgress => "labut:${state.iso}:progress";

  Future<void> load() async {
    emit(state.copy(loading: true));
    final sp = await SharedPreferences.getInstance();

    final played = sp.getBool(_kPlayed) ?? false;
    if (played) {
      emit(state.copy(played: true, loading: false));
      return;
    }

    final savedStr = sp.getString(_kProgress);
    if (savedStr != null) {
      final j = jsonDecode(savedStr) as Map<String, dynamic>;
      final ss = SaveState.fromJson(j)!;

      // Target deterministik â†’ yeniden Ã¼ret
      final daily = generateDaily(iso: state.iso);
      final correct = _countCorrect(ss.current, daily.target);

      _startTimer(initial: ss.seconds);
      emit(
        LabutState(
          iso: state.iso,
          target: daily.target,
          current: ss.current,
          ids: List<int>.generate(ss.current.length, (i) => i),
          correct: correct,
          moves: ss.moves,
          seconds: ss.seconds,
          solved: ss.solved,
          loading: false,
          played: false,
        ),
      );
      return;
    }

    // Yeni oyun Ã¼ret
    final daily = generateDaily(iso: state.iso);
    _startTimer(initial: 0);
    emit(
      LabutState(
        iso: state.iso,
        target: daily.target,
        current: daily.start,
        ids: List<int>.generate(daily.start.length, (i) => i),
        correct: _countCorrect(daily.start, daily.target),
        moves: 0,
        seconds: 0,
        solved: false,
        loading: false,
        played: false,
      ),
    );
  }

  void _startTimer({required int initial}) {
    _timer?.cancel();
    int sec = initial;
    int tick = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!state.solved) {
        sec += 1;
        tick += 1;
        emit(state.copy(seconds: sec));
        if (tick % 5 == 0) {
          await _persist();
        }
      }
    });
  }

  int _countCorrect(List<LabutColor> cur, List<LabutColor> tgt) {
    int ok = 0;
    for (int i = 0; i < cur.length; i++) {
      if (cur[i] == tgt[i]) ok++;
    }
    return ok;
  }

  void tap(int i) async {
    if (state.loading || state.solved || state.played)
      return; // Ã§Ã¶zÃ¼ldÃ¼yse tÄ±klama yok
    final sel = state.selected;

    if (sel == null) {
      emit(state.copy(selected: i)); // ilk seÃ§im
      return;
    }
    if (sel == i) {
      return; // aynÄ± elemana tÄ±klandÄ±ysa seÃ§ili kalsÄ±n (deÄŸiÅŸtirmiyoruz)
    }

    // ikinci seÃ§im â†’ SWAP
    final cur = List<LabutColor>.from(state.current);
    final ids = List<int>.from(state.ids);
    final tmp = cur[sel];
    cur[sel] = cur[i];
    cur[i] = tmp;
    // also swap ids to keep stable identities for animation
    final tmpId = ids[sel];
    ids[sel] = ids[i];
    ids[i] = tmpId;

    final correct = _countCorrect(cur, state.target);
    final solved = correct == cur.length;

    // lib/features/labut/labut_cubit.dart (tap iÃ§inde SWAP sonrasÄ± emit)

    emit(
      state.copy(
        current: cur,
        ids: ids,
        moves: state.moves + 1,
        correct: correct,
        solved: solved,
        dropSelection: true, // << seÃ§iliyi kesinlikle sÄ±fÄ±rla
      ),
    );

    await _persist();
    if (solved)
      await _finish(); // solved olsa bile tahta gÃ¶rÃ¼nmeye devam edecek
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    final s = SaveState(
      current: state.current,
      moves: state.moves,
      seconds: state.seconds,
      solved: state.solved,
    );
    await sp.setString(_kProgress, jsonEncode(s.toJson()));
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPlayed, true);
    // progress son hÃ¢li zaten kaydedildi
    emit(state.copy(played: true));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
