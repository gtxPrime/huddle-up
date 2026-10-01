// lib/ui/screens/wardrobe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';

class HatItem {
  final String id;
  final String name;
  final int cost;
  final IconData icon;
  final Color color;

  const HatItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.icon,
    required this.color,
  });
}

const List<HatItem> kHatItems = [
  HatItem(
    id: 'none',
    name: 'Classic Penguin',
    cost: 0,
    icon: Icons.account_circle_rounded,
    color: Colors.white70,
  ),
  HatItem(
    id: 'scarf',
    name: 'Glacier Scarf',
    cost: 0,
    icon: Icons.dry_cleaning_rounded,
    color: Color(0xFF00E5FF),
  ),
  HatItem(
    id: 'ribbon',
    name: 'Festive Ribbon',
    cost: 150,
    icon: Icons.celebration_rounded,
    color: Color(0xFFFF5252),
  ),
  HatItem(
    id: 'tophat',
    name: "Gentleman's Hat",
    cost: 300,
    icon: Icons.architecture_rounded,
    color: Color(0xFF78909C),
  ),
  HatItem(
    id: 'earmuffs',
    name: 'Warm Earmuffs',
    cost: 350,
    icon: Icons.headphones_rounded,
    color: Color(0xFFFF4081),
  ),
  HatItem(
    id: 'shades',
    name: 'Polar Shades',
    cost: 450,
    icon: Icons.visibility_rounded,
    color: Color(0xFF64B5F6),
  ),
  HatItem(
    id: 'crown',
    name: 'Royal Ice Crown',
    cost: 800,
    icon: Icons.military_tech_rounded,
    color: Color(0xFFFFD54F),
  ),
];

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late String _equippedHat;
  late Set<String> _ownedHats;
  late int _fishCoins;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _equippedHat = GameStorage.getEquippedHat();
      _ownedHats = GameStorage.getOwnedHats();
      _fishCoins = GameStorage.getFishCoins();
    });
  }

  Future<void> _equip(String hatId) async {
    AudioService.playTap();
    if (GameStorage.isHapticsEnabled()) {
      HapticFeedback.selectionClick();
    }
    await GameStorage.setEquippedHat(hatId);
    _refresh();
  }

  Future<void> _buy(HatItem item) async {
    if (_fishCoins < item.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Need ${item.cost - _fishCoins} more fish! Watch ads or win levels to get more.',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
        ),
      );
      return;
    }

    AudioService.playReward();
    if (GameStorage.isHapticsEnabled()) {
      HapticFeedback.heavyImpact();
    }
    await GameStorage.addFishCoins(-item.cost);
    await GameStorage.unlockHat(item.id);
    await GameStorage.setEquippedHat(item.id);
    _refresh();
  }

  void _rentWithAd(HatItem item) {
    AdService.showRewardedMysteryGiftAd(
      context,
      onRewardEarned: () async {
        AudioService.playReward();
        if (GameStorage.isHapticsEnabled()) {
          HapticFeedback.heavyImpact();
        }
        await GameStorage.unlockHat(item.id);
        await GameStorage.setEquippedHat(item.id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00E676),
              content: Text(
                'Hat Unlocked and Equipped! Looking sharp!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeItem = kHatItems.firstWhere(
      (h) => h.id == _equippedHat,
      orElse: () => kHatItems.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Penguin Wardrobe',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Fish Coins
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132F4C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.set_meal_rounded,
                            color: Color(0xFF00E5FF), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$_fishCoins',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Live Penguin Preview Stage
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const RadialGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF0B192C)],
                  radius: 0.9,
                ),
                border: Border.all(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    // Penguin Doll
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow pedestal
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0288D1)
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        // Penguin body
                        Container(
                          width: 86,
                          height: 86,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Royal Blue Jacket
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF0D47A1)
                                    ],
                                    center: Alignment(-0.3, -0.3),
                                  ),
                                ),
                              ),
                              // White belly
                              Center(
                                child: Container(
                                  width: 46,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // Eyes
                              Positioned(
                                top: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _eye(),
                                    const SizedBox(width: 8),
                                    _eye(),
                                  ],
                                ),
                              ),
                              // Beak
                              Positioned(
                                top: 29,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9800),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              // Hat on head
                              if (activeItem.id != 'none')
                                Positioned(
                                  top: -2,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Icon(
                                      activeItem.icon,
                                      color: activeItem.color,
                                      size: 26,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activeItem.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Equipped & Ready for Adventure',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hat Catalog Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: kHatItems.length,
                itemBuilder: (ctx, i) {
                  final item = kHatItems[i];
                  final isOwned = _ownedHats.contains(item.id) || item.cost == 0;
                  final isEquipped = _equippedHat == item.id;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isEquipped
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : const Color(0xFF132F4C).withValues(alpha: 0.6),
                      border: Border.all(
                        color: isEquipped
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.12),
                        width: isEquipped ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(item.icon, color: item.color, size: 24),
                            if (isEquipped)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            else if (isOwned)
                              const Icon(Icons.check_circle,
                                  color: Colors.greenAccent, size: 16)
                            else
                              Row(
                                children: [
                                  const Icon(Icons.set_meal_rounded,
                                      color: Color(0xFF00E5FF), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.cost}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Text(
                          item.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isOwned)
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEquipped
                                    ? Colors.white12
                                    : const Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: isEquipped ? null : () => _equip(item.id),
                              child: Text(
                                isEquipped ? 'Equipped' : 'Equip',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isEquipped
                                      ? Colors.white38
                                      : Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: [
                              // Buy Button
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00C853),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => _buy(item),
                                    child: Text(
                                      'Buy',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Rent with Ad Button
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => _rentWithAd(item),
                                    child: const Icon(
                                      Icons.play_circle_fill_rounded,
                                      color: Color(0xFF0D1B2A),
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eye() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
