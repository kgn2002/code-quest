import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'game_view.dart';

class TownMap extends PositionComponent with HasGameRef<CodeQuestGame> {
  late TiledComponent tiledMap;

  @override
  Future<void> onLoad() async {
    // 1. Load the visual map
    tiledMap = await TiledComponent.load(
      'village1_map.tmx',
      Vector2.all(64),
    );
    add(tiledMap);

    // 2. Access the Object Layer named 'Collisions'
    final objectLayer = tiledMap.tileMap.getLayer<ObjectGroup>('Collisions');

    if (objectLayer != null) {
      for (final obj in objectLayer.objects) {
        // 3. Create a component for each shape drawn in Tiled
        final collisionObject = PositionComponent(
          position: Vector2(obj.x, obj.y),
          size: Vector2(obj.width, obj.height),
        );

        // 4. Add the hitbox (Set to passive for better performance)
        collisionObject.add(RectangleHitbox()..collisionType = CollisionType.active);

        add(collisionObject);
      }
    }
  }
}