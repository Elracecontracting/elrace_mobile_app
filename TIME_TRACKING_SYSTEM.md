# Time Tracking System Documentation

## Overview

This document describes the time tracking rules and implementation in the El Race application.

## Time Tracking Rules

### 1. Global Working Hours

- **Total working hours are unified across all projects: 8 hours**
- The timer is not project-specific
- All employees have the same working hours regardless of the project they're working on

### 2. Check-in / Check-out Mechanism

- **Check-in and check-out are global and unified**
- Not tied to any specific project
- One check-in per day, one check-out per day
- The system tracks total working time, not per-project time

### 3. Detailed Time Management

- Project-specific time allocation is handled through **Job Missions Requests**
- Task-based or mission-based time tracking is separate from the main check-in/out system
- This allows flexibility for employees working on multiple projects during the day

## Implementation

### Core Components

#### TimerController (`timer_controller.dart`)

- Manages the global 8-hour countdown timer
- Persists timer state across app restarts
- Timer continues running even when app is closed or in background
- Recalculates remaining time based on check-in timestamp

```dart
// Timer starts with 8 hours for all projects
Duration _initialRemaining = const Duration(hours: 8);
```

#### Check-In System

**File**: `check_in_repo.dart`

The check-in API call includes:

- User ID
- Device ID
- Check-in date/time
- Location (latitude/longitude)

**No project information is sent** - check-in is global.

#### Check-Out System

**File**: `check_out_repo.dart`

The check-out API call includes:

- User ID
- Device ID
- Check-out date/time
- Location (latitude/longitude)
- Check-in Record ID (to match with corresponding check-in)

**No project information is sent** - check-out is global.

### Project Selection

While the app allows users to select a project during check-in:

- This is **for display and reference purposes only**
- It does not affect the timer duration
- It does not split working hours between projects
- Stored in `checkInProjectId` preference for UI display

### Job Missions

For detailed, project-specific time tracking:

- Use the Job Missions feature
- This allows employees to log time spent on specific tasks
- Separate from the main check-in/out system
- Provides granular time allocation across multiple projects

## Timer Persistence

The timer continues running even when:

- App is minimized
- App is closed completely
- Device is restarted

**How it works:**

1. On check-in, the current timestamp is saved
2. Timer runs in foreground using `Timer.periodic`
3. When app reopens, remaining time is recalculated from original check-in time
4. Formula: `remaining = 8 hours - (now - checkInTime)`

This ensures accurate time tracking regardless of app state.

## Data Stored

### SharedPreferences Keys:

- `isCheckedIn` - Boolean flag for check-in status
- `checkInTime` - Timestamp (milliseconds) when user checked in
- `checkInRecordId` - Server-provided ID for matching check-out
- `timeLeft` - Cached remaining time (for quick load)
- `checkInProjectId` - Selected project (display only, optional)

## Summary

✅ **One global timer for all projects (8 hours)**  
✅ **Check-in/Check-out is unified and not project-specific**  
✅ **Timer persists across app restarts**  
✅ **Detailed time management via Job Missions**  
✅ **Project selection is for reference only**

This design provides simplicity for daily attendance while allowing detailed project tracking through separate mechanisms.
