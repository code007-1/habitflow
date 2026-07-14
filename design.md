## Overview
- A responsive mobile-first design package for a habit-tracking app named **HabitFlow**. The plan defines three core screens (Create Habit, Habit Recording, and Dashboard) so designers can produce static, polished layouts that cover primary flows for creating, recording, and reviewing habits.
- Target device is **Mobile (390px)** with responsive layout considerations for larger viewports (single-column mobile-first layouts that adapt to wider screens). The visual direction is clean, neutral, and content-forward.

## Plan Details
- App type: **MobileApp (primary 390px)** with responsive variants for wider widths (note sizes: 390px base; adapt to 768px and 1440px layouts). Use standard system fonts and a neutral color palette with accent color per habit.

1) Create / Edit Habit Screen — purpose: define a new habit or update an existing one
   - Goal: let the user enter all required tracking settings and save a habit quickly.
   - Top-to-bottom layout:
     1. **Top Navigation Bar**: back button (left), screen title (“New Habit” / “Edit Habit”) center, help icon (optional) right.
     2. **Habit Identity**: input row with **Habit Name** (text), optional **Icon** or emoji picker, and optional color chip for habit accent.
     3. **Type selector**: segmented control or select list for **Tracking Unit** with options: **Binary (Done/Not)**, **Count**, **Duration**, **Numeric**. Each option shows a short subtitle (e.g., Count = times per interval).
     4. **Session Duration / Unit specifics** (conditional based on Type): numeric input + unit selector (minutes/hours) for Duration type; min/max or step for Count/Numeric types.
     5. **Interval / Schedule** section:
        - Quick presets: Daily / Weekly / Custom
        - For Daily: choose times of day (optional)
        - For Weekly: weekday toggles (Mon–Sun)
        - For Custom: every N days/weeks option and start date
     6. **Total Duration**:
        - Selector for total tracking length: **End after X** with units (days/weeks/months/years) OR **No end date** (ongoing).
     7. **Reminders & Notifications**:
        - Toggle to enable reminders; if on, allow time(s) and repeat rules.
     8. **Targets & Goals** (optional): e.g., target count per interval, target duration per session, target occurrences (e.g., 20 times in 30 days).
     9. **Remarks / Notes**: multiline text field for contextual notes or instructions.
     10. **Advanced / Optional fields** (collapsible): tags, privacy (private/public), difficulty/priority.
     11. **Preview Card**: small live preview showing habit card with name, icon, accent, and quick summary (interval + total duration + target).
     12. **Primary action area (Bottom)**: Save button (primary) and Cancel (secondary). On save show brief success state or return to Dashboard.
   - Data fields to include (explicit): Name, Icon, Accent Color, Type, Session Duration (value + unit), Interval (preset/custom + weekday selection or every-N), Total Duration (value + unit or ongoing), Start Date, Reminders (times), Target values, Remarks, Tags.
   - Validation & defaults: Name required; default Type = Binary; default Interval = Daily; default Total = ongoing.

2) Habit Recording Screen — purpose: record a single habit instance and review full history
   - Goal: let the user quickly log an entry (fast single-tap + optional details) and see the habit’s past records in detail.
   - Top-to-bottom layout:
     1. **Top Navigation Bar**: back button, habit title with small subtitle (type + accent), overflow menu (edit, delete, settings).
     2. **Habit Summary Card** (prominent): habit icon, name, current streak, best streak, quick progress ring showing completion % for the current total-duration window.
     3. **Quick Record Area** (primary interaction block):
        - For **Binary**: large single primary button labeled Done / Mark Complete and a small Undo control.
        - For **Count / Numeric**: numeric stepper (+ / -), quick-presets (e.g., +1, +5), and a direct input field.
        - For **Duration**: start/stop timer control and manual input field for minutes/hours.
        - Always show a short “Add note” inline link to attach a remark to the entry.
     4. **Recent Entries (compact list)**: horizontally scrollable chips or compact list of most recent entries (last 7–14 days) with date, value, and small note icon if present.
     5. **Full History (expanded)**:
        - Chronological list grouped by month/week with each entry showing: date/time, recorded value (or Done), note preview, and quick edit icon.
        - Each item can be tapped to open an **Entry Detail sheet** showing full note, exact timestamp, and actions: Edit, Delete, Duplicate.
     6. **Trend Snapshot** (small): mini line or bar chart for the last 30 days showing values/completions.
     7. **Bottom Actions**: Add Manual Entry (secondary) and Share/Export (optional) as icon buttons.
   - History detail expectations: show exact timestamps, ability to edit value and note, and show contextual badges (missed, partial, extra).
   - Empty-state copy: when no entries exist show prominent CTA to record the first entry and a short tip about the fastest way to log.

3) Dashboard Screen — purpose: overview of all tracked habits with visual analytics
   - Goal: provide a single glance summary of progress across all habits and allow entry to habit detail/recording.
   - Top-to-bottom layout:
     1. **Top Bar / Header**: app title/logo left, date range picker center (e.g., Today / 7d / 30d), add-habit (+) action right.
     2. **Summary Strip**: compact stats row showing **Total habits**, **Active streaks**, **Today’s completions**, and **Overall completion %** (each as tappable chips).
     3. **Habits List / Tile Grid**:
        - Vertical list of habit cards (or 2-column grid on wider screens). Each card shows: icon, name, small progress ring, current streak, and quick-record button.
        - Cards can be sorted or filtered by All / Active / Paused / Favorites via a segmented control.
     4. **Calendar View** (primary analytics block):
        - Month calendar heatmap when interval is daily or binary: each date colored by completion intensity; tap a date to show day detail.
        - For count/duration habits, calendar shows aggregated values per day.
     5. **Time-series Charts**:
        - Line chart showing daily totals for selected habit or aggregated selected set over the chosen date range.
        - Bar chart option to compare weeks or months.
     6. **Streaks & Goals**:
        - Card showing longest streaks, active streaks, and upcoming goal milestones.
     7. **Filters & Controls (persistent)**: habit selector dropdown, date range, chart type toggle, export button.
     8. **Empty / No-data states**: guidance cards explaining how to add first habit and how stats populate.

### Reusable Components
- **Habit Card**: icon, name, progress ring, streak, quick-record action, small overflow menu.
- **Form Field Row**: label + input / selector + helper text.
- **Segmented Control**: for type selection and date-range presets.
- **Primary CTA Bar**: bottom-anchored Save/Done area for forms.
- **Entry List Item**: date/time, value badge, note icon, quick edit affordance.
- **Small Charts**: calendar heatmap tile, mini line sparkline, bar microchart.

### Visual & Content Notes (defaults)
- Visual tone: neutral background, high-contrast text, one accent color per habit to help scanning.
- Use concise copy labels: Save, Cancel, Mark Done, Add Manual Entry, Remarks.
- Provide clear empty-state CTAs and microcopy explaining interval and total-duration fields.

### Variants to include as separate static screens
- Empty Dashboard (no habits yet)
- Create Habit (Edit mode) — same layout with prefilled values
- Habit Recording - Entry Detail sheet (expanded view of a single record)
- Confirmation / Success toast after saving a habit

End of plan.