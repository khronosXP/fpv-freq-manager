# ADR-013: UI Layout Consolidation & Single-Source Fleet List

## Status
**ACCEPTED**

## Context
In `CalculatorScreen`, the fleet boards were duplicated across two separate widgets:
1. `FleetGrid`: An interactive list of board cards with manual frequency picker ("Змінити"), lock toggles, band selectors, and collision alerts.
2. `ResultCheatSheet`: A duplicate, read-only list of the exact same boards, trapping the `RfSpectrumChart` in between.

The operator was presented with redundant cards and disjointed visual flow.

## Decision
1. **Retire Duplicate List**:
   - Deprecate and remove `ResultCheatSheet` from `CalculatorScreen`.
2. **Unified Fleet Board List (`FleetGrid`)**:
   - `FleetGrid` is now the single source of truth for board cards.
   - Header with table icon, board counter (`СІТКА ЧАСТОТ (N бортів)`), and a dedicated `FilledButton.tonalIcon` "Копіювати" to copy the entire formatted cheat-sheet to the clipboard.
   - Each card contains the manual channel selector button (`minHeight: 52`), frequency badge, lock toggle, band selector, collision alerts, and 1-tap replacement suggestions.
3. **Canonical Page Layout Sequence**:
   - 1. `CalculatorHeaderBanner`
   - 2. `FleetCountersSection`
   - 3. `FleetActionBar`
   - 4. `CollisionSummaryBanner`
   - 5. `FleetGrid` (Unified board list with manual controls)
   - 6. `RfSpectrumChart` (The spectrum diagram placed as the FINAL telemetry block right above the footer)
   - 7. `CalculatorFooter`

## Consequences
- Clean, non-redundant interface.
- Intuitive bottom-of-page spectrum diagram placement reflecting live frequency allocations.
- File line limits strictly maintained (< 300 lines across all widgets).
