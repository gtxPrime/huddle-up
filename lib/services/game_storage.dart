// lib/services/game_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class GameStorage {
  static SharedPreferences? _prefs;

  static const String _keyMaxUnlocked = 'huddle_max_unlocked';
  static const String _keyStarsPrefix = 'huddle_stars_lvl_';
  static const String _keyMovesPrefix = 'huddle_moves_lvl_';
  static const String _keyAdsRemoved = 'huddle_ads_removed_vip';
  static const String _keySound = 'huddle_setting_sound';
  static const String _keyMusic = 'huddle_setting_music';
  static const String _keyHaptics = 'huddle_setting_haptics';
  static const String _keyFishCoins = 'huddle_fish_coins';
  static const String _keyWinStreak = 'huddle_win_streak';
  static const String _keyBestStreak = 'huddle_best_streak';
  static const String _keyDailyLoginStreak = 'huddle_daily_streak';
  static const String _keyLastLoginDate = 'huddle_last_login_date';
  static const String _keyEquippedHat = 'huddle_equipped_hat';
  static const String _keyOwnedHats = 'huddle_owned_hats';
  static const String _keySeenPenguinsPrefix = 'huddle_seen_penguin_';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool hasSeenPenguin(String colorName) {
    // Blue penguin is the default starter, so consider it seen by default
    if (colorName == 'blue') return true;
    return _prefs?.getBool('$_keySeenPenguinsPrefix$colorName') ?? false;
  }

  static Future<void> markPenguinSeen(String colorName) async {
    await _prefs?.setBool('$_keySeenPenguinsPrefix$colorName', true);
  }

  // ── Levels & Progress ──────────────────────────────────────────────────────

  static int getMaxUnlockedLevel() {
    return _prefs?.getInt(_keyMaxUnlocked) ?? 1;
  }

  static Future<void> unlockUpTo(int level) async {
    final current = getMaxUnlockedLevel();
    if (level > current) {
      await _prefs?.setInt(_keyMaxUnlocked, level);
    }
  }

  static int getStarsForLevel(int level) {
    return _prefs?.getInt('$_keyStarsPrefix$level') ?? 0;
  }

  static int? getBestMovesForLevel(int level) {
    return _prefs?.getInt('$_keyMovesPrefix$level');
  }

  static Future<int> saveLevelCompletion({
    required int level,
    required int moves,
    required int par,
  }) async {
    int stars = 1;
    if (moves <= par) {
      stars = 3;
    } else if (moves <= par + 3) {
      stars = 2;
    }

    final oldStars = getStarsForLevel(level);
    if (stars > oldStars) {
      await _prefs?.setInt('$_keyStarsPrefix$level', stars);
    }

    final oldMoves = getBestMovesForLevel(level);
    if (oldMoves == null || moves < oldMoves) {
      await _prefs?.setInt('$_keyMovesPrefix$level', moves);
    }

    await unlockUpTo(level + 1);

    // Record win streak and initial fish coins
    await recordWinStreak();
    final earnedFish = stars * 50;
    await addFishCoins(earnedFish);

    return stars;
  }

  static int getTotalStars() {
    int total = 0;
    final maxLvl = getMaxUnlockedLevel();
    for (int i = 1; i <= maxLvl; i++) {
      total += getStarsForLevel(i);
    }
    return total;
  }

  // ── Fish Currency & Dopamine Economy ────────────────────────────────────────

  static int getFishCoins() {
    return _prefs?.getInt(_keyFishCoins) ?? 150; // Starter gift
  }

  static Future<int> addFishCoins(int amount) async {
    final cur = getFishCoins();
    final updated = cur + amount;
    await _prefs?.setInt(_keyFishCoins, updated);
    return updated;
  }

  // ── Win Streak System (Loss Aversion) ──────────────────────────────────────

  static int getWinStreak() {
    return _prefs?.getInt(_keyWinStreak) ?? 0;
  }

  static int getBestStreak() {
    return _prefs?.getInt(_keyBestStreak) ?? 0;
  }

  static Future<int> recordWinStreak() async {
    final streak = getWinStreak() + 1;
    await _prefs?.setInt(_keyWinStreak, streak);
    final best = getBestStreak();
    if (streak > best) {
      await _prefs?.setInt(_keyBestStreak, streak);
    }
    return streak;
  }

  static Future<void> resetWinStreak() async {
    await _prefs?.setInt(_keyWinStreak, 0);
  }

  // ── 7-Day Antarctic Daily Login Calendar ────────────────────────────────────

  static int getDailyLoginStreak() {
    return _prefs?.getInt(_keyDailyLoginStreak) ?? 1;
  }

  static String? getLastLoginDate() {
    return _prefs?.getString(_keyLastLoginDate);
  }

  static bool canClaimDailyGift() {
    final last = getLastLoginDate();
    if (last == null) return true;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    return last != todayStr;
  }

  static Future<int> claimDailyGift(int rewardFish) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    await _prefs?.setString(_keyLastLoginDate, todayStr);

    var streak = getDailyLoginStreak();
    // Cycle every 7 days
    final nextStreak = (streak >= 7) ? 1 : streak + 1;
    await _prefs?.setInt(_keyDailyLoginStreak, nextStreak);

    await addFishCoins(rewardFish);
    return streak;
  }

  // ── Penguin Hat Wardrobe (Coin Sink & Customization) ────────────────────────

  static String getEquippedHat() {
    return _prefs?.getString(_keyEquippedHat) ?? 'none';
  }

  static Future<void> setEquippedHat(String hatId) async {
    await _prefs?.setString(_keyEquippedHat, hatId);
  }

  static Set<String> getOwnedHats() {
    final list = _prefs?.getStringList(_keyOwnedHats) ?? ['none', 'scarf'];
    return list.toSet();
  }

  static Future<void> unlockHat(String hatId) async {
    final owned = getOwnedHats();
    owned.add(hatId);
    await _prefs?.setStringList(_keyOwnedHats, owned.toList());
  }

  // ── In-App Purchases (VIP / Remove Ads) ────────────────────────────────────

  static bool isAdsRemoved() {
    return _prefs?.getBool(_keyAdsRemoved) ?? false;
  }

  static Future<void> setAdsRemoved(bool value) async {
    await _prefs?.setBool(_keyAdsRemoved, value);
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  static bool isSoundEnabled() {
    return _prefs?.getBool(_keySound) ?? true;
  }

  static Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_keySound, value);
  }

  static bool isMusicEnabled() {
    return _prefs?.getBool(_keyMusic) ?? true;
  }

  static Future<void> setMusicEnabled(bool value) async {
    await _prefs?.setBool(_keyMusic, value);
  }

  static bool isHapticsEnabled() {
    return _prefs?.getBool(_keyHaptics) ?? true;
  }

  static Future<void> setHapticsEnabled(bool value) async {
    await _prefs?.setBool(_keyHaptics, value);
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  static Future<void> resetAllProgress() async {
    final adsRemoved = isAdsRemoved();
    await _prefs?.clear();
    // Preserve VIP purchase if user already bought it
    if (adsRemoved) {
      await setAdsRemoved(true);
    }
  }
}
