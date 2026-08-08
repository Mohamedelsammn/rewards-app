---
name: Lumina Rewards
colors:
  surface: '#fcf8ff'
  surface-dim: '#dbd8e5'
  surface-bright: '#fcf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f2ff'
  surface-container: '#efecf9'
  surface-container-high: '#e9e6f4'
  surface-container-highest: '#e4e1ee'
  on-surface: '#1b1b24'
  on-surface-variant: '#454555'
  inverse-surface: '#302f39'
  inverse-on-surface: '#f2effc'
  outline: '#767587'
  outline-variant: '#c6c4d8'
  surface-tint: '#4446e4'
  primary: '#4042e1'
  on-primary: '#ffffff'
  primary-container: '#5b5ffb'
  on-primary-container: '#fefaff'
  inverse-primary: '#c0c1ff'
  secondary: '#712ae2'
  on-secondary: '#ffffff'
  secondary-container: '#8a4cfc'
  on-secondary-container: '#fffbff'
  tertiary: '#964200'
  on-tertiary: '#ffffff'
  tertiary-container: '#bd5500'
  on-tertiary-container: '#fffaf9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#05006c'
  on-primary-fixed-variant: '#2826cd'
  secondary-fixed: '#eaddff'
  secondary-fixed-dim: '#d2bbff'
  on-secondary-fixed: '#25005a'
  on-secondary-fixed-variant: '#5a00c6'
  tertiary-fixed: '#ffdbca'
  tertiary-fixed-dim: '#ffb68e'
  on-tertiary-fixed: '#331200'
  on-tertiary-fixed-variant: '#773300'
  background: '#fcf8ff'
  on-background: '#1b1b24'
  surface-variant: '#e4e1ee'
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-sm:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 20px
  stack-gap-sm: 12px
  stack-gap-md: 24px
  grid-gutter: 16px
---

## Brand & Style

The design system is engineered to evoke a sense of "Premium Playfulness." It targets a modern mobile audience that values high-end aesthetics but seeks the dopamine hit of gamification. The visual language bridges Apple's minimalist rigor with vibrant, energetic accents typical of high-stakes reward platforms.

The style is **Glassmorphic Minimalism**. It utilizes heavy whitespace and a restricted light-mode palette, punctuated by translucent layers and soft background blurs. This creates a "breathable" interface where primary actions feel tactile and rewarding. The emotional response should be one of anticipation, trust, and delight.

## Colors

The palette is anchored in a clean, clinical white-to-blue-grey foundation to ensure the "Premium" feel. The primary and secondary colors are used for interactive states and brand-heavy moments, while the gold accent is reserved strictly for high-value rewards, "win" states, and premium callouts.

- **Primary & Secondary:** Used in gradients (from 5B5FFB to 7C3AED) to signify progression or active states.
- **Surface:** Always #FFFFFF with varying levels of opacity when used as glass overlays.
- **Success:** A vibrant emerald for positive reinforcement during reward claims.
- **Gradients:** Use soft, linear 135-degree gradients for primary buttons and progress bars.

## Typography

This design system utilizes **Plus Jakarta Sans** for headlines to provide a soft, approachable, yet modern geometric feel. **Manrope** is used for body and functional text to maintain high legibility and a refined professional tone.

- **Headlines:** Feature tight letter-spacing to create a "locked-up" editorial look.
- **Body Text:** Uses generous line heights (1.5x) to prevent visual clutter in text-heavy descriptions.
- **Labels:** Small caps or bold weights are used for category tags and metadata to create a clear hierarchy against body copy.

## Layout & Spacing

The layout follows a **fluid-to-safe-margin** philosophy. On mobile, content is contained within a 20px horizontal margin. The vertical rhythm is strictly based on an 8px baseline grid.

- **Card Spacing:** 16px gutter between cards in a vertical feed.
- **Sectioning:** Large 40px to 48px vertical gaps between major content sections to emphasize the minimalist, "Apple-esque" use of whitespace.
- **Safe Areas:** All floating elements (like the navigation bar) must maintain a 16px distance from the bottom safe area and side margins.

## Elevation & Depth

Depth is achieved through **Soft Ambient Shadows** and **Backdrop Blurs**. Avoid harsh borders; instead, use elevation to define boundaries.

- **Level 1 (Cards):** Use a 0px 4px 20px shadow with a 5% opacity of the primary color to "lift" them from the background.
- **Level 2 (Floating Nav/Modals):** Use a Backdrop Filter (Blur: 20px) on a white surface with 80% opacity. Add a 1px inner border (white, 20% opacity) to simulate a glass edge.
- **Level 3 (Pop-overs):** Highest elevation with a 0px 12px 32px shadow (8% opacity) to focus the user's attention.

## Shapes

The shape language is defined by **large, friendly radii**.

- **Primary Cards:** Use a fixed 24px corner radius to create a "squircle" feel that is signature to premium mobile OS aesthetics.
- **Buttons:** Fully rounded (pill-shaped) for primary actions to encourage tapping.
- **Small Elements (Chips/Checkboxes):** 12px radius to maintain consistency with the larger card shapes.

## Components

### Floating Navigation Bar
A suspended glass element docked at the bottom. It uses a `backdrop-filter: blur(20px)` and contains haptic-enabled icons. The active state is indicated by a subtle glow or a small primary-colored dot below the icon.

### Reward Cards
24px rounded containers. The header of the card should use a subtle gradient background if it's a "featured" reward. Imagery should be high-quality, using `aspect-ratio: 16/9` and top-corner rounding that matches the card container.

### Buttons
- **Primary:** Pill-shaped, Primary-to-Secondary gradient, white text, with a subtle shadow that matches the gradient color.
- **Secondary:** White background with a 1px border of the Primary color.
- **Ghost:** No background, Primary color text, used for "Cancel" or "Dismiss."

### Progress Trackers
Thin, 8px height bars. The filled portion uses the Primary-to-Secondary gradient, while the unfilled portion is a soft grey (#E2E8F0). For gamified steps, use the Accent (#FFD54A) color for the final "Goal" node.

### Feedback Toasts
Small, glassmorphic overlays that slide from the top, providing instant "Reward Earned" or "Success" messaging using the Success color for iconography.
