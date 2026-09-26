// lib/core/tile_types.dart
enum TileType {
  floor,
  slippery,
  wall,
  water,
  cracked,
  hole,
  bridge,
  igloo,
}

extension TileTypeX on TileType {
  bool get isPassable => this == TileType.floor ||
      this == TileType.slippery ||
      this == TileType.cracked ||
      this == TileType.igloo ||
      this == TileType.bridge;

  bool get isHazard =>
      this == TileType.water || this == TileType.hole;

  bool get isSolid =>
      this == TileType.wall;

  int toJson() => index;
  static TileType fromJson(int v) => TileType.values[v];
}
