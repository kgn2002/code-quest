import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'game_view.dart';

class TownMap extends PositionComponent with HasGameRef<CodeQuestGame> {
  late TiledComponent tiledMap;
  bool _isLoading = false;

  @override
  Future<void> onLoad() async {
    await _loadMap('village1_map.tmx');
  }

  // Called by Player._switchToMap()
  Future<void> switchMap(String newMapFile) async {
    if (_isLoading) return;
    _isLoading = true;
    debugPrint('TownMap: switching to $newMapFile');

    // Clear everything — old map tiles + old collision objects
    removeWhere((_) => true);
    await Future.delayed(const Duration(milliseconds: 50));

    await _loadMap(newMapFile);
    _isLoading = false;
    debugPrint('TownMap: ready → $newMapFile');
  }

  Future<void> _loadMap(String file) async {
    debugPrint('Loading map: $file');
    tiledMap = await TiledComponent.load(file, Vector2.all(64));
    add(tiledMap);
    _addCollisions(file);
  }

  void _addCollisions(String mapFile) {
    int count = 0;

    // Primary: object layer drawn in Tiled editor
    final objectLayer = tiledMap.tileMap.getLayer<ObjectGroup>('Collisions');
    if (objectLayer != null) {
      for (final obj in objectLayer.objects) {
        if (obj.width <= 0 || obj.height <= 0) continue; // skip point objects
        final double w = obj.width  < 32 ? 32 : obj.width;  // min 32px width
        final double h = obj.height < 32 ? 32 : obj.height; // min 32px height
        final wall = PositionComponent(
          position: Vector2(obj.x, obj.y),
          size: Vector2(w, h),
        );
        wall.add(RectangleHitbox(
          size: Vector2(w, h),
          collisionType: CollisionType.passive,
        ));
        add(wall);
        count++;
      }
    }

    // Patch: buildings missing from object layer (village1 only)
    for (final p in _getMissingCollisions(mapFile)) {
      final patch = PositionComponent(
        position: Vector2(p['x']!, p['y']!),
        size: Vector2(p['w']!, p['h']!),
      );
      patch.add(RectangleHitbox(
        size: Vector2(p['w']!, p['h']!),
        collisionType: CollisionType.passive,
      ));
      add(patch);
      count++;
    }

    debugPrint('Collisions loaded: $count for $mapFile');
  }

  List<Map<String, double>> _getMissingCollisions(String mapFile) {
    if (mapFile == 'village1_map.tmx') {
      return [
        {'x': 0,   'y': 192, 'w': 256, 'h': 256}, // Library
        {'x': 512, 'y': 320, 'w': 128, 'h': 96},  // Small building
        // Tower (cols 11-12, rows 11-12) split into 2 patches
        // to keep road at col11/row12 (x=704-768, y=768-832) open
        // — that road is the only path to PythonGarden
        {'x': 704, 'y': 704, 'w': 128, 'h': 64},  // Tower top (row 11 only)
        {'x': 768, 'y': 768, 'w': 64,  'h': 64},  // Tower right (col12, row12)
      ];
    }
    return []; // village2 uses its own object layer
  }
}