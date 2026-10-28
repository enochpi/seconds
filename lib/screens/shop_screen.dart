import 'package:flutter/material.dart';

import '../models/cosmetics.dart';
import '../models/pet.dart';
import '../services/cosmetics_service.dart';
import '../services/mystery_box_service.dart';
import '../services/profile_service.dart';
import '../services/shop_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/cosmetic_widgets.dart';
import '../widgets/profile_card_widget.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _currency =
      "${GameConstants.currencyEmoji} ${GameConstants.currencyName}";

  Future<bool> _confirmPurchase({
    required String name,
    required int cost,
  }) async {
    final balance = StorageService.getTicks();

    if (balance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You need ${cost - balance} more ${GameConstants.currencyName}. "
            "Keep playing!",
          ),
        ),
      );
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text("Buy $name?"),
          content: Text("This costs $cost $_currency."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Buy"),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _buyMode(GameMode mode) async {
    final confirmed = await _confirmPurchase(
      name:
          "${GameConstants.modeEmoji(mode)} ${GameConstants.modeName(mode)} Mode",
      cost: GameConstants.modeUnlockCost(mode),
    );
    if (!confirmed) return;

    await ShopService.buyMode(mode);
    if (mounted) setState(() {});
  }

  Future<void> _buyOrEquipPet(Pet pet) async {
    if (ShopService.ownsPet(pet)) {
      await ShopService.equipPet(pet);
    } else {
      final confirmed = await _confirmPurchase(
        name: "${pet.emoji} ${pet.name}",
        cost: pet.cost,
      );
      if (!confirmed) return;

      await ShopService.buyPet(pet);
    }

    if (mounted) setState(() {});
  }

  Future<void> _buyOrEquipCosmetic(Cosmetic item) async {
    if (CosmeticsService.owns(item)) {
      await CosmeticsService.equip(item);
    } else {
      final confirmed =
          await _confirmPurchase(name: item.name, cost: item.cost);
      if (!confirmed) return;

      await CosmeticsService.buy(item);
    }

    if (mounted) setState(() {});
  }

  Widget _buildBalance() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "YOUR ${GameConstants.currencyName.toUpperCase()}  ",
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: Colors.amber,
            ),
          ),
          Text(
            "${GameConstants.currencyEmoji} ${StorageService.getTicks()}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({
    required Widget preview,
    required String title,
    required String subtitle,
    required Widget action,
    bool highlighted = false,
    Color? subtitleColor,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 76, child: Center(child: preview)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: subtitleColor == null
                        ? FontWeight.w600
                        : FontWeight.w900,
                    color: subtitleColor ?? onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          action,
        ],
      ),
    );
  }

  Widget _buildPriceButton(int cost, VoidCallback onPressed) {
    final canAfford = StorageService.getTicks() >= cost;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? Colors.amber : Colors.grey.shade700,
        foregroundColor: canAfford ? Colors.black : Colors.white70,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        "${GameConstants.currencyEmoji} $cost",
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildStatusLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  /// "Equipped", "Equip" or a price button, depending on what the player has.
  Widget _buildOwnershipAction({
    required bool equipped,
    required bool owned,
    required int cost,
    required VoidCallback onPressed,
  }) {
    if (equipped) return _buildStatusLabel("Equipped", Colors.amber);

    if (owned) {
      return OutlinedButton(
        onPressed: onPressed,
        child: const Text("Equip"),
      );
    }

    return _buildPriceButton(cost, onPressed);
  }

  Widget _buildEmojiPreview(String emoji) {
    return Text(emoji, style: const TextStyle(fontSize: 34));
  }

  Widget _buildList(List<Widget> items, String hint) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withOpacity(0.6),
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildModesTab() {
    final lockableModes =
        GameMode.values.where((mode) => GameConstants.modeUnlockCost(mode) > 0);

    final items = lockableModes.map((mode) {
      final unlocked = StorageService.isModeUnlocked(mode);
      final multiplier = GameConstants.modeTicksMultiplierLabel(mode);

      return _buildItemCard(
        preview:
            _buildEmojiPreview(unlocked ? GameConstants.modeEmoji(mode) : "🔒"),
        title: "${GameConstants.modeName(mode)} Mode",
        subtitle: "${GameConstants.modeDescription(mode)}\n"
            "Pays $multiplier ${GameConstants.currencyName}",
        action: unlocked
            ? _buildStatusLabel("Owned", Colors.greenAccent)
            : _buildPriceButton(
                GameConstants.modeUnlockCost(mode),
                () => _buyMode(mode),
              ),
      );
    }).toList();

    return _buildList(items, "Harder modes pay more.");
  }

  Widget _buildPetsTab() {
    final equippedId = StorageService.getEquippedPetId();

    final items = Pet.all.map((pet) {
      final equipped = pet.id == equippedId;

      return _buildItemCard(
        preview: _buildEmojiPreview(pet.emoji),
        title: pet.name,
        subtitle: "${pet.bonusLabel} ${GameConstants.currencyName} every run",
        action: _buildOwnershipAction(
          equipped: equipped,
          owned: ShopService.ownsPet(pet),
          cost: pet.cost,
          onPressed: () => _buyOrEquipPet(pet),
        ),
        highlighted: equipped,
      );
    }).toList();

    return _buildList(
      items,
      "Your pet boosts every run. Only one can be equipped.",
    );
  }

  Future<void> _buyStreakShield() async {
    final confirmed = await _confirmPurchase(
      name: "a Streak Shield",
      cost: GameConstants.streakShieldCost,
    );
    if (!confirmed) return;

    await ShopService.buyStreakShield();
    if (mounted) setState(() {});
  }

  Widget _buildBoostsTab() {
    final shields = ShopService.streakShields;

    return _buildList(
      [
        _buildItemCard(
          preview: _buildEmojiPreview("🛡️"),
          title: "Streak Shield",
          subtitle: "Saves a 🔥 win streak of "
              "${GameConstants.streakShieldMinStreak}+ once when a run "
              "goes badly. Used automatically.\nYou have $shields.",
          action: _buildPriceButton(
            GameConstants.streakShieldCost,
            _buyStreakShield,
          ),
          highlighted: shields > 0,
        ),
      ],
      "One-time items. Buy as many as you like.",
    );
  }

  Widget _buildCosmeticPreview(Cosmetic item) {
    if (item is ButtonSkin) {
      return SkinnedButtonFace(
        skin: item,
        defaultColor: Colors.green,
        size: 56,
      );
    }

    if (item is TimerStyle) {
      return Container(
        width: 76,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: StyledTimerText(
              text: "7.00",
              style: item,
              fontSize: 24,
              defaultColor: Colors.lightBlueAccent,
            ),
          ),
        ),
      );
    }

    if (item is BackgroundStyle) {
      final radius = BorderRadius.circular(12);

      return SizedBox(
        width: 76,
        height: 52,
        child: item.colors.isEmpty
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
              )
            : CosmeticBackground(
                style: item,
                borderRadius: radius,
                child: const SizedBox.expand(),
              ),
      );
    }

    if (item is TapEffect) {
      return Text(
        item.particles.isEmpty ? "—" : item.particles.join(),
        style: const TextStyle(fontSize: 22),
      );
    }

    if (item is PlayerTitle) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: item.rarity.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: item.rarity.color.withOpacity(0.6)),
        ),
        child: Text(
          item.isDefault ? "—" : "🏷️",
          style: const TextStyle(fontSize: 20),
        ),
      );
    }

    if (item is ProfileFrame) {
      // Preview around the player's own picture.
      return FramedAvatar(
        profile: ProfileService.current.previewWith(frame: item),
        size: 64,
      );
    }

    if (item is ProfileBanner) {
      final banner = item;

      return Container(
        width: 76,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: banner.colors.isEmpty
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.07)
              : null,
          gradient: banner.colors.isEmpty
              ? null
              : LinearGradient(colors: banner.colors),
        ),
        alignment: Alignment.center,
        child: Text(
          banner.pattern ?? "",
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    final font = item as AppFont;

    return Text(
      "Aa 7.00",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        fontFamily: font.family,
        fontFamilyFallback: font.fallback,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Future<void> _openMysteryBox() async {
    final result = await MysteryBoxService.open();

    if (result == null) {
      final balance = StorageService.getTicks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You need ${MysteryBoxService.cost - balance} more "
            "${GameConstants.currencyName}. Share a result for a free box!",
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {});

    final item = result.item;
    final rarity = item.rarity;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: rarity.color, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pops in from small to full size.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.2, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: SizedBox(
                    height: 90,
                    child: Center(child: _buildCosmeticPreview(item)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  rarity.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w900,
                    color: rarity.color,
                  ),
                ),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _categoryName(item.type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(dialogContext)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.wasDuplicate
                      ? "Already owned → +${result.refundTicks} "
                          "${GameConstants.currencyEmoji}"
                      : "New item unlocked!",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (!result.wasDuplicate)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await CosmeticsService.equip(item);
                        if (mounted) setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rarity.color,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        "Equip now",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Nice!"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _categoryName(CosmeticType type) {
    switch (type) {
      case CosmeticType.button:
        return "Button";
      case CosmeticType.timer:
        return "Timer";
      case CosmeticType.background:
        return "Background";
      case CosmeticType.font:
        return "Font";
      case CosmeticType.tapEffect:
        return "Tap Effect";
      case CosmeticType.title:
        return "Title";
      case CosmeticType.frame:
        return "Profile Frame";
      case CosmeticType.banner:
        return "Profile Banner";
    }
  }

  Widget _buildMysteryBoxTab() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final freeBoxes = MysteryBoxService.freeBoxes;
    final weights = MysteryBoxService.dropWeights;
    final total = weights.values.reduce((a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A1B9A), Color(0xFF283593)],
            ),
          ),
          child: Column(
            children: [
              const Text("🎁", style: TextStyle(fontSize: 80)),
              const Text(
                "Mystery Box",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "One random item. Duplicates turn into Ticks.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openMysteryBox,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    freeBoxes > 0
                        ? "Open FREE box ($freeBoxes)"
                        : "Open for ${GameConstants.currencyEmoji} "
                            "${MysteryBoxService.cost}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
          ),
          child: const Text(
            "📲 Share a result to Instagram, TikTok, LinkedIn or anywhere "
            "and get a FREE box (once a day)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Drop chances",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in weights.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.key.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.key.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: entry.key.color,
                  ),
                ),
                const Spacer(),
                Text(
                  "${(entry.value * 100 / total).round()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCosmeticTab(CosmeticType type, String hint) {
    final items = Cosmetic.ofType(type).map((item) {
      final equipped = CosmeticsService.isEquipped(item);

      return _buildItemCard(
        preview: _buildCosmeticPreview(item),
        title: item.name,
        subtitle: item.isDefault
            ? "Free"
            : item is ProfileFrame && item.boost > 0
                ? "${item.rarity.label} • ${item.boostLabel} "
                    "${GameConstants.currencyName}"
                : item.rarity.label,
        subtitleColor: item.isDefault ? null : item.rarity.color,
        action: _buildOwnershipAction(
          equipped: equipped,
          owned: CosmeticsService.owns(item),
          cost: item.cost,
          onPressed: () => _buyOrEquipCosmetic(item),
        ),
        highlighted: equipped,
      );
    }).toList();

    return _buildList(items, hint);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 12,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Shop",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: "🎁 Mystery Box"),
              Tab(text: "🔓 Modes"),
              Tab(text: "🐾 Pets"),
              Tab(text: "🛡️ Boosts"),
              Tab(text: "🔘 Buttons"),
              Tab(text: "⏱️ Timers"),
              Tab(text: "🖼️ Backgrounds"),
              Tab(text: "🔤 Fonts"),
              Tab(text: "✨ Effects"),
              Tab(text: "🏷️ Titles"),
              Tab(text: "🖼️ Frames"),
              Tab(text: "🎌 Banners"),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildBalance(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMysteryBoxTab(),
                    _buildModesTab(),
                    _buildPetsTab(),
                    _buildBoostsTab(),
                    _buildCosmeticTab(
                      CosmeticType.button,
                      "The button you tap every round.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.timer,
                      "How the big timer numbers look.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.background,
                      "The background behind the game.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.font,
                      "The font used across the whole app.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.tapEffect,
                      "Particles that burst out every time you tap.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.title,
                      "Shown under your name on your share card and the "
                      "leaderboard.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.frame,
                      "Encase your profile picture with flames, lightning, "
                      "crowns and more. Upload your photo from Profile. "
                      "Frames also give a small Ticks boost.",
                    ),
                    _buildCosmeticTab(
                      CosmeticType.banner,
                      "The background of your profile card.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
