import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final GameService? gameService;

  const SettingsScreen({Key? key, this.gameService}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _hapticsEnabled;
  late String _playerName;

  @override
  void initState() {
    super.initState();

    _soundEnabled = StorageService.getSoundEnabled();
    _hapticsEnabled = StorageService.getHapticsEnabled();
    _playerName = StorageService.getPlayerName();
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: _playerName == 'Player' ? '' : _playerName,
    );
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final savedName = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Choose your name",
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLength: 16,
            autofocus: true,
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterStyle: TextStyle(color: Colors.grey.shade500),
              hintText: "SpeedyTapper",
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text(
                "Save",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (savedName == null) return;

    await StorageService.setPlayerName(savedName);

    if (!mounted) return;

    setState(() {
      _playerName = StorageService.getPlayerName();
    });
  }

  Future<void> _confirmResetData() async {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Reset all progress?",
            style: TextStyle(color: onSurface, fontWeight: FontWeight.w900),
          ),
          content: Text(
            "This clears your high score, achievements, personal bests, "
            "and leaderboard entries. Your name is kept. This can't be undone.",
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Reset",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (widget.gameService != null) {
      await widget.gameService!.clearAllData();
    } else {
      await StorageService.clearAllData();
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Progress reset.")),
    );
  }

  Widget _buildSectionLabel(String text) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          color: onSurface.withOpacity(0.5),
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: onSurface),
        title: Text(
          title,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13),
        ),
        value: value,
        activeColor: Colors.lightBlueAccent,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? onSurface),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor ?? onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSectionLabel("PLAYER"),
          _buildActionTile(
            icon: Icons.person,
            title: _playerName,
            subtitle: "Tap to change your leaderboard name",
            onTap: _editName,
          ),
          _buildSectionLabel("APPEARANCE"),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.instance.themeMode,
            builder: (context, mode, _) {
              return _buildSwitchTile(
                icon: Icons.dark_mode,
                title: "Dark Mode",
                subtitle: "Switch between light and dark theme",
                value: mode == ThemeMode.dark,
                onChanged: (value) async {
                  await ThemeService.instance.setDarkModeEnabled(value);
                },
              );
            },
          ),
          _buildSectionLabel("FEEDBACK"),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: "Sound Effects",
            subtitle: "Countdown ticks, tap feedback, high scores",
            value: _soundEnabled,
            onChanged: (value) async {
              await StorageService.setSoundEnabled(value);
              setState(() => _soundEnabled = value);
            },
          ),
          const SizedBox(height: 10),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: "Haptics",
            subtitle: "Vibration on tap and results",
            value: _hapticsEnabled,
            onChanged: (value) async {
              await StorageService.setHapticsEnabled(value);
              setState(() => _hapticsEnabled = value);
            },
          ),
          _buildSectionLabel("DATA"),
          _buildActionTile(
            icon: Icons.delete_forever,
            title: "Reset Progress",
            subtitle: "Clear scores, achievements, and leaderboard entries",
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: _confirmResetData,
          ),
          _buildSectionLabel("ABOUT"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "7 Seconds — Reaction Timer",
              style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
