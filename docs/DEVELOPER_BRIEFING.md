# Wolfsbit Website - Frontend Developer Briefing

**Document Date:** 2026-01-15
**Project Type:** Academic Research / Master's Thesis
**Deliverable:** Marketing/Information Website for iOS App

---

## Executive Summary

You're building a website for **Wolfsbit**, a chronic illness journaling iOS app developed as part of a master's thesis. The website serves as the public face of the research project: explaining what the app does, linking to download, displaying legal pages, and potentially collecting anonymized research data contributions from app users.

**This is an academic research project with no commercial intent.**

---

## Table of Contents

1. [Project Context](#project-context)
2. [Website Requirements](#website-requirements)
3. [Existing Content](#existing-content)
4. [Design System](#design-system)
5. [API Endpoints](#api-endpoints)
6. [Technical Recommendations](#technical-recommendations)
7. [Content Strategy](#content-strategy)
8. [Deployment](#deployment)

---

## Project Context

### What is Wolfsbit?

Wolfsbit is a **chronic illness journaling iOS app** designed to help patients with conditions like lupus, fibromyalgia, and chronic fatigue syndrome:

- **Voice-first interface** - Large microphone button for users experiencing fatigue/brain fog
- **On-device AI scoring** - A fine-tuned language model (Qwen2.5-3B) scores symptom severity locally
- **Privacy-focused** - All health data stays on the user's device
- **Doctor reports** - Generate PDF summaries for healthcare providers

### Research Goals

This is a master's thesis exploring:
1. AI-assisted health journaling for chronic illness patients
2. On-device ML inference for privacy-preserving health apps
3. Voice-first UX for cognitively impaired users

### Target Audience

| Audience | Website Goal |
|----------|--------------|
| **Patients** | Download app, understand features, trust privacy claims |
| **Healthcare Providers** | Understand report format, assess medical value |
| **Academic Reviewers** | See research context, methodology transparency |
| **TestFlight Testers** | Join beta, understand what they're testing |

### Key Messaging

1. **Privacy First** - "Your health data never leaves your device"
2. **Designed for Fatigue** - "Voice-first for days when typing is too much"
3. **Academic Research** - "Part of a master's thesis, not a commercial product"
4. **German Focus** - Initial testing with German patient groups

---

## Website Requirements

### Required Pages

| Page | Purpose | Priority |
|------|---------|----------|
| **Landing/Home** | Explain app, features, download CTA | P0 |
| **Privacy Policy** | Legal requirement, trust-building | P0 |
| **Terms of Service** | Legal requirement | P0 |
| **About/Research** | Academic context, methodology | P1 |
| **TestFlight Signup** | Beta tester recruitment | P1 |
| **Contact** | Feedback, research inquiries | P2 |

### Optional/Future Pages

| Page | Purpose | Priority |
|------|---------|----------|
| **FAQ** | Common questions, troubleshooting | P2 |
| **Data Contribution** | Explain opt-in research data sharing | P3 |
| **Press/Media** | Screenshots, press kit | P3 |

### Functional Requirements

1. **Responsive Design** - Mobile-first (users may visit from their phones)
2. **German/English** - Bilingual content (German primary, English secondary)
3. **Accessibility** - Target audience includes people with chronic illness
4. **Performance** - Fast load times, minimal JavaScript
5. **Analytics** - Privacy-focused (TelemetryDeck or Plausible recommended)

---

## Existing Content

### Legal Documents (Ready to Use)

Located in `docs/legal/`:

#### Privacy Policy (`privacy-policy.md`)
- Explains local-only data storage
- TelemetryDeck analytics disclosure
- Opt-in data contribution program
- GDPR-compliant language
- Contact: wolfsbit@inpyjamas.dev

#### Terms of Service (`terms-of-service.md`)
- Personal, non-commercial use
- Health disclaimer (not medical advice)
- Liability limitations
- German governing law

### App Feature Copy (From Documentation)

**LOG View:**
> "Voice-first symptom logging. Tap the microphone, speak naturally, and your symptoms are recorded. For days when typing feels like too much."

**DATA View:**
> "Track your health trends over time with visual charts. See patterns, identify flare-ups, and prepare for doctor visits."

**AI Scoring:**
> "On-device AI analyzes your entries and suggests activity scores (Remission, Mild, Moderate, Severe). All processing happens locally - your words never leave your phone."

**Privacy:**
> "Your health data is stored only on your device. No cloud sync, no accounts, no tracking. Export when you want, delete when you want."

### Activity Score Scale

| Score | Label | Description |
|-------|-------|-------------|
| 0 | Remission | No symptoms, feeling well |
| 1 | Mild | Minor symptoms, manageable |
| 2 | Moderate | Significant symptoms, functioning impaired |
| 3 | Severe | Severe symptoms, major impairment |

---

## Design System

The iOS app uses a design system that should inform the website:

### Colors

```css
:root {
  /* Primary */
  --color-highlight: #ff6347;     /* Tomato - accent color */
  --color-background: #ffffff;    /* White background */
  --color-text: #000000;          /* Black text */

  /* Secondary */
  --color-text-muted: #666666;    /* Secondary text */
  --color-border: #e0e0e0;        /* Subtle borders */
  --color-surface: #f5f5f5;       /* Card backgrounds */

  /* Activity Scores (for charts/badges) */
  --color-remission: #4CAF50;     /* Green */
  --color-mild: #8BC34A;          /* Light green */
  --color-moderate: #FF9800;      /* Orange */
  --color-severe: #F44336;        /* Red */
}
```

### Typography

```css
:root {
  /* Font Family */
  --font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', 'Helvetica Neue', sans-serif;

  /* Scale (matches iOS app) */
  --font-title: 2.5rem;           /* h1 - Large title */
  --font-heading: 1.5rem;         /* h2 - Section headers */
  --font-subheading: 1.125rem;    /* h3 - Subsection headers */
  --font-body: 1rem;              /* p - Body text */
  --font-caption: 0.875rem;       /* small - Captions, fine print */

  /* Weights */
  --weight-regular: 400;
  --weight-emphasis: 600;         /* For headings */
  --weight-strong: 700;           /* For titles */
}
```

### Spacing Scale

```css
:root {
  --space-xs: 0.25rem;   /* 4px */
  --space-sm: 0.5rem;    /* 8px */
  --space-md: 1rem;      /* 16px */
  --space-lg: 1.5rem;    /* 24px */
  --space-xl: 2rem;      /* 32px */
  --space-xxl: 2.5rem;   /* 40px */
  --space-xxxl: 3rem;    /* 48px */
  --space-huge: 4rem;    /* 64px */
}
```

### Design Principles

1. **Monochrome Base** - Black text on white, tomato accent for CTAs
2. **Clean Lines** - Borders over shadows, minimal decoration
3. **Generous Whitespace** - Users may have cognitive fatigue
4. **Large Touch Targets** - 44px minimum for buttons (accessibility)
5. **Continuous Corners** - Use `border-radius` with smooth curves

### Visual Style

- **Minimal** - Avoid visual clutter
- **Calm** - No aggressive animations or attention-grabbing elements
- **Trustworthy** - Academic/medical aesthetic, not startup/tech
- **Accessible** - High contrast, readable fonts, clear hierarchy

---

## API Endpoints

### Data Contribution Backend (Future)

If the website needs to receive anonymized research data:

**Endpoint:** `POST /api/contribute`

**Payload:**
```json
{
  "text": "Journal entry text...",
  "mlScore": 1,
  "userScore": 2
}
```

**Requirements:**
- No device ID, timestamps, or identifiers
- HTTPS only
- Rate limiting recommended
- Store in append-only format for research

**Response:**
```json
{
  "success": true
}
```

### Model Manifest (Existing)

The iOS app downloads ML models from Cloudflare R2:

**Model URL:**
```
https://pub-e89520e024ba41e299dfd77556755146.r2.dev/models/qwen2.5-3b-diary-q4_k_m.gguf
```

The website doesn't need to interact with this, but it may be referenced in technical documentation.

---

## Technical Recommendations

### Framework Options

Given the project scope (mostly static content, bilingual), consider:

| Option | Pros | Cons |
|--------|------|------|
| **Astro** | Fast, static-first, i18n support | Newer ecosystem |
| **Next.js** | Mature, great i18n, Vercel deploy | May be overkill |
| **11ty** | Simple, fast builds, markdown-friendly | Less modern DX |
| **Hugo** | Extremely fast, great for docs | Go templating curve |

**Recommendation:** Astro or Next.js for good i18n support and modern DX.

### Internationalization (i18n)

- **Primary Language:** German (de)
- **Secondary Language:** English (en)
- **URL Structure:** `/de/privacy` and `/en/privacy` or subdomain
- **Content:** Legal pages exist in English, need German translation

### Analytics

**Recommended:** TelemetryDeck or Plausible Analytics
- Privacy-focused (no cookies)
- GDPR-compliant
- Matches app's privacy stance

**Avoid:** Google Analytics (contradicts privacy messaging)

### Hosting

| Option | Pros |
|--------|------|
| **Vercel** | Easy deploy, good for Next.js/Astro |
| **Cloudflare Pages** | Already using R2 for models |
| **Netlify** | Simple, form handling built-in |
| **GitHub Pages** | Free, if static only |

---

## Content Strategy

### Landing Page Structure

```
┌─────────────────────────────────────────────────────────────┐
│  HERO                                                        │
│  "Track your chronic illness journey,                        │
│   your way, your device."                                    │
│                                                              │
│  [Download on App Store]  [Join TestFlight Beta]             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  PROBLEM                                                     │
│  "Living with chronic illness means good days and bad days.  │
│   Remembering symptoms for doctor visits is hard when        │
│   you're exhausted."                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  FEATURES (3 cards)                                          │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ Voice    │  │ AI       │  │ Doctor   │                   │
│  │ First    │  │ Scoring  │  │ Reports  │                   │
│  └──────────┘  └──────────┘  └──────────┘                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  PRIVACY                                                     │
│  "Your data stays on your device. Period.                    │
│   No accounts, no cloud, no tracking."                       │
│                                                              │
│  [Read Privacy Policy]                                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  RESEARCH                                                    │
│  "This app is part of academic research exploring            │
│   AI-assisted health journaling. No commercial intent."      │
│                                                              │
│  [Learn About the Research]                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  FOOTER                                                      │
│  Privacy Policy | Terms of Service | Contact                 │
│  © 2025-2026 Fabian Moron Zirfas                            │
└─────────────────────────────────────────────────────────────┘
```

### Research/About Page Content

**Sections:**

1. **Academic Context**
   - Part of master's thesis
   - University/program (if disclosed)
   - Research questions being explored

2. **Methodology**
   - On-device ML approach
   - Privacy-by-design decisions
   - User testing with German patient groups

3. **The Model**
   - Fine-tuned Qwen2.5-3B
   - Trained on lupus diary data
   - ~1.8 GB, runs locally on iPhone

4. **Data Contribution**
   - Opt-in program
   - What's collected (text + scores only)
   - What's NOT collected (no identifiers)
   - How it improves the model

5. **Contact**
   - Email: wolfsbit@inpyjamas.dev
   - Feedback welcome
   - Research collaboration inquiries

---

## Deployment

### Domain

**TBD** - Likely `wolfsbit.app` or `wolfsbit.de` or subdomain of `inpyjamas.dev`

### Environment Variables

```env
# Analytics (if using TelemetryDeck)
TELEMETRY_APP_ID=xxx

# API endpoint (if data contribution backend exists)
API_URL=https://api.wolfsbit.app

# App Store links
APP_STORE_URL=https://apps.apple.com/app/wolfsbit/id...
TESTFLIGHT_URL=https://testflight.apple.com/join/...
```

### Build & Deploy

```bash
# Development
npm run dev

# Build
npm run build

# Deploy (example for Vercel)
vercel --prod
```

---

## Assets Needed

### From Project Owner

- [ ] App icon (various sizes for favicon, og:image)
- [ ] App screenshots (for landing page, App Store badge)
- [ ] TestFlight invite link
- [ ] App Store link (when published)
- [ ] German translations of legal pages
- [ ] Any university/institution branding requirements

### To Create

- [ ] og:image for social sharing
- [ ] Favicon set (16, 32, 180, 192, 512px)
- [ ] Feature illustrations (optional, can use system icons)

---

## Success Criteria

1. **Loads fast** - <2s on 3G
2. **Accessible** - WCAG 2.1 AA compliance
3. **Bilingual** - Full German and English versions
4. **Trust-building** - Privacy messaging clear and prominent
5. **Conversion** - Clear path to TestFlight signup or App Store

---

## Contact

- **Project Lead:** Fabian Moron Zirfas
- **Email:** wolfsbit@inpyjamas.dev
- **Repository:** This repo (`/docs` for content, legal pages ready)

---

## Quick Reference

| Resource | Location |
|----------|----------|
| Privacy Policy content | `docs/legal/privacy-policy.md` |
| Terms of Service content | `docs/legal/terms-of-service.md` |
| App architecture docs | `docs/plans/2025-11-13-ml-integration-design.md` |
| Feature descriptions | `README.md` |
| Development journals | `docs/journals/` |
| Design tokens (iOS) | `wolfsbit/utilities/UtilitiesDesignTokens.swift` |

---

*This briefing provides context for building the Wolfsbit website. Content exists in markdown format ready to be transformed into web pages. Focus on trust, accessibility, and clear communication of the research nature of this project.*
