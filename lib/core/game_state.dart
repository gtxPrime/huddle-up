// lib/core/game_state.dart
import 'tile_types.dart';
import 'penguin_types.dart';

class Position {
  final int x, y;
  const Position(this.x, this.y);

  Position operator +(Position other) => Position(x + other.x, y + other.y);
  Position translate(int dx, int dy) => Position(x + dx, y + dy);

  @override
  bool operator ==(Object other) =>
      other is Position && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  static Position fromJson(Map<String, dynamic> j) =>
      Position(j['x'] as int, j['y'] as int);
}

class Penguin {
  final int id;
  final PenguinColor color;
  final Position pos;
  final int clumpId; // -1 = solo
  final bool inIgloo;
  final int maxMoves;
  final int movesLeft;

  const Penguin({
    required this.id,
    required this.color,
    required this.pos,
    required this.clumpId,
    this.inIgloo = false,
    this.maxMoves = 10,
    int? movesLeft,
  }) : movesLeft = movesLeft ?? maxMoves;

  Penguin copyWith({
    int? id,
    PenguinColor? color,
    Position? pos,
    int? clumpId,
    bool? inIgloo,
    int? maxMoves,
    int? movesLeft,
  }) =>
      Penguin(
        id: id ?? this.id,
        color: color ?? this.color,
        pos: pos ?? this.pos,
        clumpId: clumpId ?? this.clumpId,
        inIgloo: inIgloo ?? this.inIgloo,
        maxMoves: maxMoves ?? this.maxMoves,
        movesLeft: movesLeft ?? this.movesLeft,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.name,
        'x': pos.x,
        'y': pos.y,
        'inIgloo': inIgloo,
        'maxMoves': maxMoves,
        'movesLeft': movesLeft,
      };

  static Penguin fromJson(Map<String, dynamic> j) => Penguin(
        id: j['id'] as int,
        color: PenguinColor.values.byName(j['color'] as String),
        pos: Position(j['x'] as int, j['y'] as int),
        clumpId: -1,
        inIgloo: j['inIgloo'] as bool? ?? false,
        maxMoves: j['maxMoves'] as int? ?? 10,
        movesLeft: j['movesLeft'] as int?,
      );
}

class IceBlock {
  final Position pos;
  const IceBlock(this.pos);

  IceBlock copyWith({Position? pos}) => IceBlock(pos ?? this.pos);

  Map<String, dynamic> toJson() => pos.toJson();
  static IceBlock fromJson(Map<String, dynamic> j) =>
      IceBlock(Position.fromJson(j));
}

class GameState {
  final int width, height;
  final List<List<TileType>> tiles; // tiles[y][x]
  final List<Penguin> penguins;
  final List<IceBlock> blocks;
  final List<Position> igloo;
  final List<Position> fish;
  final int rewindsLeft;
  final int movesMade;
  final int selectedId; // penguin id or -1

  const GameState({
    required this.width,
    required this.height,
    required this.tiles,
    required this.penguins,
    required this.blocks,
    required this.igloo,
    required this.fish,
    this.rewindsLeft = 3,
    this.movesMade = 0,
    this.selectedId = -1,
  });

  TileType tile(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return TileType.wall;
    return tiles[y][x];
  }

  TileType tileAt(Position p) => tile(p.x, p.y);

  Penguin? penguinAt(Position p) {
    for (final pg in penguins) {
      if (!pg.inIgloo && pg.pos == p) return pg;
    }
    return null;
  }

  IceBlock? blockAt(Position p) {
    for (final b in blocks) {
      if (b.pos == p) return b;
    }
    return null;
  }

  bool inBounds(Position p) =>
      p.x >= 0 && p.x < width && p.y >= 0 && p.y < height;

  bool isSolid(Position p) {
    if (!inBounds(p)) return true;
    final t = tileAt(p);
    if (t.isSolid) return true;
    return false;
  }

  Penguin? get selectedPenguin {
    if (selectedId < 0) return null;
    for (final p in penguins) {
      if (p.id == selectedId && !p.inIgloo) return p;
    }
    return null;
  }

  GameState copyWith({
    int? width,
    int? height,
    List<List<TileType>>? tiles,
    List<Penguin>? penguins,
    List<IceBlock>? blocks,
    List<Position>? igloo,
    List<Position>? fish,
    int? rewindsLeft,
    int? movesMade,
    int? selectedId,
  }) =>
      GameState(
        width: width ?? this.width,
        height: height ?? this.height,
        tiles: tiles ?? this.tiles,
        penguins: penguins ?? this.penguins,
        blocks: blocks ?? this.blocks,
        igloo: igloo ?? this.igloo,
        fish: fish ?? this.fish,
        rewindsLeft: rewindsLeft ?? this.rewindsLeft,
        movesMade: movesMade ?? this.movesMade,
        selectedId: selectedId ?? this.selectedId,
      );

  // ---------- serialisation ----------

  static List<List<TileType>> _tilesFromJson(List<dynamic> rows) =>
      rows
          .map((row) => (row as List<dynamic>)
              .map((v) => TileType.values[v as int])
              .toList())
          .toList();

  static List<List<int>> _tilesToJson(List<List<TileType>> tiles) =>
      tiles.map((row) => row.map((t) => t.index).toList()).toList();

  factory GameState.fromJson(Map<String, dynamic> j) {
    final rawTiles = j['tiles'] as List<dynamic>;
    final tiles = _tilesFromJson(rawTiles);
    final height = tiles.length;
    final width = height > 0 ? tiles[0].length : 0;

    return GameState(
      width: width,
      height: height,
      tiles: tiles,
      penguins: (j['penguins'] as List<dynamic>)
          .map((e) => Penguin.fromJson(e as Map<String, dynamic>))
          .toList(),
      blocks: (j['blocks'] as List<dynamic>? ?? [])
          .map((e) => IceBlock.fromJson(e as Map<String, dynamic>))
          .toList(),
      igloo: (j['igloo'] as List<dynamic>? ?? [])
          .map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      fish: (j['fish'] as List<dynamic>? ?? [])
          .map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewindsLeft: j['rewinds'] as int? ?? 3,
      movesMade: 0,
      selectedId: -1,
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'tiles': _tilesToJson(tiles),
        'penguins': penguins.map((p) => p.toJson()).toList(),
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'igloo': igloo.map((p) => p.toJson()).toList(),
        'fish': fish.map((p) => p.toJson()).toList(),
        'rewinds': rewindsLeft,
      };
}
