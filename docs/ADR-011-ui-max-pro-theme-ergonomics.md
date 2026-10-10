# ADR-011: UI Max Pro Light Theme & Field Ergonomics Overhaul

- **Status**: Approved & Implemented
- **Date**: 2026-10-10
- **Context**: FPV Frequency Manager (`apps/fpv_freq_manager`)
- **Author**: System Architect & Lead Developer

---

## 1. Context & Problem Statement

`apps/fpv_freq_manager` is operated by FPV pilots, instructors, and electronic warfare / telemetry teams in dynamic, demanding environments:
1. **Daylight Outdoor Flight Lines**: In bright sunlight (> 10,000–50,000 lux), dark themes suffer from heavy specular glare, reflections, and reduced legibility on mobile devices.
2. **Tactile Interaction in Field Conditions**: Operators frequently use tablets or smartphones with gloved hands, cold fingers, or in turbulent field setups. Touch targets smaller than 44x44px lead to missed taps and operational friction.
3. **Cognitive Load Under Pressure**: Preparing 2 to 12 drones for coordinated flight requires instant identification of channels, frequencies, and intermodulation collisions without visual ambiguity.

---

## 2. Ergonomics & Usability Audit Findings

| Area | Current Baseline | Ergonomic Issue | "UI Max Pro" Solution |
|------|------------------|-----------------|------------------------|
| **Sunlight Legibility** | Dark Theme only (Neon Cyan on `#0D1117`) | Strong glare in direct sunlight, washed-out contrast | **"UI Max Pro" Light Theme**: Slate-50 canvas (`#F8FAFC`), Pure White surfaces (`#FFFFFF`), Slate-900 typography (`#0F172A`, 16.2:1 WCAG AAA), High-contrast Cobalt Blue (`#0265DC`, 7.2:1) |
| **Touch Targets** | `IconButton`s with `visualDensity: compact` (~34px) in steppers and slot cards | Inconvenient for gloved fingers; risk of mis-clicking Remove instead of Lock | Touch targets enlarged to $\ge 44 \times 44$px across all interactive controls (Counters, Lock toggles, Channel Pickers, Steppers) |
| **Tactile Separation** | Low-contrast borders (`outlineVariant` with low alpha) | Cards blend into background under harsh daylight | Micro-borders (1.2px, `#CBD5E1` in light, `#2A3441` in dark) with subtle elevation |
| **Color Semantics** | Hardcoded or fixed theme expectations | Need consistent adaptive semantic tokens across themes | Standard (5.8G): `#0265DC` / `#00E5FF`<br>Lowband (5.3G): `#B45309` / `#FFB300`<br>X-Band (4.9G): `#047857` / `#00E676`<br>Collisions: `#DC2626` / `#FF5252` |
| **Theme Switching** | Hardcoded dark mode in `main.dart` | No way to adapt to changing ambient light | 1-tap Theme Switcher in `AppBar.actions` powered by Riverpod `themeModeProvider` |

---

## 3. Architecture & Specifications

### 3.1. State Management (`theme_provider.dart`)
Canonical Riverpod 2.x `Notifier<ThemeMode>`:
```dart
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
```
- Default: `ThemeMode.dark` (preserves backward compatibility with existing tests and night baseline).
- Supports `.toggleTheme()` and `.setThemeMode(ThemeMode)`.

### 3.2. Theme Specifications (`app_theme.dart`)
- **`AppTheme.lightTheme` ("UI Max Pro")**:
  - `brightness`: `Brightness.light`
  - `scaffoldBackgroundColor`: `Color(0xFFF8FAFC)`
  - `colorScheme`:
    - `primary`: `Color(0xFF0265DC)`
    - `onPrimary`: `Color(0xFFFFFFFF)`
    - `secondary`: `Color(0xFFB45309)`
    - `tertiary`: `Color(0xFF047857)`
    - `error`: `Color(0xFFDC2626)`
    - `surface`: `Color(0xFFFFFFFF)`
    - `surfaceContainerHighest`: `Color(0xFFF1F5F9)`
    - `onSurface`: `Color(0xFF0F172A)`
    - `onSurfaceVariant`: `Color(0xFF334155)`
    - `outlineVariant`: `Color(0xFFCBD5E1)`
- **`AppTheme.darkTheme` (Tactical Neon Cyan)**:
  - Preserved and enhanced with identical semantic slot mappings.

### 3.3. File Line Limits & Widget Decomposition
To strictly satisfy the `< 300` line threshold:
- `manual_drone_slot_card.dart`: Decomposed by extracting slot header and channel picker button.
- `rf_spectrum_chart.dart`: Decomposed by extracting legend and selected board card.

---

## 4. Verification & Testing

- 100% test pass rate across unit and widget tests.
- Static analysis clean: 0 warnings, 0 errors.
- `flutter-culture-check`: 0 violations (zero hardcoded `Colors.*`).
- File line limits: all files $< 300$ lines.
