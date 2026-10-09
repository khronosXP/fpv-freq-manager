import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/math/frequency_allocator.dart';

class FrequencyManagerState {
  static const int maxTotalBoards = 12;
  static const int maxStandardBoards = 6;
  static const int maxLowbandBoards = 4;
  static const int maxXBandBoards = 3;

  final int standardCount;
  final int lowbandCount;
  final int xBandCount;
  final bool useExtendedBands;
  final FrequencyAllocationResult? result;
  final bool hasGenerated;
  final int? selectedBoardNumber;
  final bool isCalculating;

  const FrequencyManagerState({
    this.standardCount = 2,
    this.lowbandCount = 0,
    this.xBandCount = 0,
    this.useExtendedBands = false,
    this.result,
    this.hasGenerated = false,
    this.selectedBoardNumber,
    this.isCalculating = false,
  });

  int get totalBoards =>
      standardCount + (useExtendedBands ? (lowbandCount + xBandCount) : 0);

  bool get canIncrementStandard =>
      standardCount < maxStandardBoards && totalBoards < maxTotalBoards;

  bool get canDecrementStandard => standardCount > 0 && totalBoards > 1;

  bool get canIncrementLowband =>
      useExtendedBands &&
      lowbandCount < maxLowbandBoards &&
      totalBoards < maxTotalBoards;

  bool get canDecrementLowband => lowbandCount > 0 && totalBoards > 1;

  bool get canIncrementXBand =>
      useExtendedBands &&
      xBandCount < maxXBandBoards &&
      totalBoards < maxTotalBoards;

  bool get canDecrementXBand => xBandCount > 0 && totalBoards > 1;

  bool get isStandardAtLimit => standardCount >= maxStandardBoards;
  bool get isTotalAtLimit => totalBoards >= maxTotalBoards;

  FrequencyManagerState copyWith({
    int? standardCount,
    int? lowbandCount,
    int? xBandCount,
    bool? useExtendedBands,
    FrequencyAllocationResult? Function()? result,
    bool? hasGenerated,
    int? Function()? selectedBoardNumber,
    bool? isCalculating,
  }) {
    return FrequencyManagerState(
      standardCount: standardCount ?? this.standardCount,
      lowbandCount: lowbandCount ?? this.lowbandCount,
      xBandCount: xBandCount ?? this.xBandCount,
      useExtendedBands: useExtendedBands ?? this.useExtendedBands,
      result: result != null ? result() : this.result,
      hasGenerated: hasGenerated ?? this.hasGenerated,
      selectedBoardNumber: selectedBoardNumber != null
          ? selectedBoardNumber()
          : this.selectedBoardNumber,
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }
}

class FrequencyManagerNotifier extends Notifier<FrequencyManagerState> {
  final FrequencyAllocator _allocator = const FrequencyAllocator();

  @override
  FrequencyManagerState build() {
    return const FrequencyManagerState();
  }

  void incrementStandard() {
    if (!state.canIncrementStandard) return;
    state = state.copyWith(
      standardCount: state.standardCount + 1,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void decrementStandard() {
    if (!state.canDecrementStandard) return;
    state = state.copyWith(
      standardCount: state.standardCount - 1,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void incrementLowband() {
    if (!state.canIncrementLowband) return;
    state = state.copyWith(
      lowbandCount: state.lowbandCount + 1,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void decrementLowband() {
    if (!state.canDecrementLowband) return;
    state = state.copyWith(
      lowbandCount: state.lowbandCount - 1,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void incrementXBand() {
    if (!state.canIncrementXBand) return;
    state = state.copyWith(
      xBandCount: state.xBandCount + 1,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void decrementXBand() {
    if (!state.canDecrementXBand) return;
    state = state.copyWith(
      xBandCount: state.xBandCount - 1,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void toggleExtendedBands(bool value) {
    state = state.copyWith(
      useExtendedBands: value,
      selectedBoardNumber: () => null,
    );
    if (state.hasGenerated) {
      _runAllocation();
    }
  }

  void selectBoard(int? boardNumber) {
    if (state.selectedBoardNumber == boardNumber) {
      state = state.copyWith(selectedBoardNumber: () => null);
    } else {
      state = state.copyWith(selectedBoardNumber: () => boardNumber);
    }
  }

  Future<void> generate() async {
    if (state.isCalculating) return;
    state = state.copyWith(isCalculating: true);
    await Future<void>.delayed(Duration.zero);
    _runAllocation();
  }

  void _runAllocation() {
    final effectiveLowband = state.useExtendedBands ? state.lowbandCount : 0;
    final effectiveXBand = state.useExtendedBands ? state.xBandCount : 0;

    final result = _allocator.allocate(
      numStandard: state.standardCount,
      numLowband: effectiveLowband,
      numXBand: effectiveXBand,
    );

    state = state.copyWith(
      result: () => result,
      hasGenerated: true,
      isCalculating: false,
    );
  }

  void reset() {
    state = const FrequencyManagerState();
  }
}

final frequencyManagerProvider =
    NotifierProvider<FrequencyManagerNotifier, FrequencyManagerState>(
      FrequencyManagerNotifier.new,
    );
