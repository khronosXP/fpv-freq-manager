# FPV Frequency Manager (Менеджер відеочастот FPV)

> **Автономний калькулятор та менеджер відеочастот 5.8 GHz для інструкторів та пілотів БПЛА**  
> *Розробка команди Дизармерів Ф-22*

[![Deploy PWA to GitHub Pages](https://github.com/khronosXP/fpv-freq-manager/actions/workflows/deploy.yml/badge.svg)](https://github.com/khronosXP/fpv-freq-manager/actions/workflows/deploy.yml)
[![Live Demo](https://img.shields.io/badge/PWA-Live%20Demo-00E5FF?logo=googlechrome&logoColor=white)](https://khronosXP.github.io/fpv-freq-manager/)

---

## 🎯 Призначення та можливості

Додаток призначений для оперативного розрахунку чистих аналогових відеочастот 5.8 GHz під час групових польотів (до 12 бортів одночасно) з повним захистом від взаємних завад та інтермодуляції 3-го порядку (IMD3).

- **100% автономність (Offline-First PWA)**: працює без доступу до мережі Інтернет у польових умовах. Може встановлюватися як нативний додаток на Android, iOS, Windows, macOS, Linux.
- **Підтримка класичних та розширених діапазонів**:
  - **Класичні сітки 5.8 GHz (A, B, E, F, R)**: 40 каналів (макс. 6 бортів без завад).
  - **Lowband (5.3 GHz)**: канали L1–L8 (5333–5613 MHz).
  - **X-band (4.9 GHz)**: канали X1–X8 (4990–5200 MHz).
- **Математичне ядро Zero-Latency (0–9 мс)**: алгоритм пошуку комбінацій з усуненням симетрії (Symmetry Breaking) та миттєвим раннім відсіканням (Early Capacity Pruning).
- **Візуалізація радіоспектра**: інтерактивний горизонтальний графік з відмітками каналів та інтермодуляційних зон.
- **Шпаргалка частот (Cheat-Sheet)**: кольорове маркування за типами обладнання та копіювання готової сітки в буфер обміну для рації.

---

## 📐 Фізико-математичні критерії

1. **Захисний міжканальний інтервал**:
   $$\Delta f \ge 40\text{ MHz}$$
   Запобігає накладанню спектральних сплесків FM-відеосигналу (Carson Bandwidth ~27–30 MHz) на смугу пропускання суміжних VRX-приймачів.
2. **Захист від інтермодуляції 3-го порядку (Two-Tone IMD3)**:
   $$|2f_1 - f_2 - f_3| \ge 10\text{ MHz}$$
   Виключає утворення хибних комбінаційних частот 3-го порядку в нелінійних елементах вхідних каскадів (LNA/змішувач) приймачів.
3. **Поляризація**:
   Всі розрахунки базуються на використанні кругової правої поляризації (**RHCP**).

---

## 🚀 Встановлення та запуск

### Використання онлайн (PWA)
Перейдіть за посиланням: **[https://khronosXP.github.io/fpv-freq-manager/](https://khronosXP.github.io/fpv-freq-manager/)**  
У браузері виберіть **«Додати на головний екран»** / **«Встановити додаток»**.

### Локальна збірка та розробка
```bash
# Клонування репозиторію
git clone git@github.com:khronosXP/fpv-freq-manager.git
cd fpv-freq-manager

# Отримання залежностей
flutter pub get

# Запуск тестів
flutter test

# Збірка веб-релізу
flutter build web --release
```

---

## 🛠 Технічний стек

- **Фреймворк**: Flutter 3.x (Web PWA, Android, Desktop)
- **Архітектура**: Clean Architecture / Feature-Driven
- **Управління станом**: Riverpod 2.x (`NotifierProvider`)
- **Дизайн-система**: Material 3 (Tactical HUD Dark Theme, High-Contrast)
- **CI/CD**: GitHub Actions (`deploy.yml`) -> GitHub Pages (`gh-pages`)

---

*Розроблено командою Дизармерів Ф-22 для інструкторів та пілотів FPV БПЛА.*
