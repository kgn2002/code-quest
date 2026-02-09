import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'player_component.dart';
import 'town_map.dart';
import 'package:flame/events.dart';

// --- 1. THE UI WIDGET (PRESENTATION TIER) ---
class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late Future<Map<String, dynamic>> _gameDataFuture;

  @override
  void initState() {
    super.initState();
    _gameDataFuture = _fetchStudentProfile();
  }

  Future<Map<String, dynamic>> _fetchStudentProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
      return {'username': 'Hero', 'total_xp': 0, 'completed_quests': []};
    }
  }

  // Inside _GameViewState in lib/game_view.dart
  Future<void> _updateXP(int points, String questId, CodeQuestGame game) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Update the local game engine state first
      game.markQuestAsComplete(questId);

      // 2. Fetch latest profile to ensure we are adding to the real current total
      final currentProfile = await _fetchStudentProfile();
      int currentXp = currentProfile['total_xp'] ?? 0;
      List<dynamic> completed = currentProfile['completed_quests'] ?? [];

      if (!completed.contains(questId)) {
        // 3. Update Supabase
        await Supabase.instance.client.from('profiles').update({
          'total_xp': currentXp + points,
          'completed_quests': [...completed, questId],
        }).eq('id', userId);

        // 4. CRITICAL: Re-assign the Future and call setState to force HUD update
        setState(() {
          _gameDataFuture = _fetchStudentProfile();
        });

        debugPrint("XP Updated Successfully to ${currentXp + points}");
      }
    } catch (e) {
      debugPrint("Database Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data ?? {'username': 'Hero', 'total_xp': 0, 'completed_quests': []};

          return Stack(
            children: [
              GameWidget(
                game: CodeQuestGame(completedQuests: List<String>.from(profile['completed_quests'] ?? [])),
                overlayBuilderMap: {
                  'QuestMenu': (context, game) {
                    final questGame = game as CodeQuestGame;
                    final questId = questGame.player.activeQuest ?? '';

                    String task = "Complete the task:";
                    String expected = "";

                    if (questId == 'PythonHouse') {
                      task = "Sentence: Print Hello World";
                      expected = "print('Hello World')";
                    } else if (questId == 'JavaTable') {
                      task = "Java: int x = 5;";
                      expected = "int x = 5;";
                    }

                    return CodeSandboxWidget(
                      task: task,
                      expected: expected,
                      onSuccess: () => _updateXP(50, questId, questGame),
                      onClose: () => questGame.resumeAndRemoveOverlay('QuestMenu'),
                    );
                  },
                },
              ),

              // HUD Layer with Progress Bar
              Positioned(
                top: 50,
                left: 20,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hero: ${profile['username']}",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // XP PROGRESS BAR
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: // HUD inside GameView
                        LinearProgressIndicator(
                          // The 'value' must be between 0.0 and 1.0
                          value: (profile['total_xp'] % 100) / 100.0,
                          backgroundColor: Colors.grey[900],
                          color: Colors.greenAccent,
                          minHeight: 10,
                        )
                      ),
                      const SizedBox(height: 6),
                      Text("XP: ${profile['total_xp']}",
                          style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- 2. THE RPG ENGINE (LOGIC TIER) ---
class CodeQuestGame extends FlameGame with DragCallbacks, HasCollisionDetection {
  late final JoystickComponent joystick;
  late final Player player;
  late final TownMap town;
  List<String> completedQuests;

  CodeQuestGame({required this.completedQuests});

  @override
  Future<void> onLoad() async {
    town = TownMap();
    await add(town);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.white54),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.black38),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);

    player = Player(joystick);
    await add(player);
  }

  // FIX: These methods must be INSIDE the class curly braces
  void markQuestAsComplete(String questId) {
    if (!completedQuests.contains(questId)) {
      completedQuests.add(questId);
    }
  }

  void resumeAndRemoveOverlay(String name) {
    overlays.remove(name);
    resumeEngine();
  }
}

// --- 3. THE SANDBOX COMPONENT ---
class CodeSandboxWidget extends StatefulWidget {
  final String task;
  final String expected;
  final VoidCallback onSuccess;
  final VoidCallback onClose;

  const CodeSandboxWidget({
    super.key,
    required this.task,
    required this.expected,
    required this.onSuccess,
    required this.onClose,
  });

  @override
  State<CodeSandboxWidget> createState() => _CodeSandboxWidgetState();
}

class _CodeSandboxWidgetState extends State<CodeSandboxWidget> {
  final TextEditingController _controller = TextEditingController();
  String _feedback = "";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.task, style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: _controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  fillColor: Colors.black,
                  filled: true,
                  hintText: "// Enter exact sentence...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Text(_feedback, style: TextStyle(color: _feedback == "CORRECT!" ? Colors.green : Colors.red)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: widget.onClose, child: const Text("Exit", style: TextStyle(color: Colors.white))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_controller.text.trim() == widget.expected) {
                        setState(() => _feedback = "CORRECT!");
                        widget.onSuccess();
                        await Future.delayed(const Duration(milliseconds: 600));
                        widget.onClose();
                      } else {
                        setState(() => _feedback = "Try again!");
                      }
                    },
                    child: const Text("Run"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}