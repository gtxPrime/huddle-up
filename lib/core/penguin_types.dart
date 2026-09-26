// lib/core/penguin_types.dart
import 'dart:ui';

enum PenguinColor { blue, green, orange, red, yellow, purple, pink, grey }

enum MoveKind { walk, slideUntilBlocked, hop2, swap, diagonalOnly, chainPush }

class PenguinDef {
  final PenguinColor color;
  final Set<Direction> allowedDirs;
  final MoveKind moveKind;
  final String symbol;
  final Color displayColor;

  const PenguinDef({
    required this.color,
    required this.allowedDirs,
    required this.moveKind,
    required this.symbol,
    required this.displayColor,
  });
}

enum Direction { up, down, left, right, upLeft, upRight, downLeft, downRight }

extension DirectionX on Direction {
  bool get isDiagonal =>
      this == Direction.upLeft ||
      this == Direction.upRight ||
      this == Direction.downLeft ||
      this == Direction.downRight;

  (int, int) get delta => switch (this) {
        Direction.up => (0, -1),
        Direction.down => (0, 1),
        Direction.left => (-1, 0),
        Direction.right => (1, 0),
        Direction.upLeft => (-1, -1),
        Direction.upRight => (1, -1),
        Direction.downLeft => (-1, 1),
        Direction.downRight => (1, 1),
      };

  String get label => switch (this) {
        Direction.up => '▲',
        Direction.down => '▼',
        Direction.left => '◀',
        Direction.right => '▶',
        Direction.upLeft => '↖',
        Direction.upRight => '↗',
        Direction.downLeft => '↙',
        Direction.downRight => '↘',
      };

  String get name => switch (this) {
        Direction.up => 'up',
        Direction.down => 'down',
        Direction.left => 'left',
        Direction.right => 'right',
        Direction.upLeft => 'upLeft',
        Direction.upRight => 'upRight',
        Direction.downLeft => 'downLeft',
        Direction.downRight => 'downRight',
      };

  static Direction fromName(String s) =>
      Direction.values.firstWhere((d) => d.name == s);
}

const Set<Direction> _cardinals = {
  Direction.up,
  Direction.down,
  Direction.left,
  Direction.right,
};
const Set<Direction> _diagonals = {
  Direction.upLeft,
  Direction.upRight,
  Direction.downLeft,
  Direction.downRight,
};
const Set<Direction> _upDown = {Direction.up, Direction.down};
const Set<Direction> _leftRight = {Direction.left, Direction.right};

const Map<PenguinColor, PenguinDef> kPenguinDefs = {
  PenguinColor.blue: PenguinDef(
    color: PenguinColor.blue,
    allowedDirs: _cardinals,
    moveKind: MoveKind.walk,
    symbol: '✚',
    displayColor: Color(0xFF2196F3),
  ),
  PenguinColor.green: PenguinDef(
    color: PenguinColor.green,
    allowedDirs: _upDown,
    moveKind: MoveKind.walk,
    symbol: '↕',
    displayColor: Color(0xFF4CAF50),
  ),
  PenguinColor.orange: PenguinDef(
    color: PenguinColor.orange,
    allowedDirs: _leftRight,
    moveKind: MoveKind.walk,
    symbol: '↔',
    displayColor: Color(0xFFFF9800),
  ),
  PenguinColor.red: PenguinDef(
    color: PenguinColor.red,
    allowedDirs: _cardinals,
    moveKind: MoveKind.slideUntilBlocked,
    symbol: '➤➤',
    displayColor: Color(0xFFF44336),
  ),
  PenguinColor.yellow: PenguinDef(
    color: PenguinColor.yellow,
    allowedDirs: _cardinals,
    moveKind: MoveKind.hop2,
    symbol: '⤴',
    displayColor: Color(0xFFFFEB3B),
  ),
  PenguinColor.purple: PenguinDef(
    color: PenguinColor.purple,
    allowedDirs: _cardinals,
    moveKind: MoveKind.swap,
    symbol: '⇄',
    displayColor: Color(0xFF9C27B0),
  ),
  PenguinColor.pink: PenguinDef(
    color: PenguinColor.pink,
    allowedDirs: _diagonals,
    moveKind: MoveKind.diagonalOnly,
    symbol: '✕',
    displayColor: Color(0xFFE91E63),
  ),
  PenguinColor.grey: PenguinDef(
    color: PenguinColor.grey,
    allowedDirs: _cardinals,
    moveKind: MoveKind.chainPush,
    symbol: '■',
    displayColor: Color(0xFF9E9E9E),
  ),
};
