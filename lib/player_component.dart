import 'package:codequest/town_map.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import 'game_view.dart';

// Use HasGameRef<CodeQuestGame> so 'game' knows about 'town'
class Player extends SpriteAnimationComponent with HasGameRef<CodeQuestGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 200.0;
  Vector2 previousPosition = Vector2.zero();

  // --- SPRINT 3: QUEST TARGETS ---
  final Map<String, Vector2> questLocations = {
    'PythonHouse': Vector2(512, 320),
    'PythonTable': Vector2(384, 1152),
    'PythonLibrary': Vector2(64, 256),
  };

  String? activeQuest;

  Player(this.joystick) : super(size: Vector2(96, 64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final spriteSheet = await game.images.load('hero_walk.jpg');

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2(
            spriteSheet.width / 6.0, spriteSheet.height.toDouble()),
      ),
    );

    position = Vector2(150, 500);

    // Hitbox for physical interaction
    add(RectangleHitbox(
      size: Vector2(30, 30),
      position: Vector2(33, 30),
    ));
  }

// lib/player_component.dart
  @override
  void update(double dt) {
    previousPosition = position.clone();
    super.update(dt);

    if (!joystick.delta.isZero()) {
      final game = gameRef; // CodeQuestGame
      Vector2 movement = joystick.relativeDelta * speed * dt;

      // --- 1. HANDLE DIRECTIONAL FLIP FIRST ---
      // This works even if the map is stuck at a boundary
      if (joystick.relativeDelta.x < 0 && scale.x > 0) {
        flipHorizontallyAroundCenter();
      } else if (joystick.relativeDelta.x > 0 && scale.x < 0) {
        flipHorizontallyAroundCenter();
      }

      // --- 2. CALCULATE MAP BOUNDARIES ---
      double maxScrollX = -(1280 - game.size.x);
      double maxScrollY = -(1280 - game.size.y);

      // --- 3. APPLY MOVEMENT WITH CLAMPING ---
      Vector2 potentialMapPos = game.town.position - movement;

      game.town.position.x = potentialMapPos.x.clamp(maxScrollX, 0.0);
      game.town.position.y = potentialMapPos.y.clamp(maxScrollY, 0.0);

      // --- 4. OPTIONAL: HERO MOVES IF MAP IS STUCK ---
      // If the map can't move anymore, move the hero relative to the screen
      if (potentialMapPos.x > 0 || potentialMapPos.x < maxScrollX) {
        position.x += movement.x;
      }
      if (potentialMapPos.y > 0 || potentialMapPos.y < maxScrollY) {
        position.y += movement.y;
      }

      playing = true;
      _checkQuestProximity(); // Check for your Python/Java tasks
    } else {
      playing = false;
    }
    // Depth sorting for 2.5D perspective
    priority = position.y.toInt();
  }

// lib/player_component.dart
  // lib/player_component.dart
  void _checkQuestProximity() {
    // Real map position calculation
    Vector2 playerOnMap = position - game.town.position;

    questLocations.forEach((questName, location) {
      if (playerOnMap.distanceTo(location) < 70) {
        // Logic: Only show menu if quest is NOT in the completed list
        if (!game.completedQuests.contains(questName) &&
            !game.overlays.isActive('QuestMenu')) {
          activeQuest = questName;
          game.overlays.add('QuestMenu');
          game.pauseEngine(); // Stop the world for coding
        }
      }
    });
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Check if we hit an object that belongs to the TownMap
    if (other.parent is TownMap) {
      // Revert the hero to their previous position
      position = previousPosition;

      // Push the map back to prevent 'jittering' when scrolling
      Vector2 correction = joystick.relativeDelta * speed * 0.05;
      game.town.position.add(correction);
      add(RectangleHitbox(
        size: Vector2(30, 30), // Smaller than the sprite for better "feel"
        position: Vector2(33, 30),
      )..collisionType = CollisionType.active);
    }
  }
}