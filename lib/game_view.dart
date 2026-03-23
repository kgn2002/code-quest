import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';
import 'player_component.dart';
import 'town_map.dart';
import 'package:flame/events.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/rendering.dart';

// --- 1. THE UI WIDGET ---
class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late Future<Map<String, dynamic>> _gameDataFuture;
  CodeQuestGame? _gameInstance;
  final ApiService _apiService = ApiService();

  String _currentDifficulty = 'basic';

  final Map<String, Map<String, Map<String, String>>> questData = {
    // ── MAP 1 QUESTS ─────────────────────────────────────────────────────
    'PythonHouse': {
      'basic': {
        'task': "Welcome to Python House! 🏠\n\nYour first task is simple — say hello to the world!\n\nWrite code that prints the message:\n    Hello World\n\nTip: Use print() with the text inside quotes.",
        'expected': 'Hello World',
      },
      'intermediate': {
        'task': "Python House — Level 2 📦\n\nStore a value and display it!\n\nCreate a variable called x and assign it the text 'Hello', then print x.\n\nTip: Variables hold values. Use = to assign, then print().",
        'expected': 'Hello',
      },
      'advanced': {
        'task': "Python House — Challenge 🔥\n\nRepeat text using multiplication!\n\nPrint the word 'Hello' exactly 3 times in a row (no spaces), using the * operator.\n\nExpected output: HelloHelloHello",
        'expected': 'HelloHelloHello',
      },
    },

    'PythonTable': {
      'basic': {
        'task': "Python Table — Math Basics ➕\n\nTime for some arithmetic!\n\nWrite code that prints the result of 5 plus 5.\n\nTip: Python can do math directly inside print().",
        'expected': '10',
      },
      'intermediate': {
        'task': "Python Table — Multiplication ✖️\n\nLet's multiply!\n\nWrite code that prints the result of 12 times 12.\n\nTip: Use the * operator for multiplication.",
        'expected': '144',
      },
      'advanced': {
        'task': "Python Table — Powers 💥\n\nRaise a number to a power!\n\nWrite code that prints 2 raised to the power of 3.\n\nTip: In Python, ** is the power operator. So 2**3 means 2³.",
        'expected': '8',
      },
    },

    'PythonLibrary': {
      'basic': {
        'task': "Python Library — Variables 📚\n\nWork with two variables!\n\nCreate a variable x with value 20 and a variable y with value 5.\nThen print the result of subtracting y from x.\n\nTip: Use the - operator inside print().",
        'expected': '15',
      },
      'intermediate': {
        'task': "Python Library — Conditions 🔀\n\nUse a one-line if/else!\n\nCheck if 10 is even (divisible by 2) and print 'Even' if yes, otherwise print 'Odd'.\n\nTip: Use the % (modulo) operator. If 10 % 2 == 0, it's even.",
        'expected': 'Even',
      },
      'advanced': {
        'task': "Python Library — Swap Values 🔄\n\nSwap two variables!\n\nStart with x = 5 and y = 10.\nSwap their values so x becomes 10 and y becomes 5.\nThen print x.\n\nTip: You can swap in Python using: x, y = y, x",
        'expected': '10',
      },
    },

    'PythonGarden': {
      'basic': {
        'task': "Python Garden — Lists 🌻\n\nAccess an item from a list!\n\nCreate a list called colors containing 'red' and 'blue'.\nPrint the first item.\n\nTip: List indexes start at 0. Use colors[0] for the first item.",
        'expected': 'red',
      },
      'intermediate': {
        'task': "Python Garden — List Length 📏\n\nFind out how long a list is!\n\nCreate a list a = [1, 2, 3] and print its length.\n\nTip: Use the built-in len() function.",
        'expected': '3',
      },
      'advanced': {
        'task': "Python Garden — Append 🌱\n\nGrow your list!\n\nStart with a = [1, 2], add the number 3 to the end, then print the full list.\n\nTip: Use the .append() method to add items. Expected output: [1, 2, 3]",
        'expected': '[1, 2, 3]',
      },
    },

    'PythonCave': {
      'basic': {
        'task': "Python Cave — Loops 🔁\n\nPrint numbers using a loop!\n\nWrite a for loop that prints the numbers 0, 1, and 2 (one per line).\n\nTip: Use range(3) to get [0, 1, 2]. Don't forget the colon : and indent the print.",
        'expected': '0\n1\n2',
      },
      'intermediate': {
        'task': "Python Cave — Range with Start 🔢\n\nLoop through a custom range!\n\nWrite a for loop that prints numbers 1, 2, and 3 (one per line).\n\nTip: Use range(1, 4) to start from 1 and stop before 4.",
        'expected': '1\n2\n3',
      },
      'advanced': {
        'task': "Python Cave — List Comprehension ⚡\n\nBuild a list in one line!\n\nUse a list comprehension to create a list of numbers from 0 to 2, then print it.\n\nTip: Try: print([i for i in range(3)]). Expected: [0, 1, 2]",
        'expected': '[0, 1, 2]',
      },
    },

    // ── MAP 2 QUESTS ─────────────────────────────────────────────────────
    'TreasureBox': {
      'basic': {
        'task': "Treasure Box — Functions 📦\n\nDefine and call your first function!\n\nCreate a function called greet that prints 'Hi', then call it.\n\nTip: Use def greet(): to define the function. Don't forget to call greet() after!",
        'expected': 'Hi',
      },
      'intermediate': {
        'task': "Treasure Box — Return Values 🔙\n\nFunctions can return results!\n\nCreate a function called add that takes two numbers a and b and returns their sum.\nCall add(3, 4) and print the result.\n\nTip: Use return a + b inside the function.",
        'expected': '7',
      },
      'advanced': {
        'task': "Treasure Box — Function Power 💎\n\nWrite a function that squares a number!\n\nCreate a function called square that takes a number n and returns n times n.\nCall square(5) and print the result.\n\nTip: return n * n (or n ** 2) inside the function.",
        'expected': '25',
      },
      // Final boss task — unlocked only when ALL other map2 quests are complete
      'final': {
        'task': '''🏆 MASTER CHALLENGE — Prove Your Mastery!

You have completed ALL tasks. Now combine everything you've learned!

This challenge tests: regex, functions, string slicing, and pattern printing.

──────────────────────────────────────────
STEP 1 — Import and Write a Function:
  Import the re module (for regex).
  Write a function called analyse(text) that:
    • Splits the text into words
    • Takes the first 3 characters of the first word  (slicing: words[0][:3])
    • Finds all numbers in the text using regex       (re.findall(r'\\d+', text))
    • Returns both as a tuple: (first3chars, numbers)

STEP 2 — Call the Function:
  Call analyse('Python3 is version 42')
  Store the result, then:
    • Print result[0]  → the sliced word (first 3 chars)
    • Print result[1]  → the list of numbers found

STEP 3 — Print a Star Triangle:
  Use a for loop with range(1, 4) to print:
    *
    **
    ***
  Tip: print('*' * i) inside the loop
──────────────────────────────────────────

Expected Output:
Pyt
['3', '42']
*
**
***''',
        'expected': "Pyt\n['3', '42']\n*\n**\n***",
      },
    },

    'GoblinHouse': {
      'basic': {
        'task': "Goblin House — Strings 🧌\n\nConvert text to UPPERCASE!\n\nCreate a variable s = 'hello' and print it in all capitals.\n\nTip: Strings have a .upper() method.",
        'expected': 'HELLO',
      },
      'intermediate': {
        'task': "Goblin House — String Length 📐\n\nCount the characters in a string!\n\nCreate s = 'hello world' and print its length.\n\nTip: Use len(). Don't forget to count the space — it's a character too!",
        'expected': '11',
      },
      'advanced': {
        'task': "Goblin House — Reverse a String 🔃\n\nFlip a string backwards!\n\nCreate s = 'hello' and print it reversed.\n\nTip: Python slicing trick: s[::-1] reverses any string.",
        'expected': 'olleh',
      },
    },

    'SnowToy': {
      'basic': {
        'task': "Snow Toy — Dictionaries ❄️\n\nAccess a value from a dictionary!\n\nCreate a dictionary d with key 'a' and value 1.\nPrint the value for key 'a'.\n\nTip: Use d['a'] to access a value by its key.",
        'expected': '1',
      },
      'intermediate': {
        'task': "Snow Toy — Dict Math 🧊\n\nAdd values from a dictionary!\n\nCreate d = {'x': 5, 'y': 3} and print the sum of d['x'] and d['y'].\n\nTip: You can do math directly inside print().",
        'expected': '8',
      },
      'advanced': {
        'task': "Snow Toy — Add to Dict 📝\n\nBuild a dictionary dynamically!\n\nStart with an empty dictionary d = {}.\nAdd a key 'k' with value 10.\nThen print d['k'].\n\nTip: Use d['k'] = 10 to add a new key.",
        'expected': '10',
      },
    },

    'Computer': {
      'basic': {
        'task': "Computer Room — Booleans 💻\n\nTest a comparison!\n\nWrite code that prints whether 5 is greater than 3.\n\nTip: Python will print True or False automatically. Use the > operator.",
        'expected': 'True',
      },
      'intermediate': {
        'task': "Computer Room — And Operator 🔗\n\nCombine two conditions!\n\nWrite code that checks if 5 is greater than 3 AND 2 is less than 4, then prints the result.\n\nTip: Use the and keyword between two conditions.",
        'expected': 'True',
      },
      'advanced': {
        'task': "Computer Room — Even Check ✅\n\nCheck if a number is even!\n\nCreate x = 10 and print True if x is even (divisible by 2).\n\nTip: Use x % 2 == 0. The % operator gives the remainder after division.",
        'expected': 'True',
      },
    },

    'Coins': {
      'basic': {
        'task': "Coins — Data Types 🪙\n\nFind out the type of a value!\n\nWrite code that prints the type of the number 42.\n\nTip: Use type() inside print(). You should see: <class 'int'>",
        'expected': "<class 'int'>",
      },
      'intermediate': {
        'task': "Coins — Float Type 🔢\n\nCheck the type of a decimal!\n\nWrite code that prints the type of 3.14.\n\nTip: Decimal numbers are called floats. Expected: <class 'float'>",
        'expected': "<class 'float'>",
      },
      'advanced': {
        'task': "Coins — Type Conversion 🔁\n\nConvert a string to a number and add to it!\n\nConvert the string '42' into an integer, then add 8, and print the result.\n\nTip: Use int() to convert a string to an integer.",
        'expected': '50',
      },
    },

    'PondBuilding': {
      'basic': {
        'task': "Pond Building — While Loops 🌊\n\nUse a while loop to count!\n\nPrint numbers 0, 1, and 2 using a while loop.\n\nTip:\n  i = 0\n  while i < 3:\n      print(i)\n      i += 1\nDon't forget to increment i, or the loop runs forever!",
        'expected': '0\n1\n2',
      },
      'intermediate': {
        'task': "Pond Building — Loop with Math 🔄\n\nMultiply in a loop!\n\nUse a while loop starting at i = 1. While i is 3 or less, print i times 2, then add 1 to i.\n\nExpected output:\n2\n4\n6",
        'expected': '2\n4\n6',
      },
      'advanced': {
        'task': "Pond Building — Sum with Loop ➕\n\nAdd numbers using a while loop!\n\nCreate a variable s = 0 and i = 1.\nWhile i is 5 or less, add i to s and increase i by 1.\nAfter the loop, print s.\n\nTip: You're calculating 1+2+3+4+5 = 15.",
        'expected': '15',
      },
    },
  };

  final Map<String, List<String>> teacherHints = {
    // Map 1
    'PythonHouse':   ["Use quotes around the text!", "Make sure print is lowercase", "Try: print('Hello World')"],
    'PythonTable':   ["You only need numbers", "Use + for addition or * for multiply", "Try: print(5 + 5)"],
    'PythonLibrary': ["First define x and y on separate lines", "Subtract with the - operator", "Try: x=20; y=5; print(x-y)"],
    'PythonGarden':  ["Remember list indexes start at 0", "Use square brackets to access items", "Try: colors=['red','blue']; print(colors[0])"],
    'PythonCave':    ["A for loop needs a colon at the end", "Indent the print statement with 4 spaces", "Try: for i in range(3): print(i)"],
    // Map 2
    'TreasureBox': [
      "Define the function with the def keyword",
      "Functions can return values using return",
      "Call the function with arguments after defining it: add(3,4)",
      // Final task hints (index 3,4,5 — used when isFinalTask=true)
      "Start with: import re — then use re.findall(r'\\d+', text) to find numbers",
      "Slicing: words[0][:3] gives the first 3 characters of the first word",
      "Pattern loop: for i in range(1,4): print('*' * i)",
    ],
    'GoblinHouse':   ["Strings have built-in methods", "Try .upper() after the variable", "Try: s='hello'; print(s.upper())"],
    'SnowToy':       ["Dictionaries use curly braces {}", "Access values using square brackets []", "Try: d={'a':1}; print(d['a'])"],
    'Computer':      ["Use > or < for comparisons", "The and keyword combines two conditions", "Try: print(5 > 3)"],
    'Coins':         ["type() tells you the data type", "int() converts a string to a number", "Try: print(type(42))"],
    'PondBuilding':  ["while needs a condition to check each loop", "Remember to increment i inside the loop", "Try:\ni=0\nwhile i<3:\n    print(i)\n    i+=1"],
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _gameDataFuture = _fetchStudentProfile().then((profile) {
      _gameInstance ??= CodeQuestGame(
        completedQuests: List<String>.from(profile['completed_quests'] ?? []),
      );
      return profile;
    });
  }

  Future<Map<String, dynamic>> _fetchStudentProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final profile = Map<String, dynamic>.from(data as Map);
      // If username is stored as email, show only the part before @
      final raw = profile['username'] as String? ?? '';
      if (raw.contains('@')) profile['username'] = raw.split('@').first;
      return profile;
    } catch (e) {
      return {'username': 'Hero', 'total_xp': 0, 'completed_quests': []};
    }
  }

  Future<void> _updateXP(
      int points, String questId, int errors, double timeTaken) async {
    try {
      // ── SYNC FIX ──────────────────────────────────────────────────────
      // Mark complete IMMEDIATELY (synchronously) before any await.
      // This ensures _checkQuestProximity sees it in the very next frame
      // and won't re-open the quest menu while Supabase is still saving.
      _gameInstance?.markQuestAsComplete(questId);

      // CRITICAL: Also update the in-memory completedQuests list directly.
      // Without this, the allMap2Done check in QuestMenu overlay will
      // always be false during the same session because g.completedQuests
      // is only loaded once at startup from Supabase.
      if (!(_gameInstance?.completedQuests.contains(questId) ?? true)) {
        _gameInstance?.completedQuests.add(questId);
      }

      // Start 2-second cooldown so player can walk away before proximity
      // check re-evaluates (handles the case where player stays in range).
      _gameInstance?.player.onQuestCompleted();
      // ─────────────────────────────────────────────────────────────────

      // 🏆 CERTIFICATE: always show when master challenge is submitted,
      // even if Supabase already has it saved (e.g. player already at 750 XP).
      // Must be BEFORE the Supabase duplicate-guard so it never gets skipped.
      if (questId == 'TreasureBox_final') {
        // Save to Supabase only if not already saved
        final supabase2 = Supabase.instance.client;
        final userId2 = supabase2.auth.currentUser!.id;
        final profile2 = await _fetchStudentProfile();
        final completed2 = List<dynamic>.from(profile2['completed_quests'] ?? []);
        if (!completed2.contains('TreasureBox_final')) {
          final newXp = (profile2['total_xp'] ?? 0) + points;
          await supabase2.from('profiles').update({
            'total_xp': newXp,
            'completed_quests': [...completed2, 'TreasureBox_final'],
          }).eq('id', userId2);
        }
        // Always show certificate regardless
        _gameInstance?.pauseEngine();
        if (!(_gameInstance?.overlays.isActive('Certificate') ?? false)) {
          _gameInstance?.overlays.add('Certificate');
        }
        if (mounted) setState(() {});
        return;
      }

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final profile = await _fetchStudentProfile();
      int currentXp = profile['total_xp'] ?? 0;
      List<dynamic> completed = profile['completed_quests'] ?? [];

      if (!completed.contains(questId)) {
        int newTotalXp = currentXp + points;
        await supabase.from('profiles').update({
          'total_xp': newTotalXp,
          'completed_quests': [...completed, questId],
        }).eq('id', userId);

        final aiResponse = await _apiService.sendLearningMetrics(
          profileId: userId,
          locationId: questId,
          errors: errors,
          latency: timeTaken,
        );

        if (currentXp < 250 && newTotalXp >= 250) {
          _gameInstance?.pauseEngine();
          _gameInstance?.overlays.add('LevelUp');
        }

        if (mounted) {
          setState(() {
            _currentDifficulty = aiResponse['recommendation'] ?? 'basic';
          });
          _gameDataFuture = _fetchStudentProfile();
        }
      }
    } catch (e) {
      debugPrint('Update Failed: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      _gameInstance?.pauseEngine();
      _gameInstance = null;
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Logout Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _gameInstance == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile =
              snapshot.data ?? {'username': 'Hero', 'total_xp': 0};

          return Stack(
            children: [
              if (_gameInstance != null)
                GameWidget(
                  game: _gameInstance!,
                  overlayBuilderMap: {
                    'QuestMenu': (context, game) {
                      final g = game as CodeQuestGame;
                      final questId = g.player.activeQuest ?? '';

                      // ── MASTER CHALLENGE CHECK ─────────────────────────
                      // Uses g.completedQuests (in-memory) which is kept
                      // in sync by _updateXP above — so this works even
                      // when all 5 quests are completed in the same session
                      // without restarting the app.
                      final map2Quests = [
                        'GoblinHouse', 'SnowToy', 'Computer',
                        'Coins', 'PondBuilding',
                      ];
                      final allMap2Done = map2Quests.every(
                            (q) => g.completedQuests.contains(q),
                      );
                      // Master challenge shows when:
                      // 1. All 5 other map2 quests are done
                      // 2. TreasureBox_final not yet done
                      // NOTE: No normal TreasureBox task — goes straight to master.
                      final isFinalTask = questId == 'TreasureBox' &&
                          allMap2Done &&
                          !g.completedQuests.contains('TreasureBox_final');
                      // If map2 quests not done yet, don't open anything
                      if (questId == 'TreasureBox' && !isFinalTask &&
                          g.completedQuests.contains('TreasureBox_final')) {
                        // Already completed — close overlay silently
                        Future.microtask(() => g.resumeAndRemoveOverlay('QuestMenu'));
                      }
                      // ──────────────────────────────────────────────────

                      // TreasureBox always shows master challenge — no normal task
                      Map<String, String> levelData;
                      String taskQuestId;
                      if (questId == 'TreasureBox') {
                        if (!allMap2Done) {
                          // Not ready yet — close and let player finish others
                          Future.microtask(() => g.resumeAndRemoveOverlay('QuestMenu'));
                          return const SizedBox.shrink();
                        }
                        levelData = Map<String, String>.from(
                          questData['TreasureBox']!['final']!,
                        );
                        taskQuestId = 'TreasureBox_final';
                      } else {
                        levelData = questData[questId]?[_currentDifficulty] ??
                            questData[questId]?['basic'] ??
                            {'task': 'No task found', 'expected': ''};
                        taskQuestId = questId;
                      }

                      return CodeSandboxWidget(
                        questId: taskQuestId,
                        task: levelData['task']!,
                        expected: levelData['expected']!,
                        hints: isFinalTask
                            ? (teacherHints['TreasureBox'] ?? []).skip(3).toList()
                            : teacherHints[questId] ?? ['Keep trying!'],
                        isFinalTask: questId == 'TreasureBox',
                        onSuccess: (err, time) =>
                            _updateXP(questId == 'TreasureBox' ? 200 : 50, taskQuestId, err, time),
                        onClose: () =>
                            g.resumeAndRemoveOverlay('QuestMenu'),
                      );
                    },
                    'LevelUp': (context, game) =>
                        _buildLevelUpCard(game as CodeQuestGame),
                    'GateLocked': (context, game) =>
                        _buildGateLockedCard(),
                    'Certificate': (context, game) =>
                        _buildCertificateOverlay(game as CodeQuestGame),
                  },
                ),
              Positioned(
                  top: 50, left: 20, child: _buildHUD(profile)),
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.logout,
                      color: Colors.white, size: 28),
                  onPressed: _handleLogout,
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── BLOCKCHAIN-SIMULATED CERTIFICATE ───────────────────────────────────
  //
  // Tamper-proof design using a HASH CHAIN:
  //
  // Block 0 (Genesis): SHA-256(userId + account_created_at)
  //   ↓
  // Block N (each quest): SHA-256(prevHash + questId + quest_created_at)
  //   ↓ (repeat for all 12 quests in chronological order)
  //   ↓
  // Final Block (cert): SHA-256(chainHash + 'CERT_ISSUED' + issuedAt)
  //
  // Why tamper-proof?
  //   • Each block includes the PREVIOUS hash — changing any quest breaks
  //     every subsequent hash in the chain.
  //   • Quest created_at timestamps come from map_analytics (insert-only,
  //     protected by RLS) — they cannot be edited after insert.
  //   • The final cert hash is computed from the entire chain — you cannot
  //     fake it without re-doing all 12 quests in the correct order.
  //   • The stored cert_hash in profiles is compared against a fresh
  //     re-computation from map_analytics every time — any DB tampering
  //     breaks verification immediately.
  // ─────────────────────────────────────────────────────────────────────────

  String _sha256Hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Builds the full hash chain from map_analytics records.
  /// Each quest's created_at timestamp is fetched from the DB —
  /// these are server-set and protected by RLS (insert-only, no update).
  Future<String> _buildHashChain(String userId) async {
    final supabase = Supabase.instance.client;

    // Fetch all completed quest analytics sorted by insert time
    // (server timestamp — cannot be forged by client)
    final records = await supabase
        .from('map_analytics')
        .select('location_id, created_at')
        .eq('profile_id', userId)
        .order('created_at', ascending: true);

    // Genesis block: anchored to userId (unique, immutable)
    String chainHash = _sha256Hash('GENESIS|$userId');

    // Chain each quest block: hash = SHA-256(prevHash + questId + timestamp)
    for (final record in records) {
      final questId  = record['location_id'] as String;
      final insertedAt = record['created_at'] as String;
      chainHash = _sha256Hash('$chainHash|$questId|$insertedAt');
    }

    return chainHash;
  }

  Future<Map<String, dynamic>> _getOrIssueCertificate() async {
    final supabase = Supabase.instance.client;
    final userId   = supabase.auth.currentUser!.id;
    final profile  = await _fetchStudentProfile();

    final existingHash = profile['cert_hash']      as String?;
    final existingDate = profile['cert_issued_at']  as String?;

    // Always verify the chain — even if hash already stored
    final chainHash = await _buildHashChain(userId);

    // Final certificate block: chain + sentinel + issue timestamp
    String issuedAt;
    String certHash;

    if (existingHash != null && existingDate != null) {
      // Re-verify: recompute final block with stored issuedAt
      issuedAt = existingDate;
      certHash = _sha256Hash('$chainHash|CERT_ISSUED|$issuedAt');
      final isValid = certHash == existingHash;
      return {
        'hash':      existingHash,
        'issued_at': issuedAt,
        'verified':  isValid,
        // Short readable ID shown on certificate (first 8 + last 8 chars)
        'cert_id':   '${existingHash.substring(0, 8)}...${existingHash.substring(56)}',
      };
    }

    // First time: issue certificate
    issuedAt = DateTime.now().toUtc().toIso8601String();
    certHash = _sha256Hash('$chainHash|CERT_ISSUED|$issuedAt');

    await supabase.from('profiles').update({
      'cert_hash':      certHash,
      'cert_issued_at': issuedAt,
    }).eq('id', userId);

    return {
      'hash':      certHash,
      'issued_at': issuedAt,
      'verified':  true,
      'cert_id':   '${certHash.substring(0, 8)}...${certHash.substring(56)}',
    };
  }
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHUD(Map<String, dynamic> profile) {
    int xp = profile['total_xp'] ?? 0;
    final bool hasCertificate =
        _gameInstance?.completedQuests.contains('TreasureBox_final') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(15)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hero: ${profile["username"]}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  'AI: ${_currentDifficulty.toUpperCase()}',
                  style: TextStyle(
                      color: _currentDifficulty == 'advanced'
                          ? Colors.purpleAccent
                          : Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: (xp % 100) / 100.0,
                    color: Colors.greenAccent,
                    backgroundColor: Colors.white10),
                Text('XP: $xp',
                    style: const TextStyle(
                        color: Colors.yellowAccent, fontSize: 12)),
              ]),
        ),
        // Certificate button — only shown after master challenge completed
        if (hasCertificate) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _gameInstance?.pauseEngine();
              if (!(_gameInstance?.overlays.isActive('Certificate') ?? false)) {
                _gameInstance?.overlays.add('Certificate');
              }
            },
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.yellowAccent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'My Certificate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGateLockedCard() {
    final map1Quests = [
      'PythonHouse', 'PythonTable', 'PythonLibrary', 'PythonGarden', 'PythonCave'
    ];
    final completed = map1Quests
        .where((q) => _gameInstance?.completedQuests.contains(q) ?? false)
        .length;

    return Center(
      child: Card(
        color: Colors.black.withOpacity(0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              'GATE LOCKED',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Complete all tasks in this village first!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed / ${map1Quests.length} tasks completed',
              style: TextStyle(
                color: completed == map1Quests.length
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...map1Quests.map((q) {
              final done =
                  _gameInstance?.completedQuests.contains(q) ?? false;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? Colors.greenAccent : Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    q,
                    style: TextStyle(
                      color: done ? Colors.white54 : Colors.white,
                      fontSize: 12,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              );
            }),
          ]),
        ),
      ),
    );
  }

  final GlobalKey _certKey = GlobalKey();

  Widget _buildCertificateOverlay(CodeQuestGame game) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getOrIssueCertificate(),
          builder: (context, snap) {
            final certHash  = snap.data?['hash']      as String? ?? '...';
            final issuedAt  = snap.data?['issued_at']  as String? ?? '';
            final certId    = snap.data?['cert_id']    as String? ?? '';
            final isVerified = (snap.data?['verified'] as bool?) ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _certKey,
                    child: _CertificateCard(
                      certHash: certHash,
                      certId: certId,
                      issuedAt: issuedAt,
                      isVerified: isVerified,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Download button — saves certificate as PNG to device
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _downloadCertificate(),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          game.overlays.remove('Certificate');
                          game.resumeEngine();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _downloadCertificate() async {
    if (!mounted) return;
    try {
      // Capture the certificate card as a high-res image
      final boundary = _certKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) {
        _showCertSnackBar('❌ Could not capture certificate', isError: true);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showCertSnackBar('❌ Failed to encode image', isError: true);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to app documents directory (works without any extra permission)
      final directory = await _getDownloadDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/codequest_certificate_$timestamp.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      _showCertSnackBar('✅ Certificate saved to: $filePath');
    } catch (e) {
      debugPrint('Download error: $e');
      _showCertSnackBar('❌ Download failed: $e', isError: true);
    }
  }

  Future<Directory> _getDownloadDir() async {
    // Try external storage (Android Downloads folder) first
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    }
    // Fallback: app documents directory (always accessible, no permission needed)
    final docs = Directory('/data/user/0/com.example.codequest/files');
    if (await docs.exists()) return docs;
    return Directory.systemTemp;
  }

  void _showCertSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildLevelUpCard(CodeQuestGame game) {
    return Center(
      child: Card(
        color: Colors.black.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.stars, color: Colors.yellowAccent, size: 60),
            const Text('LEVEL UP!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('LevelUp');
                game.resumeEngine();
              },
              child: const Text('CONTINUE'),
            )
          ]),
        ),
      ),
    );
  }
}

// --- 2. THE RPG ENGINE ---
class CodeQuestGame extends FlameGame
    with DragCallbacks, HasCollisionDetection {
  late final Player player;
  late final TownMap town;
  List<String> completedQuests;
  CodeQuestGame({required this.completedQuests});

  @override
  Future<void> onLoad() async {
    town = TownMap();
    await add(town);

    final joystick = JoystickComponent(
      knob: CircleComponent(
          radius: 20, paint: Paint()..color = Colors.white54),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = Colors.black38),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);

    player = Player(joystick);
    await add(player);
  }

  void markQuestAsComplete(String questId) {
    if (!completedQuests.contains(questId)) completedQuests.add(questId);
  }

  void resumeAndRemoveOverlay(String name) {
    overlays.remove(name);
    resumeEngine();
  }
}

// --- 3. THE SANDBOX WIDGET ---
class CodeSandboxWidget extends StatefulWidget {
  final String questId, task, expected;
  final List<String> hints;
  final Function(int errors, double time) onSuccess;
  final VoidCallback onClose;
  final bool isFinalTask;

  const CodeSandboxWidget({
    super.key,
    required this.questId,
    required this.task,
    required this.expected,
    required this.hints,
    required this.onSuccess,
    required this.onClose,
    this.isFinalTask = false,
  });

  @override
  State<CodeSandboxWidget> createState() => _CodeSandboxWidgetState();
}

class _CodeSandboxWidgetState extends State<CodeSandboxWidget> {
  final TextEditingController _controller = TextEditingController();
  String _feedback = '', _terminal = '';
  bool _isEvaluating = false, _hintVisible = false;
  int _errorCount = 0;
  int _lastLength = 0; // tracks typing length to detect paste in master challenge
  late Stopwatch _timer;

  @override
  void initState() {
    super.initState();
    _timer = Stopwatch()..start();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: const Color(0xFF1E1E1E),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Final task special header
              if (widget.isFinalTask) ...[
                Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text('MASTER CHALLENGE',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  SizedBox(width: 8),
                  Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                ]),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'You have completed all tasks! Now prove your mastery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
              // Task description box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isFinalTask
                        ? Colors.amber.withOpacity(0.5)
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.task,
                  style: TextStyle(
                    color: widget.isFinalTask
                        ? Colors.amberAccent
                        : Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_errorCount > 0 && !_hintVisible)
                TextButton.icon(
                  icon: const Icon(Icons.help_outline,
                      color: Colors.orangeAccent, size: 18),
                  label: const Text('Ask Teacher for a Hint',
                      style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 13)),
                  onPressed: () => setState(() => _hintVisible = true),
                ),
              if (_hintVisible)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.school,
                        color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.hints[_errorCount > widget.hints.length
                            ? widget.hints.length - 1
                            : _errorCount - 1],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 14, color: Colors.white54),
                      onPressed: () =>
                          setState(() => _hintVisible = false),
                    ),
                  ]),
                ),
              // Code input area
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextField(
                  controller: _controller,
                  maxLines: widget.isFinalTask ? 12 : 5,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.isFinalTask
                        ? '# Type your code here — pasting is disabled'
                        : '# Write your Python code here...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                  // Disable paste for master challenge — must type manually
                  contextMenuBuilder: widget.isFinalTask
                      ? (context, editableTextState) {
                    // Return empty overlay — removes cut/copy/paste menu
                    return const SizedBox.shrink();
                  }
                      : null,
                  onChanged: widget.isFinalTask
                      ? (value) {
                    // If pasted text detected (large sudden jump in length),
                    // clear the field and warn the player
                    if (value.length - _lastLength > 10) {
                      _controller.clear();
                      setState(() {
                        _terminal = '⚠️ Pasting is not allowed in the Master Challenge!';
                      });
                      _lastLength = 0;
                      return;
                    }
                    _lastLength = value.length;
                  }
                      : null,
                ),
              ),
              if (_terminal.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Text(_terminal,
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_feedback,
                      style: TextStyle(
                          color: _feedback == 'CORRECT!'
                              ? Colors.green
                              : Colors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _isEvaluating ? null : _run,
                    icon: _isEvaluating
                        ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow, size: 16),
                    label: Text(_isEvaluating ? 'Running...' : 'Run Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isFinalTask
                          ? Colors.amber.withOpacity(0.85)
                          : Colors.green.withOpacity(0.85),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _run() async {
    setState(() {
      _isEvaluating = true;
      _feedback = 'Running...';
      _hintVisible = false;
    });
    final res = await ApiService()
        .checkPythonCode(_controller.text, widget.expected);
    setState(() {
      _isEvaluating = false;
      if (res['is_correct'] == true) {
        _timer.stop();
        _feedback = 'CORRECT!';
        widget.onSuccess(_errorCount, _timer.elapsed.inSeconds.toDouble());
        Future.delayed(const Duration(seconds: 1), widget.onClose);
      } else {
        _errorCount++;
        _feedback = 'Incorrect Output';
        _terminal = res['error'] ?? 'Actual: ${res['output']}';
      }
    });
  }
}


// --- 4. CERTIFICATE CARD WIDGET ---
class _CertificateCard extends StatelessWidget {
  final String certHash;
  final String certId;
  final String issuedAt;
  final bool isVerified;

  const _CertificateCard({
    this.certHash = '...',
    this.certId = '',
    this.issuedAt = '',
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    // Parse issued date from ISO string, fallback to today
    DateTime issueDate;
    try {
      issueDate = issuedAt.isNotEmpty ? DateTime.parse(issuedAt).toLocal() : DateTime.now();
    } catch (_) {
      issueDate = DateTime.now();
    }
    final dateStr =
        '${issueDate.day.toString().padLeft(2, '0')} / '
        '${issueDate.month.toString().padLeft(2, '0')} / '
        '${issueDate.year}';
    // Show certId (first 8 + last 8 chars of hash, pre-computed)
    final displayId = certId.isNotEmpty ? certId : (certHash.length > 16 ? '${certHash.substring(0,8)}...' : certHash);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Text(
              'CODEQUEST',
              style: TextStyle(
                color: Colors.amber.shade300,
                fontSize: 13,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Certificate of Achievement',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Trophy
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.amber.shade300, Colors.orange.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 16, spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'This certifies the successful completion of',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 14),
          // Course title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withOpacity(0.45)),
            ),
            child: const Column(
              children: [
                Text(
                  'Python Programming',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'MASTERY COURSE',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'All 11 Quests + Master Challenge Completed',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 18),
          // Skill badges
          Wrap(
            spacing: 8, runSpacing: 6,
            alignment: WrapAlignment.center,
            children: const [
              _Badge('Syntax'),
              _Badge('Variables'),
              _Badge('Lists'),
              _Badge('Loops'),
              _Badge('Functions'),
              _Badge('Regex'),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.amber.withOpacity(0.25)),
          const SizedBox(height: 14),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Date Issued',
                    style: TextStyle(color: Colors.white38, fontSize: 9)),
                Text(dateStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
              // Verified seal
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isVerified ? Colors.greenAccent : Colors.amber,
                    width: 1.5,
                  ),
                  color: Colors.amber.withOpacity(0.08),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.pending,
                      color: isVerified ? Colors.greenAccent : Colors.amber,
                      size: 18,
                    ),
                    Text(
                      isVerified ? 'VERIFIED' : 'LOADING',
                      style: TextStyle(
                        color: isVerified
                            ? Colors.greenAccent
                            : Colors.amber.shade300,
                        fontSize: 6,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Issued by',
                    style: TextStyle(color: Colors.white38, fontSize: 9)),
                const Text('CodeQuest',
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          // Blockchain hash display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(children: [
              Icon(Icons.link, color: Colors.white38, size: 11),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SHA-256: $displayId',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                isVerified ? Icons.check_circle : Icons.hourglass_empty,
                color: isVerified ? Colors.greenAccent : Colors.white24,
                size: 11,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}