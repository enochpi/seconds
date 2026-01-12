import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../utils/constants.dart';

class ModeSelector extends StatelessWidget {
  final List<GameModeInfo> modes;
  final GameMode selectedMode;
  final Function(GameMode) onModeChanged;
  final VoidCallback? onUnlockAnimation;

  const ModeSelector({
    Key? key,
    required this.modes,
    required this.selectedMode,
    required this.onModeChanged,
    this.onUnlockAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: modes.map((mode) => Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            child: _buildModeCard(mode),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildModeCard(GameModeInfo mode) {
    bool isSelected = mode.mode == selectedMode;
    bool isLocked = !mode.isUnlocked;

    return GestureDetector(
      onTap: () {
        if (mode.isUnlocked) {
          onModeChanged(mode.mode);
        } else if (onUnlockAnimation != null) {
          onUnlockAnimation!();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isLocked
              ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
              : isSelected
              ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])
              : LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLocked ? Icons.lock :
                  mode.mode == GameMode.free ? Icons.play_arrow : Icons.precision_manufacturing,
                  color: isLocked ? Colors.grey.shade600 :
                  isSelected ? Colors.white : Colors.blue.shade700,
                  size: 24,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    mode.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? Colors.grey.shade600 :
                      isSelected ? Colors.white : Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              isLocked && mode.unlockRequirement != null
                  ? "Unlock: ${mode.unlockRequirement}+ pts"
                  : mode.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isLocked ? Colors.grey.shade600 :
                isSelected ? Colors.white70 : Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}