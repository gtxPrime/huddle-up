// lib/ui/widgets/daily_reward_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';

class DailyRewardDialog extends StatefulWidget {
  const DailyRewardDialog({super.key});

  static Future<void> showIfEligible(BuildContext context) async {
    if (GameStorage.canClaimDailyGift()) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DailyRewardDialog(),
      );
    }
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  final List<int> _rewards = [100, 150, 200, 300, 400, 600, 1000];
  bool _claimed = false;
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _currentDay = GameStorage.getDailyLoginStreak().clamp(1, 7);
  }

  int get _todayReward => _rewards[_currentDay - 1];

  Future<void> _claim({bool doubleReward = false}) async {
    final reward = doubleReward ? _todayReward * 2 : _todayReward;
    await GameStorage.claimDailyGift(reward);
    AudioService.playReward();
    if (GameStorage.isHapticsEnabled()) {
      HapticFeedback.heavyImpact();
    }
    setState(() => _claimed = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar Header
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_available_rounded,
                      color: Color(0xFF4DD0E1), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '7-Day Antarctic Rewards',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Log in every day to claim fish coins & mega chests!',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // 7 Days Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(7, (i) {
                final day = i + 1;
                final isToday = day == _currentDay;
                final isPast = day < _currentDay;
                final isMega = day == 7;

                return Container(
                  width: isMega ? 150 : 70,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isToday
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                        : (isPast
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.3)),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF00E5FF)
                          : (isPast ? Colors.white24 : Colors.white10),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isMega ? 'Day 7 MEGA' : 'Day $day',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isToday ? const Color(0xFF00E5FF) : Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isMega
                            ? Icons.card_giftcard_rounded
                            : (isPast
                                ? Icons.check_circle_rounded
                                : Icons.set_meal_rounded),
                        color: isPast
                            ? Colors.greenAccent
                            : (isMega
                                ? const Color(0xFFFFD54F)
                                : const Color(0xFF4DD0E1)),
                        size: isMega ? 22 : 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${_rewards[i]} Fish',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            if (_claimed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.greenAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Reward Claimed! See you tomorrow!',
                      style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // 2X Rewarded Ad Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF0D1B2A),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFFFF9C4), width: 1.5),
                    ),
                    elevation: 8,
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'CLAIM 2X GIFT (+${_todayReward * 2} FISH) [AD]',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  onPressed: () {
                    AdService.showRewardedMysteryGiftAd(
                      context,
                      onRewardEarned: () => _claim(doubleReward: true),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Normal Claim Button
              TextButton(
                onPressed: () => _claim(doubleReward: false),
                child: Text(
                  'Claim Normal (+$_todayReward Fish)',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
