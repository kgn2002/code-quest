import 'package:codequest/town_map.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'game_view.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<CodeQuestGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  double speed = 200.0;
  Vector2 previousPosition = Vector2.zero();
  bool _isTransitioning = false;
  double _questCooldown = 0;

  final Map<int, Map<String, Vector2>> _allQuestLocations = {
    0: {
      'PythonHouse':   Vector2(320,  1088),
      'PythonTable':   Vector2(576,  384),
      'PythonLibrary': Vector2(96,   416),
      'PythonGarden':  Vector2(896,  128),
      'PythonCave':    Vector2(1152, 1088),
    },
    1: {
      'TreasureBox':  Vector2(192,  64),
      'GoblinHouse':  Vector2(1024, 512),
      'SnowToy':      Vector2(1216, 1216),
      'Computer':     Vector2(576,  1152),
      'Coins':        Vector2(128,  1216),
      'PondBuilding': Vector2(704,  128),
    },
  };

  static const double _gateX             = 1152;
  static const double _gateY             = 768;
  static const double _gateGuardX        = 986;
  static const double _returnX           = 64;
  static const double _returnY           = 576;
  static const double _returnGuardX      = 125;
  static const double _gateTriggerRadius = 100;

  int currentMap = 0;
  late Map<String, Vector2> questLocations;
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
          spriteSheet.width / 6.0,
          spriteSheet.height.toDouble(),
        ),
      ),
    );
    position = Vector2(150, 500);
    questLocations = Map.from(_allQuestLocations[0]!);
    add(RectangleHitbox(
      size: Vector2(50, 50),
      position: Vector2(23, 7),
    )..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    previousPosition = position.clone();
    super.update(dt);

    if (_questCooldown > 0) _questCooldown -= dt;
    if (_lockedMessageCooldown > 0) _lockedMessageCooldown -= dt;

    if (!joystick.delta.isZero()) {
      final Vector2 movement = joystick.relativeDelta * speed * dt;

      if (joystick.relativeDelta.x < 0 && scale.x > 0) {
        flipHorizontallyAroundCenter();
      } else if (joystick.relativeDelta.x > 0 && scale.x < 0) {
        flipHorizontallyAroundCenter();
      }

      final mapSize = Vector2(1280, 1280);
      final double maxScrollX = -(mapSize.x - game.size.x);
      final double maxScrollY = -(mapSize.y - game.size.y);

      final Vector2 potentialMapPos = game.town.position - movement;
      game.town.position.x = potentialMapPos.x.clamp(maxScrollX, 0.0);
      game.town.position.y = potentialMapPos.y.clamp(maxScrollY, 0.0);

      if (potentialMapPos.x > 0 || potentialMapPos.x < maxScrollX) {
        position.x += movement.x;
      }
      if (potentialMapPos.y > 0 || potentialMapPos.y < maxScrollY) {
        position.y += movement.y;
      }

      final double halfW = size.x / 2;
      final double halfH = size.y / 2;
      position.x = position.x.clamp(halfW, game.size.x - halfW);
      position.y = position.y.clamp(halfH, game.size.y - halfH);

      playing = true;

      if (!_isTransitioning) {
        _checkQuestProximity();
      }
    } else {
      playing = false;
    }

    if (!_isTransitioning) {
      _checkGateProximity();
    }

    priority = position.y.toInt();
  }

  static const List<String> _map1QuestIds = [
    'PythonHouse', 'PythonTable', 'PythonLibrary', 'PythonGarden', 'PythonCave',
  ];

  bool get _allMap1QuestsDone =>
      _map1QuestIds.every((q) => game.completedQuests.contains(q));

  void _checkGateProximity() {
    final Vector2 p = position - game.town.position;

    if (currentMap == 0) {
      if (!_allMap1QuestsDone) {
        if (p.x > _gateGuardX &&
            p.distanceTo(Vector2(_gateX, _gateY)) < _gateTriggerRadius) {
          _showGateLockedMessage();
        }
        return;
      }
      if (p.x > _gateGuardX) {
        if (p.distanceTo(Vector2(_gateX, _gateY)) < _gateTriggerRadius) {
          debugPrint('🚪 Gate triggered');
          _switchToMap(1);
        }
      }
    } else if (currentMap == 1) {
      if (p.x < _returnGuardX) {
        if (p.distanceTo(Vector2(_returnX, _returnY)) < _gateTriggerRadius) {
          debugPrint('🚪 Return gate triggered');
          _switchToMap(0);
        }
      }
    }
  }

  double _lockedMessageCooldown = 0;

  void _showGateLockedMessage() {
    if (_lockedMessageCooldown > 0) return;
    _lockedMessageCooldown = 3.0;
    game.overlays.add('GateLocked');
    Future.delayed(const Duration(seconds: 2), () {
      game.overlays.remove('GateLocked');
    });
  }

  void onQuestCompleted() {
    _questCooldown = 2.0;
  }

  void _checkQuestProximity() {
    if (_questCooldown > 0) return;

    final Vector2 p = position - game.town.position;

    questLocations.forEach((questName, location) {
      if (p.distanceTo(location) < 80) {
        // --- MASTER CHALLENGE GUARD ---
        // If the final task is already done, do not trigger the TreasureBox proximity at all.
        if (questName == 'TreasureBox' && game.completedQuests.contains('TreasureBox_final')) {
          return;
        }

        final bool isAlreadyCleared = game.completedQuests.contains(questName);

        final List<String> map2Others = [
          'GoblinHouse', 'SnowToy', 'Computer', 'Coins', 'PondBuilding',
        ];
        final bool allMap2Done = map2Others.every((q) => game.completedQuests.contains(q));

        final bool isTreasureBoxFinalPending =
            questName == 'TreasureBox' &&
                isAlreadyCleared &&
                allMap2Done &&
                !game.completedQuests.contains('TreasureBox_final');

        final bool shouldOpen =
            (!isAlreadyCleared || isTreasureBoxFinalPending) &&
                !game.overlays.isActive('QuestMenu');

        if (shouldOpen) {
          activeQuest = questName;
          game.overlays.add('QuestMenu');
          game.pauseEngine();
          debugPrint('📋 Quest triggered: $questName');
        }
      }
    });
  }

  Future<void> _switchToMap(int newMapIndex) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    debugPrint('🎮 Switching map: $currentMap → $newMapIndex');

    game.pauseEngine();
    currentMap = newMapIndex;
    questLocations = Map.from(_allQuestLocations[currentMap]!);

    if (newMapIndex == 1) {
      position = Vector2(150, 662);
      await game.town.switchMap('village2.tmx');
    } else {
      position = Vector2(950, 416);
      await game.town.switchMap('village1_map.tmx');
    }

    game.town.position = Vector2.zero();

    await Future.delayed(const Duration(milliseconds: 300));
    _isTransitioning = false;
    game.resumeEngine();
    debugPrint('✅ Now on map $currentMap');
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is PositionComponent && other.parent is TownMap) {
      final delta = position - previousPosition;
      if (delta.x.abs() > delta.y.abs()) {
        position.x = previousPosition.x;
      } else {
        position.y = previousPosition.y;
      }
      game.town.position -= delta * 0.5;
    }
  }
}