# Dynamic Model Routing for Waste Classification AI

## Overview

To improve classification accuracy and user satisfaction, the app now tracks which AI model produced a user-confirmed correct result for each classification. This is stored in the `confirmedByModel` field of the `WasteClassification` model.

## How It Works

- When a user marks a reanalyzed classification as correct, the app records the model used for that reanalysis in `confirmedByModel`.
- This information is saved to both local and cloud storage.
- Over time, the app will aggregate this data to determine which models are most accurate for each user, waste type, or context.

## Planned Dynamic Routing

- In the future, the app will use the aggregated `confirmedByModel` data to dynamically select the best model for each new classification request.
- This could be based on:
  - User-specific model performance
  - Waste category or item type
  - Contextual factors (e.g., location, time, image quality)
- The goal is to maximize first-try accuracy and minimize user corrections.

## Current Status

- The `confirmedByModel` field is now tracked and saved when a user confirms a correct reanalysis.
- Data aggregation and dynamic routing logic are **not yet implemented**.

## Next Steps

1. Aggregate `confirmedByModel` data in analytics/admin dashboards.
2. Design and implement a routing algorithm that selects the best model per user/context.
3. Monitor impact and iterate.

---

*This document will be updated as dynamic model routing is developed and deployed.* 