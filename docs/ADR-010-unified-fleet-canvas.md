# ADR-010: Unification of FPV Frequency Manager into a Single-Pane Reactive Fleet Canvas

- **Status**: Approved
- **Date**: 2026-10-10
- **Author**: System Architect, Flutter-STUDIO
- **Applies to**: `apps/fpv_freq_manager`
- **Supersedes**: Modal dual-tab interface (`app_mode_provider.dart`), ad-hoc grid healing (`GridAutoResolver`)
- **Extends**: ADR-009 (Maximin Engine Optimizer Architecture)

---

## 1. Context & Architectural Assessment

The FPV Frequency Manager (PWA) previously operated under two distinct operational paradigms separated by a modal `SegmentedButton` tab toggle (`app_mode_provider.dart`):
1. **Auto Calculator Mode (`AutoCalculatorView`)**: Driven by `FrequencyManagerNotifier`, focused on fleet count inputs (Standard, Lowband, X-Band) and running the multi-band Maximin solver (`FrequencyAllocator`).
2. **Manual Configurator Mode (`ManualConfiguratorView`)**: Driven by `ManualConfigNotifier`, focused on individual slot inspection, manual channel assignments, channel locking (🔒), and local heuristic repair (`GridAutoResolver`).

### Critical Flaws of the Dual-Tab Paradigm:
1. **State Fragmentation & Synchronization Friction**:
   - State lived in two independent notifiers (`FrequencyManagerNotifier` and `ManualConfigNotifier`).
   - Synchronization required a brittle handshake (`syncWithAllocationIfUntouched`), copying calculated boards into slots on tab switch.
   - User edits made in manual mode (`isUserCustomized = true`) were severed from auto-calculation; switching back to auto mode caused either loss of mental model or data divergence.
2. **Solver Divergence & Suboptimal RF Healing**:
   - `FrequencyAllocator` performed global Maximin optimization with Branch & Bound and Sidon DiffMap checks, but had zero support for locked channel constraints.
   - `GridAutoResolver` supported locked channels, but used an ad-hoc local backtracking heuristic minimizing deviation from existing frequency, completely bypassing Maximin multi-objective scoring and IMD margin guarantees established in ADR-009.
3. **High Cognitive Load in Tactical Field Conditions**:
   - Drone operators in the field need to coordinate mixed fleets (up to 12 UAVs) rapidly without having to switch tabs or manage disparate UI workflows (counters vs dropdowns).

---

## 2. Decision: The Single-Pane Reactive Fleet Canvas

We formally approve the complete architectural unification of the FPV Frequency Manager into a **Single-Pane Reactive Fleet Canvas**.

```
+-----------------------------------------------------------------------+
|                       CalculatorHeaderBanner                          |
+-----------------------------------------------------------------------+
|                        FleetCountersSection                           |
|  [Standard 5.8G: - 3 +]  [Extended Toggle]  [Lowband: - 1 +] [X-Band] |
+-----------------------------------------------------------------------+
|                          FleetActionBar                               |
|  [ ⚡ Розрахувати вільні борти ]    [ 🛡️ СІТКА БЕЗПЕЧНА (ЧИСТИЙ ЕФІР) ]|
+-----------------------------------------------------------------------+
|               CollisionSummaryBanner (Reactive conditional)           |
|  [ ⚠️ КОЛІЗІЇ: 2 | 🪄 1-Click Автовиправлення | 📋 Деталі розрахунку ]  |
+-----------------------------------------------------------------------+
|                            FleetGrid                                  |
|  [ Card #1: Std | R1 (5658) | 🔒 Locked   | Status: Clean          ]  |
|  [ Card #2: Std | R4 (5769) | 🔓 Unlocked | Status: Clean          ]  |
|  [ Card #3: Low | L2 (5373) | 🔓 Unlocked | Status: Clean          ]  |
|  [ Card #4: Std | R1 (5658) | 🔓 Unlocked | ⚠️ Conflict: Δf < 40MHz ]  |
+-----------------------------------------------------------------------+
|                       RfSpectrumChart & CheatSheet                    |
|  [ Interactive Horizontally Scrollable Spectrum Chart               ]  |
|  [ CheatSheet Grid + Copy to Clipboard CTA                          ]  |
+-----------------------------------------------------------------------+
|                          CalculatorFooter                             |
+-----------------------------------------------------------------------+
```

---

## 3. Architectural Specifications

### 3.1. Single Source of Truth & State Flow

1. **Retirement of Modal Switching**:
   - `app_mode_provider.dart` and `FpvManagerMode` are deprecated and retired from the UI layer.
2. **Canonical Domain Model**:
   - `FleetDroneSlot` (compatible with `ManualDroneSlot`):
     ```dart
     class FleetDroneSlot {
       final int id;
       final int boardNumber; // 1..N
       final BoardType boardType; // standard, lowband, xBand
       final FpvChannel? channel;
       final bool isLocked;
     }
     ```
3. **Canonical State: `FleetState` (in `FleetNotifier`)**:
   ```dart
   class FleetState {
     final List<FleetDroneSlot> slots;
     final bool useExtendedBands;
     final ConflictReport conflictReport;
     final bool isCalculating;
     final String? lastStatusMessage;
     final int? selectedSlotId;
     final bool hasGenerated;

     // Invariant: Counters are strictly derived from slots
     int get standardCount => slots.where((s) => s.boardType == BoardType.standard).length;
     int get lowbandCount => slots.where((s) => s.boardType == BoardType.lowband).length;
     int get xBandCount => slots.where((s) => s.boardType == BoardType.xBand).length;
     int get totalBoards => slots.length;
   }
   ```
4. **State Mutations & Invariants**:
   - `incrementStandard()` / `incrementLowband()` / `incrementXBand()`: Appends a new slot of the specified type. If the existing fleet is clean, it assigns the best available non-conflicting channel or recalculates unlocked slots.
   - `decrementStandard()` / `decrementLowband()` / `decrementXBand()`: Safely pops the last **unlocked** slot of that type (protecting operator locks). Re-indexes board numbers 1..N.
   - `toggleLock(slotId)`: Flips `isLocked` flag.
   - `assignChannel(slotId, channel)`: Updates slot channel and immediately triggers reactive `ConflictAnalyzer.analyze(slots)` within 0 ms.
   - `calculateOptimalFleet()` / `autoHealUnlocked()`: Passes locked channels as invariant constraints to the Maximin solver, re-optimizing all unlocked slots.

---

### 3.2. Solver Constraint Architecture (Constrained Maximin Engine)

`MaximinEngine` and `FrequencyAllocator` are extended to solve with **Fixed Constraints**:

```dart
BandAllocationResult optimize({
  required List<FpvChannel> availableChannels,
  required int count,
  List<FpvChannel> lockedChannels = const [],
});
```

#### Constraint Resolution Pipeline:
1. **Internal Locked Validation**:
   - Check all pairs of `lockedChannels` for guard band spacing: $|f_i - f_j| \ge 40$ MHz.
   - Check all triplets of `lockedChannels` for IMD3 distance: $|2f_i - f_j - f_k| \ge 10$ MHz.
   - If locked channels violate physics, halt immediately with diagnostic:
     `"Зафіксовані канали (🔒) конфліктують між собою. Зніміть блокування хоча б з одного зафіксованого борта."`
2. **Dynamic Available Pool Filtering**:
   - Exclude frequencies already assigned to `lockedChannels`.
   - **Cross-Band Filter**: If Lowband has a locked channel $L_8$ (5613 MHz), dynamically exclude Standard channels with $f < 5653$ MHz (excluding $E_4$ 5645 MHz) to maintain the 40 MHz guard band.
   - If Lowband has no locked channels and Standard slots exist, continue excluding $L_8$ from candidate pool (ADR-009).
3. **Constrained Branch & Bound Search**:
   - `freeCount = count - lockedChannels.length`.
   - Free candidates are explored in strictly monotonic frequency order (`startIndex = i + 1`) to preserve **Symmetry Breaking** ($O(k!)$ pruning).
   - Each candidate is evaluated against all `lockedChannels` and currently accumulated free channels via:
     - Guard band: $\Delta f \ge 40$ MHz
     - `DiffMap.canAddWithoutCollision` (Sidon diff rejection)
     - `ImdValidator.canAddFrequency(currentFreqs, cand.frequency)`
   - Full ensemble score is calculated using `AllocationScore`:
     $$\text{Score} = \min(\text{imdMargin}, 50) \cdot 100 + \text{minSpacing} \cdot 10 + \text{totalSpread} \cdot 0.1$$
   - The combination with maximum score is assigned to the unlocked slots.
4. **Execution Performance**:
   - Search space for $\le 6$ free channels with Branch & Bound pruning remains $< 66,000$ iterations.
   - Total runtime across all 3 bands is strictly **$< 5$ ms**, maintaining the Zero-Latency guarantee on web and mobile.

---

### 3.3. UI Modularity & Flutter-Culture Compliance

The UI is decomposed into small, focused widgets adhering to the strict 300-line limit:

| File | Purpose | Line Estimate |
|---|---|---|
| `calculator_screen.dart` | Root screen orchestration, SingleChildScrollView | ~130 lines |
| `fleet_counters_section.dart` | Band counters (+/-), extended toggle, limits | ~140 lines |
| `fleet_action_bar.dart` | "⚡ Розрахувати" button, status badge, reset | ~90 lines |
| `fleet_grid.dart` | Grid layout of drone slot cards | ~85 lines |
| `fleet_drone_slot_card.dart` | Individual slot: board badge, picker, lock, error | ~180 lines |
| `collision_summary_banner.dart` | Reactive warning banner with 1-click auto-fix | ~120 lines |
| `rf_spectrum_chart.dart` | Interactive canvas RF visualization | ~190 lines |
| `result_cheat_sheet.dart` | Frequency cheat-sheet table & copy action | ~180 lines |

#### Flutter-Culture 4-Point Checklist Guarantees:
1. **Rule 1 (No async setState)**: Zero `setState(() async ...)`. Asynchronous calculation is managed via `ref.read(fleetProvider.notifier).calculateOptimalFleet()`, updating `isCalculating` reactively.
2. **Rule 2 (No hardcoded Colors.*)**: 100% theme-based styling using `Theme.of(context).colorScheme.*` (`primary`, `secondary`, `error`, `surface`, `outlineVariant`) and `textTheme`.
3. **Rule 3 (Navigation via context.goNamed)**: Zero raw pushes. Modals are opened via `showModalBottomSheet` (`ChannelPickerSheet`) and `showDialog` (`CollisionDetailDialog`).
4. **Rule 4 (No side-effects in build)**: Pure reactive rendering inside `build()`. Actions triggered strictly through user interactions (`onPressed`, `onTap`).

---

### 3.4. Backward Compatibility & Test Migration Strategy

1. **Model Aliasing**:
   `typedef ManualDroneSlot = FleetDroneSlot;` preserves backward compatibility across existing math tests (`conflict_analyzer_test.dart`, `grid_auto_resolver_test.dart`).
2. **Provider Bridging**:
   - `fleetProvider` becomes the primary canonical notifier.
   - `frequencyManagerProvider` and `manualConfigProvider` are maintained as backward-compatible proxies or re-exports.
   - `app_mode_provider.dart` is retained as a deprecated compatibility stub (`FpvManagerMode.auto` default) so legacy imports compile without breaking changes.
3. **Test Suite Adaptation**:
   - Existing math tests (30/30) remain 100% valid and unaffected.
   - Widget tests (`widget_test.dart`, `manual_configurator_test.dart`) are updated to target the unified canvas directly, verifying fleet counter adjustments, slot card locks, reactive collision detection, and 1-click optimization on a single screen.

---

## 4. Consequences & Benefits

- **Zero Operational Friction**: Pilots adjust fleet size, lock pre-assigned drones, and click "⚡ Розрахувати вільні борти" on one single screen.
- **Unified Math Core**: Solves both unconstrained auto-generation and constrained manual repair using the same mathematically proven Maximin Engine Optimizer (ADR-009).
- **Rock-Solid Reactivity**: Real-time conflict analysis provides immediate visual feedback whenever an operator selects a channel, preventing errors before takeoff.
- **Maintainable Codebase**: Retires duplicate UI views (`AutoCalculatorView`, `ManualConfiguratorView`), reduces SLOC, and enforces strict widget modularity (< 300 lines/file).

---

## 5. Formal Architectural Decision

**DECISION: APPROVED FOR IMPLEMENTATION (ADR-010).**  
The implementation team may proceed with unifying the state into `FleetNotifier`, extending `MaximinEngine` with locked constraints, and assembling the Single-Pane Reactive Fleet Canvas.
