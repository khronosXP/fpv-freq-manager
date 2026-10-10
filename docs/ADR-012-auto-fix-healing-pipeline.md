# ADR-012: Two-Tier Auto-Fix Healing Pipeline & Strict Band Isolation

## Status
**ACCEPTED**

## Context
When resolving channel collisions on the reactive fleet canvas, the auto-heal feature previously failed silently:
1. `FleetNotifier.autoHealUnlocked()` completely bypassed `GridAutoResolver`, delegating blindly to `calculateOptimalFleet()`.
2. When locked channels collided or mathematical constraints were violated, `allocateFleetSlots()` returned failure without surfacing `lastStatusMessage` in `CollisionSummaryBanner` or via a SnackBar, leaving the user with an unresponsive button.
3. Candidate pools in `GridAutoResolver` and `ConflictAnalyzer` leaked standard frequencies into Lowband and X-band pools, violating strict band isolation.
4. A rigid 12 MHz IMD floor prevented resolving 6 standard boards (which require a 10 MHz floor).

## Decision
1. **Two-Tier Auto-Healing Pipeline**:
   - **Tier 0 (Pre-flight Lock Validation)**: If locked channels (🔒) mutually collide, abort early with an actionable Ukrainian message instructing the user to unlock conflicting boards.
   - **Tier 1 (Smart Micro-Fix via `GridAutoResolver`)**: Preserve unconflicted unlocked channels and adjust only conflicted or unassigned channels to nearest safe frequencies.
   - **Tier 2 (Macro Maximin Fallback via `FrequencyAllocator`)**: Fallback to global branch-and-bound optimization honoring locked channels.
2. **Strict Band Isolation**:
   - `_getCandidatePool` strictly partitions Standard (5.8 GHz), Lowband (5.3–5.5 GHz), and X-Band (4.9–5.2 GHz).
3. **Adaptive IMD Floor**:
   - Automatically adapts floor to 10 MHz (`marginalImdDistance`) when 6 standard boards are present, and 12 MHz otherwise.
4. **UI Diagnostic Feedback**:
   - `CollisionSummaryBanner` renders an inline diagnostic alert callout when auto-heal cannot resolve collisions.
   - `CalculatorScreen` listens to `fleetProvider` via `ref.listen` and displays high-contrast tactical `SnackBar` messages on completion.

## Consequences
- Guaranteed non-silent error reporting with clear, actionable guidance.
- Safe, minimal-mutation frequency healing for drone operators in field conditions.
