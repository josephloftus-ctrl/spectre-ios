# ZoneCount: Zone-Based Inventory Counting for Food Service

## Problem Statement

Current food service inventory workflow is broken:

```
Print sheet → walk around → write numbers → walk back → type into computer → hope no transcription errors → run reconciliation
```

This process takes 3+ hours per site, introduces transcription errors, and disconnects the physical act of counting from the digital record. Existing solutions (MarketMan, WISK, Restaurant365) are enterprise platforms ($200-500/mo) that require item-level barcode scanning and wholesale system replacement.

## Core Insight

Inventory is inherently spatial. Experienced operators don't think in alphabetical lists—they think in locations: "back wall of the walk-in, second shelf, behind the tomatoes." The app should match this mental model.

## Solution: Zone-First Counting

Instead of scanning individual product barcodes (fragile, tedious, impossible for prepped items), use **location markers** to anchor the workflow:

1. **Scan zone marker** (one scan per storage area)
2. **See items that live there** with par levels and last counts
3. **Tap to count** quantities
4. **Move to next zone**

Data is digital from the moment of capture. No paper. No re-keying. Flows directly into downstream systems.

## Why Location Markers Beat Product Barcodes

| Product Barcodes | Zone Markers |
|------------------|--------------|
| Every item needs clean, scannable code | One marker per storage area |
| Frozen/wet/torn labels won't scan | Laminated, controlled placement |
| Bulk/prepped items have no barcode | You control print quality |
| Must scan each unit individually | One scan shows all zone items |

Zone markers can be simple laminated cards with bold text (e.g., "DRY-01") or QR codes. The marker says "I'm HERE"—the app supplies what should be there.

## Key Differentiators

### 1. Zone-First Workflow
Scan WHERE, not WHAT. Matches how kitchens are actually organized and how experienced operators already think.

### 2. Built-In Canon
The app knows food service. It can recognize "this is a walk-in cooler" and suggest common items pre-sorted by food safety shelf logic (proteins bottom, RTE top). Setup time drops from hours to minutes.

### 3. Lightweight Integration
Doesn't replace existing systems—feeds them. Exports to CSV, integrates with inventory reconciliation tools (like Nebula Engine), pushes to MyOrders/MyFinance.

### 4. Multi-Site Support Role
Built for area managers and support staff who walk into different kitchens. Site profiles persist; you're not rebuilding from scratch each visit.

## Target Users

- Area Support Chefs / District Managers
- Kitchen Managers doing weekly counts
- Multi-unit operators needing consistency across locations

## Technical Approach

- **iOS native app** (Swift/SwiftUI)
- **Camera-based marker recognition** (QR code or OCR on zone labels)
- **Optional image recognition** for zone type suggestion during setup
- **Local-first data** with cloud sync for multi-device/multi-site
- **CSV export** as minimum viable integration

## MVP Scope

### In Scope
- Site and zone management
- Zone marker scanning (QR or text recognition)
- Item lists per zone with par levels
- Count entry with session tracking
- Canon system for quick zone setup
- CSV export

### Out of Scope (Future)
- Recipe costing
- POS integration
- Ordering/purchasing
- Waste tracking
- Multi-user permissions
- Variance analysis (handled by Nebula Engine)

## Success Metrics

- Inventory count time reduced from 3+ hours to under 30 minutes
- Zero transcription errors (data born digital)
- New site setup under 1 hour using canon templates
- Seamless handoff to reconciliation/financial systems

## Project Origins

This concept emerged from direct operational experience managing inventory across multiple B&I (Business & Industry) food service locations. The realization: everyone knows paper-and-pencil counting is inefficient, but existing digital solutions don't match how kitchens actually work.

The zone-based approach leverages spatial memory and existing kitchen organization rather than fighting against it.
