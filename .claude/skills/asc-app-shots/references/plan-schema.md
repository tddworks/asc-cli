# ScreenPlan JSON Schema

The `ScreenPlan` is the core data structure written by the `asc-app-shots` skill and consumed by `asc app-shots generate`.

## Full Schema

```json
{
  "appId": "string — App Store app ID (e.g. '6736834466')",
  "appName": "string — localized app name from AppInfoLocalization",
  "tagline": "string — 5-8 word marketing tagline for the app",
  "tone": "string — one of: minimal | playful | professional | bold | elegant",
  "colors": {
    "primary": "string — hex color for background (e.g. '#0a0a0a')",
    "accent": "string — hex color for highlights/CTAs (e.g. '#3b82f6')",
    "text": "string — hex color for heading text (e.g. '#FFFFFF')",
    "subtext": "string — hex color for subheading text (e.g. '#94A3B8')"
  },
  "screens": [
    {
      "index": "number — 0-based screen order",
      "screenshotFile": "string — filename of the screenshot (e.g. 'IMG_7141.PNG')",
      "heading": "string — 2-5 word headline for this screen",
      "subheading": "string — 6-12 word supporting text for this screen",
      "layoutMode": "string — one of: center | left | tilted",
      "visualDirection": "string — 1-2 sentence description of what the screenshot shows",
      "imagePrompt": "string — Gemini image generation prompt (see rules below)"
    }
  ]
}
```

---

## imagePrompt Writing Rules (CRITICAL)

This prompt is sent directly to Gemini image generation along with the actual screenshot.
Write 1-3 concise sentences following this structure:

**Formula:**
```
"Generate a [premium/cinematic/modern] App Store [hero/feature/showcase] screenshot.
The uploaded iPhone UI is displayed in a [style] device mockup [angle] [position].
Bold [color] heading '[EXACT heading text]' [placement], with [color] subtext '[EXACT subheading]' [placement].
[Background: hex color, glow/gradient/particles]. [Atmosphere/quality descriptors]."
```

**Rules:**
1. Always start with "Generate a [adjective] App Store screenshot"
2. Always include **exact heading and subheading text** quoted — Gemini renders them
3. Specify device angle: "centered", "tilted ~8 degrees", "positioned left/right"
4. Include background hex color and lighting effect (radial glow, gradient, bokeh)
5. End with quality/style descriptors: "Minimal, editorial, premium quality"
6. 1-3 sentences max — be concise, let Gemini be creative with composition

**Tips from AppShots:**
- Be concise — 1-3 sentences work best
- Describe the creative perspective and device angle
- Include the heading text you want rendered
- Mention colors, mood, and atmosphere
- Let the AI be creative — don't over-specify

---

## Tone Guide

| Tone | Background | Accent | Best for |
|------|-----------|--------|----------|
| `minimal` | `#0a0a0a`–`#1a1a2e` | blue/indigo | Productivity, tools, utilities |
| `playful` | bright vibrant | warm colors | Games, kids, lifestyle |
| `professional` | navy/slate `#0d1b2a` | blue `#4A7CFF` | Business, finance, enterprise |
| `bold` | high contrast dark | vivid saturated | Sports, media, entertainment |
| `elegant` | rich dark gradient | gold/cream | Fashion, luxury, wellness |

## Layout Mode Guide

| Mode | Description | imagePrompt device phrase |
|------|-------------|--------------------------|
| `center` | Device centered, big (80% canvas) | "centered on the canvas" |
| `left` | Device on left side (65% width) | "positioned to the left, text on right side" |
| `tilted` | Device tilted ~8 degrees | "in a sleek tilted device mockup (~8 degrees)" |

---

## Complete Example

```json
{
  "appId": "6736834466",
  "appName": "TaskFlow",
  "tagline": "Organize your life, effortlessly",
  "tone": "minimal",
  "colors": {
    "primary": "#0a0a0a",
    "accent": "#3b82f6",
    "text": "#FFFFFF",
    "subtext": "#94A3B8"
  },
  "screens": [
    {
      "index": 0,
      "screenshotFile": "IMG_7141.PNG",
      "heading": "Work Smarter",
      "subheading": "Organize all your tasks in one beautiful place",
      "layoutMode": "center",
      "visualDirection": "Main dashboard showing a list of tasks with colored priority badges",
      "imagePrompt": "Generate a premium App Store hero screenshot. The uploaded iPhone UI is displayed in a sleek tilted device mockup (~8 degrees) centered on a near-black canvas (#0a0a0a). Bold white heading 'Work Smarter' sits above the device, with soft blue-gray subtext 'Organize all your tasks in one beautiful place' below. A deep electric blue radial glow (#3b82f6) pulses behind the device. Floating micro-dots and a subtle light streak add cinematic depth. Minimal, editorial, premium quality."
    },
    {
      "index": 1,
      "screenshotFile": "IMG_7142.PNG",
      "heading": "Stay on Track",
      "subheading": "Smart reminders that fit your schedule",
      "layoutMode": "left",
      "visualDirection": "Calendar view showing scheduled tasks with a notification popup",
      "imagePrompt": "Generate a modern App Store feature screenshot. The uploaded iPhone UI is positioned to the left of the canvas, tilted slightly right on a deep navy background (#0d1b2a). Bold white heading 'Stay on Track' appears on the right side, with muted blue subtext 'Smart reminders that fit your schedule' below. Soft blue accent glow (#3b82f6) radiates from behind the device. Professional depth-of-field atmosphere, clean editorial quality."
    }
  ]
}
```
