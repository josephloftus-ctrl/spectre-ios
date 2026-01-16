# ZoneCount: Data Model

## Overview

The data model supports three core operations:
1. **Setup**: Define sites, zones, and what items live where
2. **Counting**: Capture quantities during count sessions
3. **Canon**: Pre-built templates for fast zone population

## Entity Relationship Diagram

```
┌─────────────────┐
│      SITE       │
├─────────────────┤
│ id              │
│ name            │
│ address         │
│ created_at      │
└────────┬────────┘
         │ 1:many
         ▼
┌─────────────────┐       ┌─────────────────┐
│      ZONE       │       │  COUNT_SESSION  │
├─────────────────┤       ├─────────────────┤
│ id              │       │ id              │
│ site_id (FK)    │       │ site_id (FK)    │
│ name            │       │ started_at      │
│ code            │◄──────│ completed_at    │
│ zone_type       │       │ counted_by      │
│ sort_order      │       │ status          │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │ many:many               │ 1:many
         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐
│    ZONE_ITEM    │       │  COUNT_ENTRY    │
├─────────────────┤       ├─────────────────┤
│ zone_id (FK)    │       │ id              │
│ item_id (FK)    │       │ session_id (FK) │
│ par_level       │       │ zone_id (FK)    │
│ sort_order      │       │ item_id (FK)    │
└────────┬────────┘       │ quantity        │
         │                │ timestamp       │
         ▼                │ note            │
┌─────────────────┐       └─────────────────┘
│      ITEM       │
├─────────────────┤
│ id              │
│ name            │
│ unit            │
│ category        │
│ canon_item_id   │
└─────────────────┘
```

## Core Tables

### SITE
Represents a physical location (kitchen, facility, account).

```sql
CREATE TABLE site (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    address         TEXT,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Examples:**
- PSEG Hope Creek
- PSEG Salem
- Lockheed Martin - Moorestown
- Phoenix Contact
- Grier School

### ZONE
A storage area within a site. The `code` field is what appears on the physical marker.

```sql
CREATE TABLE zone (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id         UUID REFERENCES site(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    code            VARCHAR(20) NOT NULL,  -- "WIC-01", "DRY-02"
    zone_type       VARCHAR(50),           -- walk_in_cooler, dry_storage, etc.
    sort_order      INTEGER DEFAULT 0,     -- Walking path sequence
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(site_id, code)
);
```

**Zone Types:**
- `walk_in_cooler`
- `walk_in_freezer`
- `dry_storage`
- `reach_in_cooler`
- `reach_in_freezer`
- `line_station`
- `other`

### ITEM
Individual inventory items. Can be site-specific or linked to canon items.

```sql
CREATE TABLE item (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id         UUID REFERENCES site(id) ON DELETE CASCADE,
    name            VARCHAR(255) NOT NULL,
    unit            VARCHAR(50) NOT NULL,  -- case, each, lb, gal, bag
    category        VARCHAR(100),          -- Protein, Dairy, Produce, etc.
    canon_item_id   UUID REFERENCES canon_item(id),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### ZONE_ITEM
Many-to-many relationship defining what items live in which zones.

```sql
CREATE TABLE zone_item (
    zone_id         UUID REFERENCES zone(id) ON DELETE CASCADE,
    item_id         UUID REFERENCES item(id) ON DELETE CASCADE,
    par_level       DECIMAL(10,2),         -- Target quantity
    sort_order      INTEGER DEFAULT 0,     -- Position within zone (shelf order)
    PRIMARY KEY (zone_id, item_id)
);
```

### COUNT_SESSION
A single inventory count event at a site.

```sql
CREATE TABLE count_session (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id         UUID REFERENCES site(id) ON DELETE CASCADE,
    started_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at    TIMESTAMP,
    counted_by      VARCHAR(255),          -- User identifier
    status          VARCHAR(20) DEFAULT 'in_progress',  -- in_progress, completed, abandoned
    notes           TEXT
);
```

### COUNT_ENTRY
Individual count records within a session.

```sql
CREATE TABLE count_entry (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID REFERENCES count_session(id) ON DELETE CASCADE,
    zone_id         UUID REFERENCES zone(id),
    item_id         UUID REFERENCES item(id),
    quantity        DECIMAL(10,2) NOT NULL,
    timestamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    note            VARCHAR(255)           -- "damaged", "expired", "new case opened"
);
```

## Canon Tables (Templates)

### ZONE_TEMPLATE
Pre-defined zone type configurations.

```sql
CREATE TABLE zone_template (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type            VARCHAR(50) UNIQUE NOT NULL,
    name_suggestion VARCHAR(255),
    description     TEXT,
    visual_cues     TEXT                   -- For image recognition hints
);
```

### CANON_ITEM
Master list of common food service items.

```sql
CREATE TABLE canon_item (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    default_unit    VARCHAR(50),
    category        VARCHAR(100),
    typical_zones   VARCHAR(255)[],        -- Array of zone types
    b_and_i_common  BOOLEAN DEFAULT true,  -- Common in B&I accounts
    default_par     DECIMAL(10,2)
);
```

### CANON_ZONE_ITEM
Default items for each zone template.

```sql
CREATE TABLE canon_zone_item (
    zone_template_id UUID REFERENCES zone_template(id),
    canon_item_id    UUID REFERENCES canon_item(id),
    sort_order       INTEGER DEFAULT 0,    -- Follows food safety shelf logic
    PRIMARY KEY (zone_template_id, canon_item_id)
);
```

## Export Format

CSV export for integration with downstream systems:

```csv
site_name,zone_code,zone_name,item_name,unit,quantity,par_level,variance,timestamp,counted_by,note
"PSEG Hope Creek","WIC-01","Walk-in Cooler - Proteins","Chicken Breast, 10lb",case,3,4,-1,2025-01-14T06:30:00Z,"Joseph",""
"PSEG Hope Creek","WIC-01","Walk-in Cooler - Proteins","Ground Beef, 5lb",case,6,6,0,2025-01-14T06:31:00Z,"Joseph",""
```

## Indexes

```sql
CREATE INDEX idx_zone_site ON zone(site_id);
CREATE INDEX idx_zone_code ON zone(site_id, code);
CREATE INDEX idx_item_site ON item(site_id);
CREATE INDEX idx_count_entry_session ON count_entry(session_id);
CREATE INDEX idx_count_session_site ON count_session(site_id);
CREATE INDEX idx_count_session_date ON count_session(started_at);
```

## Notes

- UUIDs used throughout for offline-first sync compatibility
- Soft deletes could be added via `deleted_at` columns if needed
- `sort_order` fields enable custom sequencing for walking paths and shelf positions
- Canon linkage (`canon_item_id`) allows tracking which items came from templates vs. custom additions
