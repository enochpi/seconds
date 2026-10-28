import 'package:flutter/material.dart';

import '../services/mystery_box_service.dart';
import '../services/profile_service.dart';
import '../services/season_service.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';
import 'share_cards.dart';

/// End-of-season celebration: the podium with the player's avatar on it,
/// their prize, and (for the top 3) a "Share Victory" story card.
class SeasonPodiumDialog extends StatefulWidget {
  final SeasonReward reward;

  const SeasonPodiumDialog({super.key, required this.reward});

  @override
  State<SeasonPodiumDialog> createState() => _SeasonPodiumDialogState();
}

class _SeasonPodiumDialogState extends State<SeasonPodiumDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  late final _profile = ProfileService.current;

  late final List<PodiumSpot> _standings = SeasonService.standings(
    seasonIndex: widget.reward.seasonIndex,
    playerRounds: widget.reward.rounds,
    playerName: _profile.name,
  );

  bool get _onPodium => widget.reward.placement <= 3;

  String get _shareText {
    final place = PodiumShareCard.placeLabel(widget.reward.placement);

    return "I just took $place in the 7 Seconds Endless season with "
        "${widget.reward.rounds} rounds 👑\n"
        "Think you can take my spot?\n${ShareService.storeLink}\n\n"
        "${ShareService.hashtags}";
  }

  Future<void> _shareVictory() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      final shared = await ShareService.shareCard(_cardKey, text: _shareText);

      if (shared && await MysteryBoxService.rewardShare() && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "🎁 Thanks for sharing! A free Mystery Box is waiting in the Shop.",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't share. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final placeColor = _onPodium ? Colors.amber : Colors.white;

    return Dialog(
      backgroundColor: const Color(0xFF14121F),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Off-screen story card, captured when sharing.
          if (_onPodium)
            Positioned(
              left: -1400,
              top: 0,
              child: RepaintBoundary(
                key: _cardKey,
                child: PodiumShareCard(
                  profile: _profile,
                  topThree: _standings.take(3).toList(),
                  placement: reward.placement,
                  prize: reward.ticks,
                ),
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "🏁 SEASON OVER",
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  PodiumShareCard.placeLabel(reward.placement),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: placeColor,
                    shadows: _onPodium
                        ? [
                            Shadow(
                              color: Colors.amber.withOpacity(0.7),
                              blurRadius: 24,
                            ),
                          ]
                        : null,
                  ),
                ),
                Text(
                  "${reward.rounds} rounds in Endless",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                FittedBox(
                  child: PodiumView(
                    topThree: _standings.take(3).toList(),
                    profile: _profile,
                    scale: 0.4,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "+${reward.ticks} ${GameConstants.currencyEmoji} "
                  "${GameConstants.currencyName}",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                if (!_onPodium) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Make the top 3 next season to win up to "
                    "${SeasonService.placementPrizes.first} "
                    "${GameConstants.currencyName}!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (_onPodium)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : _shareVictory,
                      icon: const Icon(Icons.ios_share),
                      label: Text(
                        _isSharing
                            ? "Preparing Card..."
                            : MysteryBoxService.shareRewardAvailable
                                ? "Share Victory & get a free 🎁"
                                : "Share Victory",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Collect",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _onPodium ? Colors.white70 : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
