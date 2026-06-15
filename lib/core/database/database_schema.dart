const String createTagsTable = '''
CREATE TABLE IF NOT EXISTS tags (
  tag_id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  color INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
''';

const String createIntentionsTable = '''
CREATE TABLE IF NOT EXISTS intentions (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  highlight TEXT,
  intention_text TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

const String createCaptureItemsTable = '''
CREATE TABLE IF NOT EXISTS capture_items (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT '随想',
  source_type TEXT NOT NULL DEFAULT 'manual',
  external_refs TEXT,
  status TEXT NOT NULL DEFAULT 'unclassified'
    CHECK(status IN ('unclassified', 'valuable', 'pending', 'discarded')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

const String createCaptureItemsFtsTable = '''
CREATE VIRTUAL TABLE IF NOT EXISTS capture_items_fts USING fts5(
  content,
  content=capture_items,
  content_rowid=rowid
);
''';

const String createFocusSessionsTable = '''
CREATE TABLE IF NOT EXISTS focus_sessions (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  start_time TEXT,
  end_time TEXT,
  duration_minutes INTEGER,
  type TEXT NOT NULL DEFAULT 'pomodoro',
  brain_dump_items TEXT,
  completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);
''';

const String createScheduleItemsTable = '''
CREATE TABLE IF NOT EXISTS schedule_items (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  title TEXT NOT NULL,
  time_slot TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

const String createDailyLogsTable = '''
CREATE TABLE IF NOT EXISTS daily_logs (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  actual_activities TEXT,
  reflection_notes TEXT,
  created_at TEXT NOT NULL
);
''';

const String createProjectProgressTable = '''
CREATE TABLE IF NOT EXISTS project_progress (
  project_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  total_units INTEGER NOT NULL DEFAULT 1,
  completed_units INTEGER NOT NULL DEFAULT 0,
  unit_label TEXT NOT NULL DEFAULT '章',
  status TEXT NOT NULL DEFAULT 'active',
  start_date TEXT,
  target_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

// Phase 5: performance indexes
const String createCaptureItemsIndexes = '''
CREATE INDEX IF NOT EXISTS idx_capture_created_at ON capture_items(created_at);
CREATE INDEX IF NOT EXISTS idx_capture_category ON capture_items(category);
''';

const String createScheduleItemsIndexes = '''
CREATE INDEX IF NOT EXISTS idx_schedule_date ON schedule_items(date);
''';

const String createFocusSessionsIndexes = '''
CREATE INDEX IF NOT EXISTS idx_focus_created_at ON focus_sessions(created_at);
''';

const String createIntentionsIndexes = '''
CREATE INDEX IF NOT EXISTS idx_intentions_created_at ON intentions(created_at);
''';

const List<String> allCreateTables = [
  createTagsTable,
  createIntentionsTable,
  createCaptureItemsTable,
  createCaptureItemsFtsTable,
  createFocusSessionsTable,
  createScheduleItemsTable,
  createDailyLogsTable,
  createProjectProgressTable,
];

/// SQL statements for v2→v3 migration
const List<String> migrationV2toV3 = [
  createTagsTable,
  createCaptureItemsIndexes,
  createScheduleItemsIndexes,
  createFocusSessionsIndexes,
  createIntentionsIndexes,
];

/// Default tags inserted on first upgrade or fresh install.
const List<Map<String, dynamic>> defaultTags = [
  {'tag_id': 'tag_default_random', 'name': '随想', 'color': 0xFF4A90D9},
  {'tag_id': 'tag_default_todo', 'name': '待办', 'color': 0xFFE67E22},
  {'tag_id': 'tag_default_inspiration', 'name': '灵感', 'color': 0xFF9B59B6},
  {'tag_id': 'tag_default_note', 'name': '笔记', 'color': 0xFF27AE60},
];
