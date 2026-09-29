import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/penguin_types.dart';
import '../../services/game_storage.dart';

class KawaiiPenguin extends StatelessWidget {
  final PenguinColor color;
  final double size;
  final bool isSelected;
  final bool isDead;
  final bool showBadge;
  final int? movesLeft;
  final String? hat;

  const KawaiiPenguin({
    super.key,
    required this.color,
    required this.size,
    this.isSelected = false,
    this.isDead = false,
    this.showBadge = true,
    this.movesLeft,
    this.hat,
  });

  @override
  Widget build(BuildContext context) {
    final def = kPenguinDefs[color]!;
    final effectiveHat = hat ?? GameStorage.getEquippedHat();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Ground Drop Shadow ──────────────────────────────────────
          Positioned(
            bottom: size * 0.02,
            child: Container(
              width: size * 0.65,
              height: size * 0.16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(size * 0.32, size * 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.38),
                    blurRadius: size * 0.12,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ),

          // ── Little Orange Feet ──────────────────────────────────────
          Positioned(
            bottom: size * 0.04,
            left: size * 0.26,
            child: _buildFoot(size, -0.2),
          ),
          Positioned(
            bottom: size * 0.04,
            right: size * 0.26,
            child: _buildFoot(size, 0.2),
          ),

          // ── Left & Right Flippers (Wings) ───────────────────────────
          Positioned(
            left: size * 0.04,
            top: size * 0.38,
            child: Transform.rotate(
              angle: isSelected ? -0.45 : -0.22,
              child: _buildFlipper(size, def.displayColor),
            ),
          ),
          Positioned(
            right: size * 0.04,
            top: size * 0.38,
            child: Transform.rotate(
              angle: isSelected ? 0.45 : 0.22,
              child: _buildFlipper(size, def.displayColor),
            ),
          ),

          // ── Main Chubby Pear Body ───────────────────────────────────
          Center(
            child: Container(
              width: size * 0.74,
              height: size * 0.82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.37),
                  bottom: Radius.circular(size * 0.32),
                ),
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  radius: 0.95,
                  colors: [
                    _tint(def.displayColor, 0.35),
                    def.displayColor,
                    _shade(def.displayColor, 0.35),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: isSelected
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: def.displayColor.withValues(alpha: isSelected ? 0.85 : 0.35),
                    blurRadius: isSelected ? size * 0.36 : size * 0.12,
                    spreadRadius: isSelected ? size * 0.06 : 0,
                  ),
                ],
              ),
            ),
          ),

          // ── Snow-White Down Belly ───────────────────────────────────
          Positioned(
            bottom: size * 0.10,
            child: Container(
              width: size * 0.48,
              height: size * 0.52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * 0.24),
                  bottom: Radius.circular(size * 0.22),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF0F4F8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // ── Kawaii Eyes & Blush Cheeks ──────────────────────────────
          Positioned(
            top: size * 0.22,
            child: SizedBox(
              width: size * 0.50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildKawaiiEye(size),
                  _buildKawaiiEye(size),
                ],
              ),
            ),
          ),

          // ── Rosy Blush Cheeks ───────────────────────────────────────
          Positioned(
            top: size * 0.33,
            child: SizedBox(
              width: size * 0.54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBlush(size),
                  _buildBlush(size),
                ],
              ),
            ),
          ),

          // ── Cute Golden-Orange Beak ─────────────────────────────────
          Positioned(
            top: size * 0.32,
            child: Container(
              width: size * 0.16,
              height: size * 0.11,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(size * 0.05),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFB74D),
                    Color(0xFFF57C00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // ── Movement Direction / Move Counter Badge on Belly ──────
          if (showBadge)
            Positioned(
              bottom: size * 0.10,
              child: movesLeft != null
                  ? _buildBellyMoveBadge(
                      color, movesLeft!, size * 0.22, def.displayColor)
                  : _buildMovementBadge(
                      color, size * 0.22, def.displayColor),
            ),

          // ── Equipped Hat Accessory ──────────────────────────────────
          if (effectiveHat != 'none')
            Positioned(
              top: -size * 0.08,
              child: Icon(
                _hatIcon(effectiveHat),
                color: _hatColor(effectiveHat),
                size: (size * 0.36).clamp(12.0, 24.0),
              ),
            ),

          // ── Dead Clump Frost Coating ────────────────────────────────
          if (isDead)
            Container(
              width: size * 0.82,
              height: size * 0.88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.4),
                color: const Color(0xFF81D4FA).withValues(alpha: 0.45),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Icon(
                  Icons.ac_unit_rounded,
                  color: Colors.white,
                  size: (size * 0.32).clamp(10.0, 20.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildFoot(double size, double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size * 0.16,
        height: size * 0.09,
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(size * 0.04),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFlipper(double size, Color baseColor) {
    return Container(
      width: size * 0.12,
      height: size * 0.28,
      decoration: BoxDecoration(
        color: _shade(baseColor, 0.25),
        borderRadius: BorderRadius.circular(size * 0.06),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  static Widget _buildKawaiiEye(double size) {
    final eyeW = size * 0.12;
    final eyeH = size * 0.14;
    return Container(
      width: eyeW,
      height: eyeH,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1B2631),
      ),
      child: Stack(
        children: [
          // Top-right large twinkle catchlight
          Positioned(
            top: eyeH * 0.15,
            right: eyeW * 0.18,
            child: Container(
              width: eyeW * 0.42,
              height: eyeW * 0.42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
          // Bottom-left micro catchlight
          Positioned(
            bottom: eyeH * 0.15,
            left: eyeW * 0.18,
            child: Container(
              width: eyeW * 0.22,
              height: eyeW * 0.22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBlush(double size) {
    return Container(
      width: size * 0.11,
      height: size * 0.07,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A80).withValues(alpha: 0.65),
        borderRadius: BorderRadius.all(Radius.elliptical(size * 0.055, size * 0.035)),
      ),
    );
  }

  static Widget _buildBellyMoveBadge(
    PenguinColor color,
    int movesLeft,
    double bSize,
    Color displayColor,
  ) {
    final isOutOfMoves = movesLeft <= 0;
    IconData dirIcon;
    switch (color) {
      case PenguinColor.blue:
        dirIcon = Icons.gamepad_rounded;
      case PenguinColor.green:
        dirIcon = Icons.unfold_more_rounded;
      case PenguinColor.orange:
        dirIcon = Icons.code_rounded;
      case PenguinColor.red:
        dirIcon = Icons.fast_forward_rounded;
      default:
        dirIcon = Icons.star_rounded;
    }

    final badgeD = (bSize * 1.35).clamp(20.0, 36.0);

    return Container(
      width: badgeD,
      height: badgeD,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOutOfMoves ? const Color(0xFFFF2A4B) : Colors.white,
        border: Border.all(
          color: isOutOfMoves ? Colors.white : displayColor,
          width: isOutOfMoves ? 1.8 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isOutOfMoves
                ? const Color(0xFFFF1744).withValues(alpha: 0.65)
                : displayColor.withValues(alpha: 0.35),
            blurRadius: isOutOfMoves ? 8 : 4,
            spreadRadius: isOutOfMoves ? 1 : 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dirIcon,
            color: isOutOfMoves ? Colors.white70 : displayColor,
            size: (bSize * 0.40).clamp(7.0, 11.0),
          ),
          Text(
            '$movesLeft',
            style: GoogleFonts.outfit(
              color: isOutOfMoves ? Colors.white : const Color(0xFF0F172A),
              fontSize: (bSize * 0.58).clamp(9.0, 15.0),
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMovementBadge(PenguinColor color, double bSize, Color displayColor) {
    IconData icon;
    switch (color) {
      case PenguinColor.blue:
        icon = Icons.gamepad_rounded;
      case PenguinColor.green:
        icon = Icons.unfold_more_rounded;
      case PenguinColor.orange:
        icon = Icons.code_rounded;
      case PenguinColor.red:
        icon = Icons.fast_forward_rounded;
      default:
        icon = Icons.star_rounded;
    }

    return Container(
      width: bSize.clamp(14.0, 26.0),
      height: bSize.clamp(14.0, 26.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: displayColor.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: displayColor.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: displayColor,
          size: (bSize * 0.75).clamp(10.0, 18.0),
        ),
      ),
    );
  }

  static IconData _hatIcon(String hat) {
    switch (hat) {
      case 'crown':
        return Icons.military_tech_rounded;
      case 'tophat':
        return Icons.architecture_rounded;
      case 'scarf':
        return Icons.dry_cleaning_rounded;
      case 'ribbon':
        return Icons.celebration_rounded;
      case 'earmuffs':
        return Icons.headphones_rounded;
      case 'shades':
        return Icons.visibility_rounded;
      default:
        return Icons.military_tech_rounded;
    }
  }

  static Color _hatColor(String hat) {
    switch (hat) {
      case 'crown':
        return const Color(0xFFFFD54F);
      case 'tophat':
        return const Color(0xFFCFD8DC);
      case 'scarf':
        return const Color(0xFF00E5FF);
      case 'ribbon':
        return const Color(0xFFFF5252);
      case 'earmuffs':
        return const Color(0xFFFF4081);
      case 'shades':
        return const Color(0xFF64B5F6);
      default:
        return const Color(0xFFFFD54F);
    }
  }

  static Color _tint(Color c, double factor) {
    final hsl = HSLColor.fromColor(c);
    final newLightness = (hsl.lightness + (1.0 - hsl.lightness) * factor).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  static Color _shade(Color c, double factor) {
    final hsl = HSLColor.fromColor(c);
    final newLightness = (hsl.lightness * (1.0 - factor)).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}
