// lib/ui/screens/level_select_screen.dart
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/game_storage.dart';
import '../../services/ad_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'purchase_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _maxUnlocked = 1;
  int _totalStars = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _maxUnlocked = GameStorage.getMaxUnlockedLevel();
      _totalStars = GameStorage.getTotalStars();
    });
  }

  @override
  Widget build(BuildContext context) {
    const totalLevels = 250;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Choose Level',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Stars count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2A3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFD54F), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '$_totalStars',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Fish Coins badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2A3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4DD0E1).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.set_meal_rounded,
                            color: Color(0xFF4DD0E1), size: 13),
                        const SizedBox(width: 5),
                        Text(
                          '${GameStorage.getFishCoins()}',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF4DD0E1),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // VIP Crown
                  IconButton(
                    icon: const Icon(Icons.military_tech_rounded,
                        color: Color(0xFFFFB300), size: 18),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PurchaseScreen()),
                      );
                      _refresh();
                    },
                  ),
                  // Settings
                  IconButton(
                    icon: const Icon(Icons.settings_rounded,
                        color: Colors.white70, size: 18),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                      _refresh();
                    },
                  ),
                ],
              ),
            ),

            // World Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _WorldSection(
                    icon: Icons.terrain_rounded,
                    worldName: 'Ice Shelf',
                    subtitle: '6×6 · 2 penguins · meet at camp',
                    startLevel: 1,
                    endLevel: 5,
                    accent: const Color(0xFF2196F3),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.ac_unit_rounded,
                    worldName: 'Frozen Path',
                    subtitle: '6×6 · 2 penguins · ice blocks appear',
                    startLevel: 6,
                    endLevel: 15,
                    accent: const Color(0xFF00BCD4),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.air_rounded,
                    worldName: 'Blizzard Roads',
                    subtitle: '7×7 · 2 penguins · orange joins',
                    startLevel: 16,
                    endLevel: 30,
                    accent: const Color(0xFF4CAF50),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.speed_rounded,
                    worldName: 'Red Rush',
                    subtitle: '8×8 · 2 penguins · sliders arrive',
                    startLevel: 31,
                    endLevel: 50,
                    accent: const Color(0xFFF44336),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.water_rounded,
                    worldName: 'Frozen Lake',
                    subtitle: '9×9 · 3 penguins · water hazards',
                    startLevel: 51,
                    endLevel: 75,
                    accent: const Color(0xFF1565C0),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.call_split_rounded,
                    worldName: 'Hop Valley',
                    subtitle: '10×10 · 3 penguins · yellow hops',
                    startLevel: 76,
                    endLevel: 100,
                    accent: const Color(0xFFFFB300),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.shuffle_rounded,
                    worldName: 'Swap Lands',
                    subtitle: '11×11 · 4 penguins · cracked ice',
                    startLevel: 101,
                    endLevel: 150,
                    accent: const Color(0xFF9C27B0),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.layers_rounded,
                    worldName: 'Deep Tundra',
                    subtitle: '12×12 · 5 penguins · grey chain push',
                    startLevel: 151,
                    endLevel: 200,
                    accent: const Color(0xFF607D8B),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
                  _WorldSection(
                    icon: Icons.cyclone_rounded,
                    worldName: 'Blizzard Peak',
                    subtitle: '12–14×12–14 · 5–8 penguins · master mode',
                    startLevel: 201,
                    endLevel: totalLevels,
                    accent: const Color(0xFFE91E63),
                    maxUnlocked: _maxUnlocked,
                    onLevelSelected: (lvl) => _openLevel(lvl),
                  ),
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

  void _openLevel(int lvl) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(levelNumber: lvl)),
    );
    _refresh();
  }
}

// ─────────────────────────── World Section ───────────────────────────────────

class _WorldSection extends StatelessWidget {
  final IconData icon;
  final String worldName;
  final String subtitle;
  final int startLevel;
  final int endLevel;
  final Color accent;
  final int maxUnlocked;
  final ValueChanged<int> onLevelSelected;

  const _WorldSection({
    required this.icon,
    required this.worldName,
    required this.subtitle,
    required this.startLevel,
    required this.endLevel,
    required this.accent,
    required this.maxUnlocked,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isWorldUnlocked = maxUnlocked >= startLevel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isWorldUnlocked ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isWorldUnlocked ? accent : Colors.white30,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worldName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isWorldUnlocked ? Colors.white : Colors.white38,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isWorldUnlocked ? Colors.white54 : Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Levels grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: endLevel - startLevel + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (ctx, i) {
              final lvl = startLevel + i;
              final isUnlocked = lvl <= maxUnlocked;
              final stars = GameStorage.getStarsForLevel(lvl);
              final isCurrent = lvl == maxUnlocked;

              return _LevelTile(
                level: lvl,
                isUnlocked: isUnlocked,
                isCurrent: isCurrent,
                stars: stars,
                accent: accent,
                onTap: isUnlocked ? () => onLevelSelected(lvl) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Level Tile ──────────────────────────────────────

class _LevelTile extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final int stars;
  final Color accent;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.stars,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF1B2A3D) : const Color(0xFF111C28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? accent
              : (isUnlocked
                  ? accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06)),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isUnlocked) ...[
                Text(
                  '$level',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                // Star row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (starIdx) {
                    final earned = starIdx < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        earned ? Icons.star_rounded : Icons.star_border_rounded,
                        color: earned ? const Color(0xFFFFD54F) : Colors.white24,
                        size: 8,
                      ),
                    );
                  }),
                ),
              ] else ...[
                const Icon(
                  Icons.lock_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
                const SizedBox(height: 4),
                Text(
                  '$level',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (isCurrent) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.05, duration: 900.ms, curve: Curves.easeInOut);
    }

    return card;
  }
}
