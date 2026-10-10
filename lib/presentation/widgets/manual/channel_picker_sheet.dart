import 'package:flutter/material.dart';
import '../../../core/constants/fpv_frequencies.dart';
import '../../../core/math/imd_validator.dart';
import '../../../core/models/board_type.dart';
import '../../../core/models/fpv_channel.dart';
import '../../../core/models/manual_drone_slot.dart';

class ChannelPickerSheet extends StatefulWidget {
  final ManualDroneSlot targetSlot;
  final List<ManualDroneSlot> otherSlots;
  final ValueChanged<FpvChannel> onSelectChannel;

  const ChannelPickerSheet({
    super.key,
    required this.targetSlot,
    required this.otherSlots,
    required this.onSelectChannel,
  });

  static Future<void> show({
    required BuildContext context,
    required ManualDroneSlot targetSlot,
    required List<ManualDroneSlot> otherSlots,
    required ValueChanged<FpvChannel> onSelectChannel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChannelPickerSheet(
        targetSlot: targetSlot,
        otherSlots: otherSlots,
        onSelectChannel: onSelectChannel,
      ),
    );
  }

  @override
  State<ChannelPickerSheet> createState() => _ChannelPickerSheetState();
}

class _ChannelPickerSheetState extends State<ChannelPickerSheet> {
  late String _selectedBandName;

  @override
  void initState() {
    super.initState();
    final allowedBands = _getAllowedBands();
    _selectedBandName =
        widget.targetSlot.channel?.bandName ?? allowedBands.first;
    if (!allowedBands.contains(_selectedBandName)) {
      _selectedBandName = allowedBands.first;
    }
  }

  List<String> _getAllowedBands() => switch (widget.targetSlot.boardType) {
    BoardType.standard => const ['R', 'F', 'A', 'B', 'E'],
    BoardType.lowband => const ['L'],
    BoardType.xBand => const ['X'],
  };

  List<FpvChannel> _getChannelsForBand(String bandName) => switch (bandName) {
    'R' => FpvFrequencies.bandR,
    'F' => FpvFrequencies.bandF,
    'A' => FpvFrequencies.bandA,
    'B' => FpvFrequencies.bandB,
    'E' => FpvFrequencies.bandE,
    'L' => FpvFrequencies.bandL,
    'X' => FpvFrequencies.bandX,
    _ => switch (widget.targetSlot.boardType) {
      BoardType.lowband => FpvFrequencies.bandL,
      BoardType.xBand => FpvFrequencies.bandX,
      BoardType.standard => FpvFrequencies.bandR,
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final otherFreqs = widget.otherSlots
        .where((s) => s.isAssigned)
        .map((s) => s.channel!.frequency)
        .toList();

    final allowedBands = _getAllowedBands();
    final channels = _getChannelsForBand(_selectedBandName);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.tune, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Вибір каналу: Борт ${widget.targetSlot.boardNumber} (${widget.targetSlot.boardType.displayName})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Band tabs for standard 5.8 GHz
            if (allowedBands.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: allowedBands.map((band) {
                    final isSelected = band == _selectedBandName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Band $band'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedBandName = band);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
            ],
            // Channel List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: channels.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ch = channels[index];
                  final isCurrent = widget.targetSlot.channel?.code == ch.code;
                  final isClean = ImdValidator.canAddFrequency(
                    otherFreqs,
                    ch.frequency,
                  );

                  return _buildChannelItem(
                    context,
                    ch,
                    isCurrent,
                    isClean,
                    colorScheme,
                    theme,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelItem(
    BuildContext context,
    FpvChannel ch,
    bool isCurrent,
    bool isClean,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final statusColor = isClean ? colorScheme.tertiary : colorScheme.error;

    return InkWell(
      onTap: () {
        widget.onSelectChannel(ch);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.25),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ch.code,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: isCurrent
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Frequency
            Text(
              '${ch.frequency} MHz',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            // Clean / Collision Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isClean ? Icons.check_circle : Icons.warning_amber,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isClean ? 'Без колізій' : 'Завада / IMD3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
