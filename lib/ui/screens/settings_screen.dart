// lib/ui/screens/settings_screen.dart
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import '../../services/ad_service.dart';
import '../../services/audio_service.dart';
import 'purchase_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _sound;
  late bool _music;
  late bool _haptics;
  late bool _isAdsRemoved;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _sound = GameStorage.isSoundEnabled();
      _music = GameStorage.isMusicEnabled();
      _haptics = GameStorage.isHapticsEnabled();
      _isAdsRemoved = GameStorage.isAdsRemoved();
    });
  }

  Future<void> _toggleSound(bool val) async {
    await GameStorage.setSoundEnabled(val);
    setState(() => _sound = val);
    if (val) AudioService.playTap();
  }

  Future<void> _toggleMusic(bool val) async {
    await GameStorage.setMusicEnabled(val);
    setState(() => _music = val);
    await AudioService.onMusicSettingChanged(val);
  }

  Future<void> _toggleHaptics(bool val) async {
    await GameStorage.setHapticsEnabled(val);
    setState(() => _haptics = val);
  }

  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded,
                    color: Colors.lightBlueAccent, size: 22),
                const SizedBox(width: 10),
                Text(
                  'How to Play Huddle Up',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _guideItem(
              icon: Icons.holiday_village_rounded,
              color: const Color(0xFFFFD54F),
              title: 'The Meeting Camp',
              desc:
                  'Every maze has a glowing golden Camp. All penguins must navigate into this camp and huddle together to win!',
            ),
            const SizedBox(height: 12),
            _guideItem(
              icon: Icons.directions_walk_rounded,
              color: const Color(0xFF2196F3),
              title: 'Jacket Colors Define Moves',
              desc:
                  'Blue walks 4 directions. Green walks up/down only. Orange walks left/right only. Red slides until blocked.',
            ),
            const SizedBox(height: 12),
            _guideItem(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFE91E63),
              title: 'Lives & Timer',
              desc:
                  'You have 3 Lives and a level timer. Avoid water and holes, or use a Rewarded Ad to refill your lives/time!',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _guideItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142435),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset All Progress?',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will reset all unlocked levels and stars back to Level 1. This action cannot be undone.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await GameStorage.resetAllProgress();
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Progress has been reset.')),
                );
              }
            },
            child: Text('Reset', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // VIP / Remove Ads Banner
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PurchaseScreen()),
                      );
                      _loadSettings();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isAdsRemoved
                              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                              : [const Color(0xFFE65100), const Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isAdsRemoved ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAdsRemoved
                                ? Icons.security_rounded
                                : Icons.military_tech_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAdsRemoved ? 'VIP ACTIVE' : 'REMOVE ADS',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  _isAdsRemoved
                                      ? 'All ads removed · VIP benefits enabled'
                                      : 'Play ad-free with instant lives & extra time',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('AUDIO & HAPTICS'),

                  _SettingSwitchTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    value: _sound,
                    onChanged: _toggleSound,
                  ),
                  const SizedBox(height: 8),
                  _SettingSwitchTile(
                    icon: Icons.music_note_rounded,
                    title: 'Background Ambience',
                    value: _music,
                    onChanged: _toggleMusic,
                  ),
                  const SizedBox(height: 8),
                  _SettingSwitchTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Vibrations',
                    value: _haptics,
                    onChanged: _toggleHaptics,
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('HELP & ABOUT'),

                  _SettingActionTile(
                    icon: Icons.help_outline_rounded,
                    title: 'How to Play',
                    subtitle: 'Rules, movement types, and strategies',
                    onTap: _showHowToPlay,
                  ),
                  const SizedBox(height: 8),
                  _SettingActionTile(
                    icon: Icons.replay_rounded,
                    title: 'Reset Progress',
                    subtitle: 'Start fresh from Level 1',
                    isDestructive: true,
                    onTap: _confirmReset,
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Huddle Up v1.0.0 · Antarctic Puzzle Engine',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // AdMob Banner
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.lightBlueAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF142435),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF2196F3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFEF5350) : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF142435),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: isDestructive ? Colors.redAccent : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }
}
