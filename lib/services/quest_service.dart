import 'dart:convert';
import 'dart:math';

import '../models/quest.dart';
import 'storage_service.dart';

/// Three daily quests (easy, medium, hard) that reset at local midnight, plus
/// a weekly goal: claim [weeklyGoal] quests to earn a free Mystery Box.
class QuestService {
  static const int weeklyGoal = 10;

  /// Days since 1970 in local time.
  static int get _dayIndex {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  /// Weeks start on Monday (day 0 was a Thursday).
  static int get _weekIndex => (_dayIndex + 3) ~/ 7;

  static Map<String, dynamic> _state = {};

  /// Loads the saved state, resetting the daily and weekly parts if they're
  /// from an earlier day or week.
  static Map<String, dynamic> _load() {
    try {
      final raw = StorageService.getQuestState();
      _state = raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      _state = {};
    }

    if (_state['day'] != _dayIndex) {
      _state['day'] = _dayIndex;
      _state['progress'] = <String, dynamic>{};
      _state['claimed'] = <dynamic>[];
    }

    if (_state['week'] != _weekIndex) {
      _state['week'] = _weekIndex;
      _state['weekClaimed'] = 0;
      _state['weekBoxClaimed'] = false;
    }

    return _state;
  }

  static Future<void> _save() async {
    await StorageService.setQuestState(jsonEncode(_state));
  }

  /// Today's quests, one per tier. Everyone gets the same ones each day.
  static List<Quest> get todaysQuests {
    final random = Random(_dayIndex * 7919);

    return QuestTier.values.map((tier) {
      final pool = Quest.all.where((quest) => quest.tier == tier).toList();
      return pool[random.nextInt(pool.length)];
    }).toList();
  }

  static int progress(Quest quest) {
    final value = (_load()['progress'] as Map)[quest.id] as int? ?? 0;
    return min(value, quest.target);
  }

  static bool isComplete(Quest quest) => progress(quest) >= quest.target;

  static bool isClaimed(Quest quest) {
    return (_load()['claimed'] as List).contains(quest.id);
  }

  /// Quests (and the weekly box) ready to be collected.
  static int get claimableCount {
    final quests = todaysQuests
        .where((quest) => isComplete(quest) && !isClaimed(quest))
        .length;

    return quests + (weeklyBoxClaimable ? 1 : 0);
  }

  /// Updates progress after a run. Returns the quests this run finished.
  static Future<List<Quest>> recordRun(RunSummary run) async {
    final state = _load();
    final progressMap = state['progress'] as Map;
    final finished = <Quest>[];

    for (final quest in todaysQuests) {
      final before = progressMap[quest.id] as int? ?? 0;
      final amount = quest.amount(run);
      final after = quest.cumulative ? before + amount : max(before, amount);

      progressMap[quest.id] = after;

      if (before < quest.target && after >= quest.target) {
        finished.add(quest);
      }
    }

    await _save();
    return finished;
  }

  /// Pays the quest's reward. Returns 0 if it can't be claimed.
  static Future<int> claim(Quest quest) async {
    if (!isComplete(quest) || isClaimed(quest)) return 0;

    final state = _load();
    (state['claimed'] as List).add(quest.id);
    state['weekClaimed'] = (state['weekClaimed'] as int? ?? 0) + 1;

    await _save();
    await StorageService.addTicks(quest.reward);

    return quest.reward;
  }

  static int get weeklyProgress {
    return min(_load()['weekClaimed'] as int? ?? 0, weeklyGoal);
  }

  static bool get weeklyBoxClaimed => _load()['weekBoxClaimed'] == true;

  static bool get weeklyBoxClaimable =>
      weeklyProgress >= weeklyGoal && !weeklyBoxClaimed;

  /// Gives the weekly free Mystery Box. Returns false if it isn't ready.
  static Future<bool> claimWeeklyBox() async {
    if (!weeklyBoxClaimable) return false;

    _load()['weekBoxClaimed'] = true;
    await _save();
    await StorageService.setFreeMysteryBoxes(
      StorageService.getFreeMysteryBoxes() + 1,
    );

    return true;
  }

  static Duration get timeUntilReset {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }
}
