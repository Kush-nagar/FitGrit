# Akira Chatbot - Visual UI Guide

This document describes the visual design and user interface of the Akira chatbot.

## 🎨 Color Palette

### Akira's Messages

- Background: `#2E2E2E` (Dark surface)
- Text: `#FFFFFF` (White)
- Border: `#3D4040` with 30% opacity
- Avatar: Gradient from `#45C588` (Lime) to `#03DEEE` (Blue)

### User Messages

- Background: Gradient from `#45C588` (Lime) to `#45C588` (Lime, full opacity)
- Text: `#1C1C1C` (Dark - contrasts with lime background)
- Avatar: `#6A6AED` (Purple)

### UI Elements

- App Bar Background: `#1C1C1C` (Dark background)
- Screen Background: `#1C1C1C` (Dark background)
- Input Field Background: `#1C1C1C` (Dark background)
- Input Container: `#2E2E2E` (Dark surface)
- Send Button: Gradient from `#45C588` (Lime) to `#03DEEE` (Blue)
- Send Button (Disabled): Grey gradient
- Border Colors: `#3D4040` with opacity variations

## 📱 Screen Layout

```
┌─────────────────────────────────────┐
│  ← Akira               🗨️ 🗑️       │ ← App Bar
│    Health & Fitness Assistant       │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🤖 Akira's Message          │   │ ← Akira Message
│  │ Hello! I'm Akira...         │   │
│  └─────────────────────────────┘   │
│                                     │
│             ┌───────────────────┐   │
│             │ User's Message   👤│  │ ← User Message
│             │ Tell me about... │   │
│             └───────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🤖 Akira's Response...       │   │ ← Streaming
│  │ Great question! Here's...   │   │    Response
│  │ ⏳ Generating...             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🤖 • • •                     │   │ ← Typing
│  └─────────────────────────────┘   │    Indicator
│                                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────┐  🚀   │ ← Input Area
│ │ Ask Akira anything...   │       │
│ └─────────────────────────┘       │
└─────────────────────────────────────┘
```

## 🎭 UI Components

### 1. App Bar

```
┌──────────────────────────────────────┐
│ ← [Akira Avatar] Akira        🗑️     │
│    Health & Fitness Assistant        │
└──────────────────────────────────────┘
```

- **Back Button**: Standard iOS/Android back arrow
- **Avatar**: 40x40px circle with lime-to-blue gradient
- **Title**: "Akira" in bold, white text
- **Subtitle**: "Health & Fitness Assistant" in grey
- **Clear Button**: Trash icon to clear chat history

### 2. Message Bubbles

#### Akira's Message

```
┌────────┐  ┌─────────────────────────────┐
│   🤖   │  │ Hello! I'm here to help     │
│ Lime-  │  │ with your health journey.   │
│ Blue   │  │                             │
│ Circle │  │ [Streaming indicator]       │
└────────┘  └─────────────────────────────┘
   36px        Rounded corners (4, 20, 20, 20)
```

- **Position**: Left-aligned
- **Avatar**: 36px circle with gradient
- **Bubble**: Dark surface with subtle border
- **Text**: White, 14px, line height 1.5
- **Corners**: Top-left 4px, others 20px

#### User's Message

```
               ┌─────────────────────────┐  ┌────────┐
               │ What are some healthy   │  │   👤   │
               │ breakfast ideas?        │  │ Purple │
               │                         │  │ Circle │
               └─────────────────────────┘  └────────┘
                  Rounded corners (20, 4, 20, 20)      36px
```

- **Position**: Right-aligned
- **Avatar**: 36px purple circle with person icon
- **Bubble**: Lime green gradient
- **Text**: Dark, 14px, line height 1.5
- **Corners**: Top-right 4px, others 20px

### 3. Typing Indicator

```
┌────────┐  ┌─────────────────┐
│   🤖   │  │  • • •          │
└────────┘  └─────────────────┘
```

- **Three dots**: Animated with staggered fade
- **Animation**: 1.5 second loop
- **Color**: Lime green with opacity cycling
- **Size**: 8px circles

### 4. Streaming Indicator

```
┌──────────────────────────────────┐
│ Great question! Here are some... │
│                                  │
│ ⏳ Generating...                 │
└──────────────────────────────────┘
```

- **Icon**: Small circular progress (12px)
- **Text**: "Generating..." in italic grey
- **Position**: Below message content

### 5. Input Area

```
┌────────────────────────────────────────┐
│  ┌──────────────────────────────┐  🚀 │
│  │ Ask Akira anything...        │     │
│  └──────────────────────────────┘     │
└────────────────────────────────────────┘
```

- **Container**: Dark surface background
- **Text Field**: Dark background, rounded (25px)
- **Placeholder**: Grey, 14px
- **Send Button**: 50px circle with gradient
- **Icon**: White send arrow (or hourglass when typing)

## 🎬 Animations

### 1. Typing Dots Animation

```
Frame 1:  ● ○ ○
Frame 2:  ○ ● ○
Frame 3:  ○ ○ ●
Frame 4:  ○ ● ○
```

- Duration: 1.5 seconds
- Loop: Continuous
- Effect: Opacity fade in/out

### 2. Streaming Text

```
"Hello"
"Hello! I'm"
"Hello! I'm Akira"
"Hello! I'm Akira. How"
...
```

- Effect: Text appears chunk by chunk
- Speed: As received from API
- Indicator: Spinning circle while generating

### 3. Message Entry

```
Opacity: 0 → 1
Position: +30px → 0px
Duration: 300ms
```

- Fade in effect
- Slight upward slide
- Smooth easing

### 4. Auto-Scroll

```
Scroll Position: current → bottom
Duration: 300ms
Curve: easeOut
```

- Triggers on new message
- Smooth animation
- Slight delay (100ms)

## 📐 Dimensions & Spacing

### Avatars

- Size: 36x36 pixels
- Shape: Circle
- Margin: 2.w (responsive width)

### Message Bubbles

- Padding: 4.w horizontal, 2.h vertical
- Max Width: ~80% of screen
- Corner Radius: 4-20px (varies by corner)
- Margin Bottom: 3.h

### Input Area

- Padding: 3.w all around
- Text Field Height: ~50px (auto with content)
- Send Button: 50x50 pixels
- Gap: 2.w between field and button

### Spacing Units

- Using Sizer package:
  - `w` = percentage of screen width
  - `h` = percentage of screen height
  - Example: `4.w` ≈ 4% of screen width

## 🎨 Theme Integration

### Matches App Theme

- Uses `AppTheme.backgroundDark` (#1C1C1C)
- Uses `AppTheme.surfaceDark` (#2E2E2E)
- Uses `AppTheme.primaryLime` (#45C588)
- Uses `AppTheme.accentBlue` (#03DEEE)
- Uses `AppTheme.accentPurple` (#6A6AED)
- Uses `AppTheme.textPrimary` (#FFFFFF)
- Uses `AppTheme.textSecondary` (#888F92)

### Consistent with App

- Same color scheme as other screens
- Matches card styles
- Compatible with dark mode
- Uses established gradients

## 📱 Responsive Design

### Screen Sizes

- **Small phones**: Optimized with Sizer
- **Large phones**: Scales proportionally
- **Tablets**: Maintains readable layout

### Text Scaling

- Respects system text size settings
- Minimum readable size maintained
- Maximum size prevents overflow

### Orientation

- Portrait: Primary design
- Landscape: Adapts with scroll

## ✨ Visual Polish

### Shadows

- Message bubbles: Subtle depth
- Send button: Glowing effect with lime shadow
- Avatar icons: None (flat design)

### Borders

- Input field: 1px grey with opacity
- Akira messages: 1px grey with 30% opacity
- User messages: No border (solid gradient)

### Gradients

- Akira avatar: Lime to blue diagonal
- Send button: Lime to blue diagonal
- User message bubble: Lime gradient
- Chat button (home): Lime to blue diagonal

## 🎯 Accessibility

### Contrast Ratios

- White on dark: ✅ WCAG AAA compliant
- Dark on lime: ✅ WCAG AA compliant
- Grey text: ✅ WCAG AA for large text

### Touch Targets

- Send button: 50x50px ✅ (minimum 44x44)
- Clear button: 48x48px ✅
- Message bubbles: Full width ✅

### Readability

- Font size: 14px (readable)
- Line height: 1.5 (comfortable)
- Spacing: Generous padding

## 🖼️ Icon Reference

### Used Icons

- `Icons.chat_bubble_rounded` - Akira avatar
- `Icons.psychology_rounded` - AI brain icon (alternative)
- `Icons.person_rounded` - User avatar
- `Icons.send_rounded` - Send message
- `Icons.hourglass_empty` - Typing/waiting state
- `Icons.delete_outline` - Clear chat

### Icon Sizes

- App bar icons: 22px
- Avatar icons: 20px
- Send button icon: 22px

## 🌟 Special Effects

### Welcome Message

- Appears immediately on open
- Styled as Akira message
- Multi-line with bullet points
- Engaging introduction

### Gradient Effects

- Smooth color transitions
- Diagonal direction (topLeft to bottomRight)
- Multiple gradients for depth

### Haptic Feedback

- Not implemented by default
- Can be added with `HapticFeedback.mediumImpact()`

---

This UI design creates a modern, cohesive chatbot experience that feels native to your app while providing clear visual feedback and an engaging user experience! 🎨✨
