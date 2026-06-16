# Add New Visit — Screen Reference for Web Replication

> **Source files (Flutter)**
> - View: `lib/Views/Screens/RouteManagement/add_task_screen.dart`
> - ViewModel: `lib/ViewModels/routeOptimization_viewModel.dart`
> - API Service: `lib/API/route_optimization_api_service.dart`
> - Models: `lib/Models/route_optimization_models.dart`

---

## Overview

The **Add New Visit** screen lets an admin/manager create a new client visit task and optionally assign it to a Field Executive (FE). The screen is split into three logical sections:

1. **Client Information** — who is being visited
2. **Visit Details** — where, why, visit type, priority
3. **Timing & Assignment** — when and who (FE)

On submission the form calls a single `POST` API to create the visit.

---

## Screen Layout

```
┌────────────────────────────────────┐
│  ← Add New Visit                   │  (App Bar)
├────────────────────────────────────┤
│  [Client Information]              │
│    • Client Name / Search          │
│    • Mobile Number                 │
├────────────────────────────────────┤
│  [Visit Details]                   │
│    • Visiting Address / Map Search │
│    • Google Map preview (if coords)│
│    • Additional Address Details    │
│    • Purpose of Visit              │
│    • Visit Type  (chip group)      │
│    • Priority    (chip group)      │
├────────────────────────────────────┤
│  [Timing & Assignment]             │
│    • Can Visit Anytime (toggle)    │
│    • Date picker                   │
│    • Slot Start / Slot End pickers │
│    • Field Executive selector      │
├────────────────────────────────────┤
│       [ Create Visit Task ]        │
└────────────────────────────────────┘
```

---

## Section 1 — Client Information

### Field: Client Name / Search

| Property | Value |
|---|---|
| Type | Text input with live search + dropdown suggestions |
| Required | No (can be left empty or use temporary client) |
| Debounce | 300 ms after last keystroke |
| Min chars to search | 3 |
| Placeholder | "Client Name / Search" |
| Special mode | Switches to "Temporary Client Name" label when a temporary client is selected |

**Behaviour:**
- As the user types (≥ 3 chars), client search API is called with a 300 ms debounce.
- A loading spinner appears in the trailing icon position while searching.
- A dropdown list of matching clients appears below the field.
- If no clients are found, a special row appears: **"Add as Temporary Client"** with the typed name as subtitle. Tapping it locks the field in **Temporary Client Mode**.
- While in Temporary Client mode: field becomes read-only, label changes, a "userCirclePlus" icon is shown.
- A clear (×) button appears when the field has text; tapping it resets client selection.

---

#### API: Search Clients

| | |
|---|---|
| **Method** | `GET` |
| **Endpoint** | `/api/route-plan/clients/list` |
| **When called** | On every keystroke (debounced 300 ms), minimum 3 characters |

**Query Parameters:**

| Param | Type | Value |
|---|---|---|
| `search` | string | The text typed by the user |
| `temporary` | boolean | Always `false` during normal search |
| `searchall` | boolean | `false` by default (was a toggle, now hidden) |

**Response:**
```json
{
  "clientList": [
    {
      "clientId": "abc123",
      "name": "John Doe",
      "mobile": "9876543210",
      "address": "123 Main St, City",
      "isTemporary": false
    }
  ]
}
```

**How response is used on UI:**

| Response field | Used as |
|---|---|
| `clientId` | Stored as `selectedClientId`; sent in submit payload as `clientId` |
| `name` | Shown as the primary line in each dropdown suggestion row |
| `address` | Shown as the subtitle in each suggestion row; auto-filled into the Visiting Address field when client is selected (unless user declines the address-replace dialog) |
| `mobile` | Auto-filled into Mobile Number field when client is selected |
| `isTemporary` | Metadata, not directly rendered but used for client type logic |

---

#### Selecting a Client from Suggestions

When a user taps a suggestion:
1. If the **Visiting Address field already has content**, a **confirmation dialog** appears:
   - Title: "Replace Address?"
   - Shows current address vs the client's address
   - Buttons: **No** (keep current) / **Replace** (use client's address)
2. If the field is empty, the client's address is filled automatically without dialog.

After selection:
- `selectedClientId` is set to `client.clientId`
- `_nameController` gets `client.name`
- `_mobileController` gets `client.mobile`
- `_visitAddressController` gets `client.address` (if user chose to replace or field was empty)
- If address was filled, coordinates are fetched immediately (see **Get Coordinates** API below)
- Suggestion dropdown is dismissed

---

#### Temporary Client Mode

When user taps "Add as Temporary Client":
- `isTemporaryClientMode = true`
- `selectedClientId = null`
- `selectedTemporaryName` = the typed name (used in submit payload)
- The name field becomes read-only

In submit payload, this translates to:
```json
{
  "clientId": null,
  "clientType": "temporary",
  "clientName": "<typed name>",
  "clientMobile": "<mobile field value>"
}
```

---

### Field: Mobile Number

| Property | Value |
|---|---|
| Type | Text input, phone keyboard |
| Required | No |
| Auto-fill | Populated from client search selection |

Not tied to any separate API. Sent as-is in the submit payload (`clientMobile` for temporary clients; not sent separately for mint clients).

---

## Section 2 — Visit Details

### Field: Visiting Address / Map Search

| Property | Value |
|---|---|
| Type | Multi-line text input (2 lines) with live search + dropdown suggestions |
| Required | **Yes** — form validation fails if empty or no coordinates selected |
| Debounce | 500 ms after last keystroke |
| Min chars to search | 3 |
| Validation message | "Please select a valid address from the map search suggestions" (if no coordinates) |

**Behaviour:**
- User types an address; after 500 ms, Address Search API is called.
- A dropdown of address suggestions appears.
- User **must** tap a suggestion (not just type) to lock in coordinates. If no suggestion is tapped, validation fails.
- When a suggestion is tapped, `selectedCoordinates` is set and a **Google Map preview** renders below the field, centered on the selected location with a pin marker.
- A clear (×) button resets the field and clears coordinates.
- Coordinates are stored as `[longitude, latitude]` (GeoJSON order).

---

#### API: Search Addresses

| | |
|---|---|
| **Method** | `POST` |
| **Endpoint** | `/api/route-plan/client/searchAddress` |
| **When called** | On address field change, debounced 500 ms, min 3 chars |

**Request Body:**
```json
{
  "searchedAddress": "MG Road, Bengaluru"
}
```

**Response:**
```json
{
  "suggestions": [
    {
      "name": "MG Road",
      "address": "MG Road, Bengaluru, Karnataka 560001, India",
      "coordinates": [77.6037, 12.9756]
    }
  ]
}
```

> ⚠️ Coordinates are in **GeoJSON order: `[longitude, latitude]`**  
> When rendering on the map: `LatLng(coordinates[1], coordinates[0])`

**How response is used on UI:**

| Field | Used as |
|---|---|
| `address` | Shown in each suggestion row; filled into address input on tap |
| `coordinates` | Stored as `selectedCoordinates`; shown on the Google Map; sent in submit payload as `locationCoordinates` |
| `name` | Not currently shown separately (only `address` is displayed) |

After address selection:
- If `coordinates` is present → `fetchAvailableFEs()` is called immediately
- If `coordinates` is null → `getCoordinates` API is called first to resolve them, then FEs are fetched

---

#### API: Get Coordinates (fallback)

| | |
|---|---|
| **Method** | `GET` |
| **Endpoint** | `/api/route-plan/client/getCoordinatesFromAddress` |
| **When called** | When an address suggestion has no coordinates, or when a client's address is auto-filled from client selection |

**Query Parameters:**

| Param | Type | Value |
|---|---|---|
| `address` | string | The full address string |

**Response:**
```json
{
  "coordinates": [77.6037, 12.9756]
}
```

> Same GeoJSON `[lng, lat]` format.

After coordinates are resolved, `fetchAvailableFEs()` is called.

---

### Google Map Preview

- Renders **only when** `selectedCoordinates != null`
- Fixed height container (approx. 180px)
- Centered on `LatLng(coordinates[1], coordinates[0])`
- Zoom level: 15
- Shows a single pin marker at the selected location
- Not interactive beyond standard zoom; no address editing via map

---

### Field: Additional Address Details (Optional)

| Property | Value |
|---|---|
| Type | Free-text single-line input |
| Required | No |
| Sent in payload | Only if non-empty, as `additionalAddressDetails` |

Example: "3rd floor, flat 302"

---

### Field: Purpose of Visit

| Property | Value |
|---|---|
| Type | Free-text single-line input |
| Required | No (field exists but no validator) |
| Sent in payload | As `purposeOfVisit` |

---

### Field: Visit Type (Chip Group)

| Property | Value |
|---|---|
| Type | Single-select chip/pill buttons |
| Options | `Collection`, `Handover`, `Exchange` |
| Default | `Collection` |
| Sent in payload | As `visitType` (string) |

**UI behaviour:** Selected chip gets a tinted background + colored border matching the primary color. Unselected chips have a neutral muted background.

---

### Field: Priority (Chip Group)

| Property | Value |
|---|---|
| Type | Single-select chip/pill buttons |
| Options | `High` (value: `1`), `Normal` (value: `2`) |
| Default | `Normal` (value: `2`) |
| Sent in payload | As `priority` (integer: 1 or 2) |

**UI behaviour:**
- High → red color
- Normal → orange color
- Selected chip shows tinted background + border in the respective color

---

## Section 3 — Timing & Assignment

### Field: Can Visit Anytime (Toggle)

| Property | Value |
|---|---|
| Type | Toggle switch |
| Default | Off (`false`) |
| Sent in payload | As `canGoAnytime` (boolean) |

**Effect when ON:**
- Slot Start and Slot End pickers become disabled (show "--:--")
- FE availability check uses `23:58–23:59` of the selected date (end-of-day sentinel)
- FEs that are "Unavailable" during the slot become selectable (not greyed out)
- `availabilityStart`, `availabilityEnd`, `slotStart`, `slotEnd` are sent as `null` in the payload

**Effect when OFF:**
- Normal time pickers are active
- FEs are filtered by slot feasibility

---

### Field: Date

| Property | Value |
|---|---|
| Type | Date picker (tap to open native date picker) |
| Default | Today |
| Min date | Today |
| Max date | Today + 365 days |
| Display format | `dd MMM, yyyy` (e.g. "16 Jun, 2026") |
| Sent in payload | As `date` (ISO 8601 string with timezone offset, e.g. `"2026-06-16T00:00:00.000+05:30"`) |

Changing the date triggers `fetchAvailableFEs()` to reload FE availability.

---

### Field: Slot Start / Slot End

| Property | Value |
|---|---|
| Type | Time picker (tap to open native time picker) |
| Default Start | Current time + 5 minutes |
| Default End | Current time + 1 hour |
| Disabled when | "Can Visit Anytime" is ON (shows "--:--") |
| Sent in payload | As `availabilityStart`, `availabilityEnd`, `slotStart`, `slotEnd` (all four set to same value — the combined `date + time` as ISO 8601 with offset) |

> 💡 Both `availabilityStart`/`End` and `slotStart`/`End` receive the **same values**. They are redundant fields kept for API compatibility.

**Validation:**
- Start time cannot be in the past (when `canGoAnytime` is false)
- End time must be after start time

Changing either time triggers `fetchAvailableFEs()`.

---

### API: Fetch Available Field Executives

| | |
|---|---|
| **Method** | `GET` |
| **Endpoint** | `/api/route-plan/fe/list` |
| **When called** | After coordinates are set/changed, or when date/time changes |

**Query Parameters:**

| Param | Type | Condition |
|---|---|---|
| `lat` | number | Always when coordinates known — `coordinates[1]` (latitude) |
| `lng` | number | Always when coordinates known — `coordinates[0]` (longitude) |
| `slotStart` | string (ISO 8601 + offset) | When `canGoAnytime` is false |
| `slotEnd` | string (ISO 8601 + offset) | When `canGoAnytime` is false |
| `canGoAnytime` | string (`"true"` / `"false"`) | Always sent |

When `canGoAnytime` is true, `slotStart` is set to `23:58` and `slotEnd` to `23:59` of the selected date.

**Response:**
```json
[
  {
    "_id": "fe_id_001",
    "name": "Ravi Kumar",
    "employeeId": "EMP001",
    "contactNumber": "9876543210",
    "isAvailable": true,
    "isNearer": true,
    "distanceMeters": 2300,
    "nextAvailableAt": null,
    "isFeasible": true,
    "eta": "14 min"
  }
]
```

**How response is used on UI (Field Executive selector bottom sheet):**

Each FE card in the bottom sheet shows:

| Response field | UI Element |
|---|---|
| `name` | Primary bold text on FE card |
| `employeeId` | Shown in parentheses next to name in selector trigger button |
| `distanceMeters` | Tag pill: `"X.X km"` (blue) |
| `eta` | Tag pill: `"ETA: X min"` (teal) |
| `isNearer == true` | Tag pill: `"Suggested"` (blue, thumbs-up icon) |
| `isAvailable == false` | Tag pill: `"Next: <date>"` (orange); FE is greyed out and unselectable (unless canGoAnytime is ON) |
| `nextAvailableAt` | Formatted as `"dd MMM, hh:mm a"` and shown in the "Next:" tag |
| `isFeasible == false` | Red warning box: "Not Feasible: ETA to location is X, but slot ends before that." FE is always unselectable |

**Selectability rules:**

| Condition | Selectable? |
|---|---|
| `isFeasible == true` AND `isAvailable == true` | ✅ Yes |
| `isFeasible == true` AND `isAvailable == false` AND `canGoAnytime == true` | ✅ Yes |
| `isFeasible == true` AND `isAvailable == false` AND `canGoAnytime == false` | ❌ No (greyed out, orange warning) |
| `isFeasible == false` | ❌ No (greyed out, red warning, always) |

**When no coordinates are set:** The FE dropdown trigger shows "Select location to see field executives" (placeholder text).  
**While loading:** A `CircularProgressIndicator` is shown in place of the FE selector.

---

### Field: Field Executive Selector

| Property | Value |
|---|---|
| Type | Tap-to-open bottom sheet (75% screen height) |
| Required | No (can submit without assigning an FE) |
| Sent in payload | As `feId` (string ID or null) |

**Trigger button shows:**
- Icon: person-gear icon
- Label: "Field Executive" (small muted)
- Value: `"<name> (<employeeId>)"` if selected, else `"Select Field Executive"` (muted)
- Trailing: chevron-down icon

---

## Submit — Create Visit Task

### Button: "Create Visit Task"

- Full-width primary button at the bottom of the screen
- Shows a loading spinner while submitting
- Disabled during submission

---

### API: Create Visit

| | |
|---|---|
| **Method** | `POST` |
| **Endpoint** | `/api/route-plan/clients/add-visit` |
| **When called** | On form submission, after validation passes |

**Request Body:**

```json
{
  "clientId": "abc123",
  "clientType": "mint",

  // Only for temporary clients:
  "clientName": "John Doe",
  "clientMobile": "9876543210",

  "visitingAddress": "123 Main St, City",
  "additionalAddressDetails": "3rd floor",
  "locationCoordinates": [77.6037, 12.9756],

  "purposeOfVisit": "Loan collection",
  "visitType": "Collection",
  "priority": 2,
  "feId": "fe_id_001",

  "canGoAnytime": false,

  // When canGoAnytime is false:
  "availabilityStart": "2026-06-16T10:00:00.000+05:30",
  "availabilityEnd": "2026-06-16T11:00:00.000+05:30",
  "slotStart": "2026-06-16T10:00:00.000+05:30",
  "slotEnd": "2026-06-16T11:00:00.000+05:30",

  // When canGoAnytime is true:
  // "availabilityStart": null,
  // "availabilityEnd": null,
  // "slotStart": null,
  // "slotEnd": null,

  "date": "2026-06-16T00:00:00.000+05:30"
}
```

**Payload field reference:**

| Field | Source |
|---|---|
| `clientId` | `selectedClientId` (null for temporary) |
| `clientType` | `"temporary"` if temp mode, else `"mint"` |
| `clientName` | Only if temp: `selectedTemporaryName` |
| `clientMobile` | Only if temp: `_mobileController.text` |
| `visitingAddress` | `_visitAddressController.text` |
| `additionalAddressDetails` | `_additionalAddressController.text` (omitted if empty) |
| `locationCoordinates` | `selectedCoordinates` (array `[lng, lat]`) |
| `purposeOfVisit` | `_purposeController.text` |
| `visitType` | `selectedVisitType` (default: `"Collection"`) |
| `priority` | `selectedPriority` (1 = High, 2 = Normal) |
| `feId` | `_selectedFeId` (local state, can be null) |
| `canGoAnytime` | `canGoAnytime` (boolean) |
| `availabilityStart` | Formatted `selectedDate + startTime` as ISO 8601 with offset, or `null` |
| `availabilityEnd` | Formatted `selectedDate + endTime` as ISO 8601 with offset, or `null` |
| `slotStart` | Same as `availabilityStart` |
| `slotEnd` | Same as `availabilityEnd` |
| `date` | `selectedDate` formatted as ISO 8601 with offset |

**On success:** Snackbar "Task created successfully", screen pops (navigates back).  
**On error:** Snackbar with the error message from the API response.

---

## Date/Time Formatting

All datetime values sent to the API use a custom formatter that appends the local timezone offset:

```
2026-06-16T10:00:00.000+05:30
```

Format: `ISO 8601 local time + timezone offset sign + HH:MM`

This ensures MongoDB stores the correct UTC moment regardless of server timezone.

---

## Pre-fill (from Route Map / External Navigation)

The screen accepts optional constructor parameters to pre-fill fields when navigated to from another screen (e.g. tapping a location on the route map):

| Parameter | Pre-fills |
|---|---|
| `initialCoordinates` | `selectedCoordinates`; triggers `fetchAvailableFEs()` immediately |
| `initialAddress` | `_visitAddressController` |
| `initialClientName` | `_nameController`; triggers `searchClientsImmediately()` (up to 2 attempts, 800 ms apart) |

---

## Form Validation Rules

| Field | Rule |
|---|---|
| Visiting Address | Required, must not be empty |
| Visiting Address | Must have coordinates (from suggestion tap, not just typed text) |
| Slot Start | Cannot be in the past (when `canGoAnytime` is false) |
| Slot End | Must be after Slot Start (when `canGoAnytime` is false) |

All other fields have no hard validation.

---

## State Flags (for UI reactive rendering)

| Flag | Effect |
|---|---|
| `isSearchingClients` | Shows spinner in Client Name field suffix |
| `isSearchingAddresses` | Shows spinner in Visiting Address field suffix |
| `isLoadingFEs` | Shows `CircularProgressIndicator` where FE selector would be |
| `isSubmitting` | Disables submit button, shows spinner inside it |
| `isTemporaryClientMode` | Makes Client Name field read-only, changes label/icon |
| `canGoAnytime` | Disables time pickers, affects FE selectability |
| `selectedCoordinates != null` | Shows Google Map preview; shows FE selector |
| `clientSuggestions.isNotEmpty` | Shows client suggestions dropdown |
| `temporaryClientName != null` | Shows "Add as Temporary Client" row in dropdown |
| `addressSuggestions.isNotEmpty` | Shows address suggestions dropdown |

---

## API Summary Table

| # | API | Method | Endpoint | Trigger |
|---|---|---|---|---|
| 1 | Search Clients | GET | `/api/route-plan/clients/list` | Client name field change (debounce 300ms, min 3 chars) |
| 2 | Search Addresses | POST | `/api/route-plan/client/searchAddress` | Address field change (debounce 500ms, min 3 chars) |
| 3 | Get Coordinates | GET | `/api/route-plan/client/getCoordinatesFromAddress` | When address suggestion has no coords, or client address auto-filled |
| 4 | Fetch Available FEs | GET | `/api/route-plan/fe/list` | After coordinates set, or date/time changed |
| 5 | Create Visit | POST | `/api/route-plan/clients/add-visit` | Submit button tap |
