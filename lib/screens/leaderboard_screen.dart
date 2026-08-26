import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  GameMode? _selectedMode;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final name = StorageService.getPlayerName();

      if (name == 'Player') {
        _showNameDialog();
      }
    });
  }

  List<LeaderboardEntry> _filteredEntries(List<LeaderboardEntry> entries) {
    if (_selectedMode == null) {
      return entries;
    }

    return entries.where((entry) => entry.mode == _selectedMode).toList();
  }

  String get _title {
    if (_selectedMode == null) {
      return "All Modes";
    }

    return "${GameConstants.modeEmoji(_selectedMode!)} ${GameConstants.modeName(_selectedMode!)}";
  }

  Future<void> _showNameDialog() async {
    final controller = TextEditingController(
      text: StorageService.getPlayerName() == 'Player'
          ? ''
          : StorageService.getPlayerName(),
    );

    final savedName = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Choose your name",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLength: 16,
            autofocus: false,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterStyle: TextStyle(
                color: Colors.grey.shade500,
              ),
              hintText: "SpeedyTapper",
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: Text(
                "Later",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (savedName != null) {
      await StorageService.setPlayerName(savedName);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {});
    }

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = StorageService.getLeaderboardEntries();
    final entries = _filteredEntries(allEntries);
    final playerName = StorageService.getPlayerName();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          "Leaderboard",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Change name",
            icon: const Icon(Icons.person),
            onPressed: _showNameDialog,
          ),
          IconButton(
            tooltip: "Clear your scores",
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await StorageService.clearLeaderboard();

              if (!mounted) return;

              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Playing as $playerName",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showNameDialog,
                    child: Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildFilterChip(
                  label: "All",
                  emoji: "🏆",
                  selected: _selectedMode == null,
                  onTap: () {
                    setState(() {
                      _selectedMode = null;
                    });
                  },
                ),
                ...GameMode.values.map((mode) {
                  return _buildFilterChip(
                    label: GameConstants.modeName(mode),
                    emoji: GameConstants.modeEmoji(mode),
                    selected: _selectedMode == mode,
                    onTap: () {
                      setState(() {
                        _selectedMode = mode;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  "${entries.length} scores",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final placement = index + 1;

                Color placementColor = Colors.white;

                if (placement == 1) placementColor = Colors.amber;
                if (placement == 2) placementColor = Colors.grey.shade300;
                if (placement == 3) {
                  placementColor = Colors.brown.shade300;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: placement <= 3
                        ? Border.all(
                      color: placementColor.withOpacity(0.7),
                      width: 1.5,
                    )
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: Text(
                          "#$placement",
                          style: TextStyle(
                            color: placementColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    entry.playerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (entry.isBot) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      "CPU",
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${GameConstants.modeEmoji(entry.mode)} ${GameConstants.modeName(entry.mode)} • ${entry.rank}",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.accuracyText,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${entry.score}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? Colors.white : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}