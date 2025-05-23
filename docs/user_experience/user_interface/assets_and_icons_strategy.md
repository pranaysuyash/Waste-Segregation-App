# Asset & Icon Strategy for Waste Segregation App

_Last updated: May 2025_

## Overview
This document outlines the strategy for sourcing, organizing, and integrating visual assets (icons, badges, illustrations) into the Waste Segregation App, with a focus on leveraging the Freepik API and ensuring design consistency and license compliance.

---

## 1. Asset Types & Use Cases

### A. Gamification Assets
- **Badges:** Unique icons for achievements (e.g., streaks, challenges, levels)
- **Points/Level Icons:** Visual indicators for user progress
- **Leaderboard Icons:** Trophies, medals, crowns, etc.

### B. App UI Assets
- **App Icon:** Modern, recognizable, and scalable
- **Category Icons:** Wet, dry, hazardous, medical, non-waste, etc.
- **Action Icons:** Camera, share, save, analytics, etc.
- **Onboarding/Empty State Illustrations:** Friendly, educational visuals

### C. Educational Content
- **Infographics:** For waste facts, recycling tips, etc.
- **Section Banners:** For different app sections (dashboard, achievements, etc.)

### D. Theming
- **Consistent style:** Flat, outline, or filled icons
- **SVG preferred** for scalability and theming

---

## 2. Style Recommendations for Icons & Illustrations

### A. Main App (All Ages/Education)
- **Recommended Styles:**
  - **Outline:** Clean, modern, and accessible for all ages. Works well for educational content and is easy to theme.
  - **Lineal Color:** Adds vibrancy and friendliness without being too childish. Great for making the app feel engaging and lively for both adults and younger users.
- **Why:**
  - Outline icons are universally readable and professional, but not intimidating.
  - Lineal Color icons are inviting and can make learning feel more fun, but still look "grown up" enough for adults.

### B. Kid-Friendly Section (Future/Optional)
- **Recommended Styles:**
  - **Hand drawn:** Playful, friendly, and approachable—perfect for kids' content, games, or special "junior" modes.
  - **Lineal Color:** Also works well for kids, especially if you use brighter, more saturated colors.
- **Why:**
  - Hand drawn icons create a sense of play and creativity, which is great for engaging children.
  - Consistent use of color and playful shapes helps kids recognize and remember actions and categories.

### C. Consistency & Theming
- Keep the style consistent within each section (main app vs. kid mode).
- Use the same icon style for similar actions across the app.
- Organize assets in folders (e.g., `assets/icons/outline/`, `assets/icons/handdrawn/`) to support easy theming or switching styles in the future.

#### Summary Table
| Section         | Recommended Style(s)   | Why?                                 |
|-----------------|-----------------------|--------------------------------------|
| Main App        | Outline, Lineal Color | Universal, modern, friendly, clear   |
| Kid Section     | Hand drawn, Lineal Color | Playful, engaging, age-appropriate   |

---

## 3. Sourcing Assets: Manual Curation Recommended

### A. Why Manual Curation?
- **Freepik API** (even with premium) does not always guarantee that search results are directly downloadable as SVGs, or that the asset is available in the desired format/license.
- **Best practice:** Use the Freepik (or Flaticon) website to visually search, filter, and preview assets before downloading or using the API.

### B. Manual Asset Selection Workflow
1. **Search on Freepik/Flaticon Website:**
   - Use relevant search terms (e.g., "trophy icon", "recycle badge", "camera flat icon").
   - Filter by **License** (Premium/Freemium as needed), **File Type** (SVG/Vector), and **Resource Type** (Icons/Vectors).
2. **Preview and Confirm:**
   - Ensure the asset matches your style and is available as SVG.
   - Note the asset ID (from the URL) or download directly if allowed.
3. **Download and Organize:**
   - Download SVGs manually and place them in the appropriate `assets/` subdirectory.
   - Keep a record of asset IDs/URLs for attribution and future reference.
4. **Attribution:**
   - Update `assets/ATTRIBUTION.md` with author and asset URL as required by your license.

### C. (Optional) Batch Download by ID via API
- If you have a list of asset IDs, you can use the Freepik API to download them in batch.
- This is more reliable than keyword search, as you have already confirmed the asset's suitability and format.
- Example endpoint: `/v1/resources/{id}/download/svg`

### D. Best Search Terms for Common Needs
| Use Case         | Freepik Search Term Example         |
|------------------|------------------------------------|
| Badge            | badge icon, achievement badge      |
| Trophy           | trophy icon, cup icon              |
| Medal            | medal icon, award medal            |
| Camera           | camera icon, photo icon            |
| Recycle          | recycle icon, eco icon             |
| Compost          | compost icon, compostable icon     |
| Leaderboard      | leaderboard icon, ranking icon     |
| Share            | share icon, send icon              |
| Save             | save icon, bookmark icon           |
| Analytics        | analytics icon, chart icon         |
| Medical          | medical icon, health icon          |
| Hazard           | hazard icon, warning icon          |
| Onboarding       | onboarding illustration, recycling illustration |
| Infographic      | recycling infographic, waste infographic |

---

## 4. Asset Organization
- `assets/icons/` — UI and category icons
- `assets/badges/` — Gamification badges and rewards
- `assets/images/` — Illustrations, banners, infographics
- `assets/docs/` — Legal and documentation assets
- (Optional) Use subfolders for different styles: `assets/icons/outline/`, `assets/icons/handdrawn/`, etc.

---

## 5. Design & Theming Guidelines
- **Style:** Choose a consistent style (e.g., flat, outline, or filled) for all icons and badges
- **Color Palette:** Use the app's primary/secondary colors for theming SVGs
- **Size:** Standardize icon sizes (e.g., 24x24, 48x48 for badges)
- **Accessibility:** Ensure sufficient contrast and alt text for all icons
- **SVG Usage:** Prefer SVG for scalability and theming; use PNG only if SVG is unavailable

---

## 6. License Compliance & Attribution
- **Premium License:** If you have a premium Freepik license, attribution may not be required, but always check the terms
- **Attribution File:** Keep `assets/ATTRIBUTION.md` up to date with all sourced assets
- **No Redistribution:** Do not redistribute Freepik assets outside the app

---

## 7. Adding New Assets: Step-by-Step
1. Search and download asset from Freepik/Flaticon (website recommended)
2. Optimize and rename asset file
3. Place in appropriate `assets/` subdirectory
4. Add to `pubspec.yaml` under `assets:`
5. Update `ATTRIBUTION.md` if required
6. Test rendering in the app

---

## 8. Future Automation
- Consider writing a script to automate asset download by ID if you have a curated list.
- Review and curate assets regularly for freshness and consistency.

---

## 9. References
- [Freepik API Documentation](https://docs.freepik.com/api-reference/resources/get-all-resources)
- [SVGOMG Optimizer](https://jakearchibald.github.io/svgomg/)
- [Flutter SVG Package](https://pub.dev/packages/flutter_svg)

---

## 10. Changelog
- **May 2025:**
    - Fixed a bug where gamification points/popups would incorrectly display when viewing an already analyzed image from history. The `ResultScreen` now checks if it's a new classification before processing gamification rewards.

---

_This document should be updated as new asset needs or workflows are identified._ 