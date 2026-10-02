// lib/ui/screens/purchase_screen.dart
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../services/game_storage.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _isPurchased = false;

  @override
  void initState() {
    super.initState();
    _isPurchased = GameStorage.isAdsRemoved();
  }

  Future<void> _handlePurchase() async {
    await GameStorage.setAdsRemoved(true);
    setState(() => _isPurchased = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All Ads Removed! Thank you for supporting Huddle Up!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _handleRestore() async {
    final status = GameStorage.isAdsRemoved();
    setState(() => _isPurchased = status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status
            ? 'Purchases restored: Ads are removed.'
            : 'No prior purchases found on this account.'),
        backgroundColor: const Color(0xFF1E88E5),
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
          'Remove Ads',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Hero Icon / Crown
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'HUDDLE UP VIP',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFFD54F),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Play Pure Puzzle Bliss',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Perks List
              const _PerkTile(
                icon: Icons.block_rounded,
                title: 'No Banner Ads',
                subtitle: 'Zero ads at the bottom of the screen.',
                color: Color(0xFFEF5350),
              ),
              const SizedBox(height: 12),
              const _PerkTile(
                icon: Icons.flash_on_rounded,
                title: 'No Interstitial Breaks',
                subtitle: 'Smooth, instant transitions between levels.',
                color: Color(0xFF29B6F6),
              ),
              const SizedBox(height: 12),
              const _PerkTile(
                icon: Icons.security_rounded,
                title: 'Ad-Free Concentration',
                subtitle: 'Never interrupted by popups while solving.',
                color: Color(0xFF66BB6A),
              ),
              const SizedBox(height: 12),
              const _PerkTile(
                icon: Icons.military_tech_rounded,
                title: 'Permanent VIP Status',
                subtitle: 'Golden crown badge and supporter benefits.',
                color: Color(0xFFFFCA28),
              ),

              const Spacer(),

              // Purchase Button
              if (_isPurchased)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF81C784), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'VIP Active · All Ads Removed',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: const Color(0xFF0D1B2A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _handlePurchase,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_offer_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Remove All Ads · \$2.99',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _handleRestore,
                child: Text(
                  'Restore Previous Purchase',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PerkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF142435),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
