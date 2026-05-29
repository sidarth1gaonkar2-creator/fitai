import 'package:shared_preferences/shared_preferences.dart';

/// In-app coin economy. Backed by SharedPreferences (two ints — `coins` and
/// `gems`) plus a small append-only log of recent transactions so the UI can
/// surface "+10 coins — workout" toasts.
///
/// Not backed by Isar: the data is two scalars and a fixed-size ring buffer
/// of strings — overkill to schema-evolve through Isar codegen.
class CurrencyService {
  CurrencyService(this._prefs);

  static const _kCoins = 'currency_coins';
  static const _kGems = 'currency_gems';
  static const _kLog = 'currency_log';
  static const _logCapacity = 50;

  // ── Award amounts ────────────────────────────────────────────────────
  static const int coinsPerWorkout = 10;
  static const int coinsPerStreak7 = 50;
  static const int coinsPerStreak30 = 200;
  static const int coinsPerChallengeDay = 5;
  static const int coinsPerChallengeComplete = 100;
  static const int coinsPerNutritionDay = 5;
  static const int coinsPerWeightLog = 3;
  static const int coinsPerPR = 25;

  final SharedPreferences _prefs;

  int get coins => _prefs.getInt(_kCoins) ?? 0;
  int get gems => _prefs.getInt(_kGems) ?? 0;

  Future<int> awardCoins({required int amount, required String reason}) async {
    if (amount <= 0) return coins;
    final next = coins + amount;
    await _prefs.setInt(_kCoins, next);
    await _log('earn', 'coins', amount, reason);
    return next;
  }

  /// Attempts to deduct [amount] coins. Returns true on success, false when
  /// the user can't afford it.
  Future<bool> spendCoins({required int amount, required String reason}) async {
    if (amount <= 0) return true;
    final current = coins;
    if (current < amount) return false;
    final next = current - amount;
    await _prefs.setInt(_kCoins, next);
    await _log('spend', 'coins', amount, reason);
    return true;
  }

  Future<int> awardGems({required int amount, required String reason}) async {
    if (amount <= 0) return gems;
    final next = gems + amount;
    await _prefs.setInt(_kGems, next);
    await _log('earn', 'gems', amount, reason);
    return next;
  }

  Future<bool> spendGems({required int amount, required String reason}) async {
    if (amount <= 0) return true;
    final current = gems;
    if (current < amount) return false;
    final next = current - amount;
    await _prefs.setInt(_kGems, next);
    await _log('spend', 'gems', amount, reason);
    return true;
  }

  /// Returns the most recent [_logCapacity] transactions, newest first. Each
  /// row is a `;`-delimited string `type;currency;amount;reason;iso_date`.
  List<CurrencyTransaction> recentTransactions() {
    final raw = _prefs.getStringList(_kLog) ?? const [];
    return raw.map(CurrencyTransaction._parse).whereType<CurrencyTransaction>().toList();
  }

  Future<void> _log(
    String type,
    String currency,
    int amount,
    String reason,
  ) async {
    final raw = _prefs.getStringList(_kLog) ?? <String>[];
    final row = '$type;$currency;$amount;$reason;${DateTime.now().toIso8601String()}';
    final next = [row, ...raw].take(_logCapacity).toList();
    await _prefs.setStringList(_kLog, next);
  }
}

class CurrencyTransaction {
  const CurrencyTransaction({
    required this.type,
    required this.currency,
    required this.amount,
    required this.reason,
    required this.date,
  });

  /// `'earn'` or `'spend'`.
  final String type;

  /// `'coins'` or `'gems'`.
  final String currency;
  final int amount;
  final String reason;
  final DateTime date;

  static CurrencyTransaction? _parse(String raw) {
    final parts = raw.split(';');
    if (parts.length != 5) return null;
    final amount = int.tryParse(parts[2]);
    final date = DateTime.tryParse(parts[4]);
    if (amount == null || date == null) return null;
    return CurrencyTransaction(
      type: parts[0],
      currency: parts[1],
      amount: amount,
      reason: parts[3],
      date: date,
    );
  }
}
