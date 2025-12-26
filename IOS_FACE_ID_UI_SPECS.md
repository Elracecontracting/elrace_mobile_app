# 🍎 iOS Face ID UI Specifications

## Visual Hierarchy

```
┌─────────────────────────────────────────┐
│                                         │
│           [Backdrop Blur]               │
│        Black @ 40% opacity              │
│                                         │
│         ┌─────────────────┐             │
│         │                 │             │
│         │  ╔═══════════╗  │             │
│         │  ║           ║  │             │
│         │  ║    [●]    ║  │ ← Face ID   │
│         │  ║           ║  │   Icon      │
│         │  ╚═══════════╝  │   (pulse)   │
│         │                 │             │
│         │  Confirm Action │ ← Title     │
│         │                 │             │
│         │ Use Face ID to  │ ← Subtitle  │
│         │ verify check-in │             │
│         │                 │             │
│         │   [● Success]   │ ← State     │
│         │                 │   (hidden   │
│         └─────────────────┘    until    │
│                                done)    │
│                                         │
└─────────────────────────────────────────┘
```

---

## Component Breakdown

### 1. Background Layer

```
Full Screen Container
├─ Color: CupertinoColors.black @ 40%
└─ Blur: 10pt (backdrop filter)
```

### 2. Sheet Container

```
Centered Container (320pt width)
├─ Background: SystemGrey6 (dark) @ 92%
├─ Border Radius: 28pt
├─ Border: White @ 10%, 0.5pt
├─ Shadow: 40pt blur, 20pt offset
└─ Blur: 30pt (backdrop filter)
```

### 3. Face ID Icon Circle

```
Container (80pt × 80pt)
├─ Shape: Circle
├─ Background: Icon color @ 15%
└─ Icon: person_crop_circle_badge_checkmark
    ├─ Size: 44pt
    └─ Color: Dynamic (blue/green/red/white)
```

### 4. Typography

```
Title
├─ Font Size: 20pt
├─ Weight: 600 (semibold)
├─ Color: White
└─ Letter Spacing: 0.2pt

Subtitle
├─ Font Size: 15pt
├─ Weight: 400 (regular)
├─ Color: White @ 70%
└─ Line Height: 1.3
```

---

## State Colors

| State          | Icon Color   | Background  |
| -------------- | ------------ | ----------- |
| Idle           | White        | Gray        |
| Authenticating | System Blue  | Blue @ 15%  |
| Success        | System Green | Green @ 15% |
| Failed         | System Red   | Red @ 15%   |
| Cancelled      | White        | Gray        |

---

## Animation Specifications

### Entrance (300ms)

```
Property: Scale
├─ From: 0.96
├─ To: 1.0
└─ Curve: easeOutCubic

Property: Opacity
├─ From: 0.0
├─ To: 1.0
└─ Curve: easeOut
```

### Pulse (Continuous during auth)

```
Property: Scale (icon only)
├─ From: 1.0
├─ To: 1.08
├─ Duration: Repeating
└─ Curve: easeInOut
```

### Exit (300ms)

```
Property: Reverse entrance
├─ Scale: 1.0 → 0.96
├─ Opacity: 1.0 → 0.0
└─ Curve: easeInCubic
```

---

## Spacing & Padding

```
Sheet Container
├─ Width: 320pt (fixed)
├─ Padding Horizontal: 32pt
├─ Padding Vertical: 40pt
└─ Spacing:
    ├─ Icon → Title: 24pt
    ├─ Title → Subtitle: 8pt
    └─ Subtitle → State: 16pt
```

---

## Shadow Specifications

```
Primary Shadow
├─ Color: Black @ 30%
├─ Blur Radius: 40pt
├─ Offset: (0, 20)
└─ Spread: 0pt
```

---

## Blur Specifications

```
Background Blur (backdrop)
├─ Sigma X: 10pt
└─ Sigma Y: 10pt

Sheet Content Blur
├─ Sigma X: 30pt
└─ Sigma Y: 30pt
```

---

## Responsive Behavior

### Portrait (Default)

- Sheet centered vertically & horizontally
- Width: 320pt fixed
- Height: Auto (content-based)

### Landscape

- Sheet centered vertically & horizontally
- Width: 320pt fixed
- Height: Auto (content-based)

### Small Devices (< 375pt width)

- Sheet maintains 320pt width
- May slightly overflow horizontally
- Still centered

---

## Interaction States

### Initial

```
Background: Visible
Sheet: Animating in (scale + fade)
Icon: Static white
Text: Visible
State: Hidden
```

### Authenticating

```
Background: Visible
Sheet: Fully visible
Icon: Blue, pulsing
Text: Visible
State: Hidden
```

### Success

```
Background: Visible
Sheet: Fully visible
Icon: Green, static
Text: Visible
State: "Success" with checkmark
Duration: Brief (auto-dismiss)
```

### Failed

```
Background: Visible
Sheet: Fully visible
Icon: Red, static
Text: Visible
State: Error message
Duration: 1.5s then auto-dismiss
```

### Cancelled

```
Background: Visible
Sheet: Animating out
Icon: White, static
Text: Visible
State: Hidden
Duration: Dismissing
```

---

## Accessibility

### VoiceOver Labels

```dart
// Icon container
Semantics(
  label: 'Face ID authentication',
  child: Icon(...),
)

// Title
Semantics(
  header: true,
  label: widget.title,
  child: Text(...),
)

// Subtitle
Semantics(
  label: widget.subtitle,
  child: Text(...),
)
```

### Tap Targets

```
Backdrop: Full screen (cancels)
Sheet: 320pt × auto (prevents cancel)
```

---

## Dark Mode vs Light Mode

### Dark Mode (Primary)

```
Sheet Background: SystemGrey6.darkColor @ 92%
Text: White / White @ 70%
Icons: Colored (blue/green/red/white)
Border: White @ 10%
```

### Light Mode (Automatic)

```
Sheet Background: SystemGrey6.color @ 92%
Text: Black / Black @ 70%
Icons: Colored (blue/green/red/black)
Border: Black @ 10%
```

**Note:** Colors use Cupertino dynamic colors, so light mode is automatically supported.

---

## iOS Design References

This implementation follows:

- [Apple Human Interface Guidelines - Modality](https://developer.apple.com/design/human-interface-guidelines/modality)
- [SF Symbols Guidelines](https://developer.apple.com/sf-symbols/)
- [iOS Motion Design](https://developer.apple.com/design/human-interface-guidelines/motion)
- Apple Pay authentication pattern
- iCloud Keychain unlock pattern

---

## Code Snippet for Reference

```dart
// Premium frosted glass container
Container(
  width: 320,
  decoration: BoxDecoration(
    color: CupertinoColors.systemGrey6.darkColor.withOpacity(0.92),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: CupertinoColors.white.withOpacity(0.1),
      width: 0.5,
    ),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.black.withOpacity(0.3),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: /* Content */,
    ),
  ),
)
```

---

**Designed to Apple's standards. Every pixel intentional. ✨**
