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
    "primary": "string — hex color for background/primary elements (e.g. '#1A1A2E')",
    "accent": "string — hex color for highlights/CTAs (e.g. '#E94560')",
    "text": "string — hex color for heading text (e.g. '#FFFFFF')",
    "subtext": "string — hex color for subheading text (e.g. '#CCCCCC')"
  },
  "screens": [
    {
      "index": "number — 0-based screen order",
      "screenshotFile": "string — path to screenshot file",
      "heading": "string — 2-5 word headline for this screen",
      "subheading": "string — 6-12 word supporting text for this screen",
      "layoutMode": "string — one of: center | left | tilted",
      "visualDirection": "string — 1-2 sentence description of what the screenshot shows",
      "imagePrompt": "string — detailed prompt for AI image enhancement of this screen"
    }
  ]
}
```

## Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `appId` | Yes | App Store Connect app ID |
| `appName` | Yes | Localized app name |
| `tagline` | Yes | Short marketing tagline |
| `tone` | Yes | Visual/messaging tone |
| `colors.primary` | Yes | Background hex color |
| `colors.accent` | Yes | Accent/highlight hex color |
| `colors.text` | Yes | Heading text hex color |
| `colors.subtext` | Yes | Subheading text hex color |
| `screens[].index` | Yes | 0-based ordering index |
| `screens[].screenshotFile` | Yes | Path to the source screenshot |
| `screens[].heading` | Yes | Short headline text |
| `screens[].subheading` | Yes | Supporting subheadline text |
| `screens[].layoutMode` | Yes | How text overlays the image |
| `screens[].visualDirection` | Yes | What the screenshot shows |
| `screens[].imagePrompt` | Yes | Prompt for image enhancement AI |

## Tone Guide

| Tone | Best for | Example headings |
|------|----------|-----------------|
| `minimal` | Productivity, tools, utilities | "Focus. Ship." / "Less noise." |
| `playful` | Games, kids, lifestyle | "Level up your day!" / "Fun starts here" |
| `professional` | Business, finance, enterprise | "Enterprise-grade security" / "Your team, in sync" |
| `bold` | Sports, media, entertainment | "DOMINATE YOUR GOALS" / "STREAM EVERYTHING" |
| `elegant` | Fashion, luxury, wellness | "Effortless beauty" / "Curated for you" |

## Layout Mode Guide

| Mode | Description | Best for |
|------|-------------|----------|
| `center` | Text centered, screenshot as full background | Clean, impactful single-feature screens |
| `left` | Text on left, screenshot on right | Feature comparison screens |
| `tilted` | Screenshot at slight angle with shadow, text beside | Premium feel, depth |

## Complete Example

```json
{
  "appId": "6736834466",
  "appName": "TaskFlow",
  "tagline": "Organize your life, effortlessly",
  "tone": "professional",
  "colors": {
    "primary": "#0F172A",
    "accent": "#6366F1",
    "text": "#F8FAFC",
    "subtext": "#94A3B8"
  },
  "screens": [
    {
      "index": 0,
      "screenshotFile": "screen1.png",
      "heading": "Work Smarter",
      "subheading": "Organize all your tasks in one beautiful place",
      "layoutMode": "center",
      "visualDirection": "Main dashboard showing a list of tasks with colored priority badges and completion checkboxes",
      "imagePrompt": "Clean dark dashboard UI with colorful task cards, subtle gradient background, minimalist typography, depth of field blur on background elements"
    },
    {
      "index": 1,
      "screenshotFile": "screen2.png",
      "heading": "Stay on Track",
      "subheading": "Smart reminders that fit your schedule",
      "layoutMode": "left",
      "visualDirection": "Calendar view showing scheduled tasks with a notification popup",
      "imagePrompt": "Calendar UI with soft purple accent colors, notification card floating above with gentle shadow, light mode with warm undertones"
    },
    {
      "index": 2,
      "screenshotFile": "screen3.png",
      "heading": "Team Sync",
      "subheading": "Collaborate seamlessly with your team",
      "layoutMode": "tilted",
      "visualDirection": "Team collaboration view showing multiple user avatars and shared task assignments",
      "imagePrompt": "Team collaboration screen with avatar circles, shared task list, blurred background with depth, professional corporate aesthetic"
    }
  ]
}
```