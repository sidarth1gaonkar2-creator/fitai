import 'package:shared_preferences/shared_preferences.dart';

/// In-app coin economy. Backed by SharedPreferences (a single `coins` int)
/// plus a small append-only log of recent transactions so the UI can surface
/// "+10 coins — workout" toasts.
///
/// Coins are the app's single currency. Not backed by Isar: the data is a
/// scalar and a fixed-size ring buffer of strings — overkill to schema-evolve
/// through Isar codegen.
class CurrencyService {
  CurrencyService(this._prefs);

  static const _kCoins = 'currency_coins';
  static const _kLog = 'currency_log';
  static const _logCapacity = 50;

  // ── Award amounts ────────────────────────────────────────────────────
  // NOTE: the gym-day streak reward (base × multiplier) lives in
  // streak_rewards.dart, not here — it replaced the old per-workout coin and the
  // streak7/30 milestone bonuses (removed). coinsPerPR is still awarded on a new
  // PR. The remaining challenge/nutrition/weight constants are pre-existing dead
  // code (never awarded); their removal is part of the separate "CurrencyService
  // instance is never wired" cleanup, deliberately out of scope here.
  static const int coinsPerChallengeDay = 5;
  static const int coinsPerChallengeComplete = 100;
  static const int coinsPerNutritionDay = 5;
  static const int coinsPerWeightLog = 3;
  static const int coinsPerPR = 25;

  final SharedPreferences _prefs;

  int get coins => _prefs.getInt(_kCoins) ?? 0;

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

  /// Always `'coins'` — the app's single currency.
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
