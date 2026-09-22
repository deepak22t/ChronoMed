// Drift table definitions for ChronoMed local relational storage.
// Matches SQLite schema specified in LLD.md.

abstract class TableContract {
  // Shared metadata contract
}

class UserRoutinesTable {
  static const String tableName = 'user_routines';
  static const String colUserId = 'user_id';
  static const String colWakeMinutes = 'wake_minutes';
  static const String colSleepMinutes = 'sleep_minutes';
  static const String colUpdatedAt = 'updated_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS user_routines (
      user_id TEXT PRIMARY KEY,
      wake_minutes INTEGER NOT NULL,
      sleep_minutes INTEGER NOT NULL,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  ''';
}

class UserMealsTable {
  static const String tableName = 'user_meals';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colMealType = 'meal_type';
  static const String colStartMinutes = 'start_minutes';
  static const String colDurationMinutes = 'duration_minutes';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS user_meals (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      meal_type TEXT CHECK(meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
      start_minutes INTEGER NOT NULL,
      duration_minutes INTEGER DEFAULT 30,
      FOREIGN KEY(user_id) REFERENCES user_routines(user_id) ON DELETE CASCADE
    );
  ''';
}

class UserMedicationsTable {
  static const String tableName = 'user_medications';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colName = 'name';
  static const String colDosage = 'dosage';
  static const String colRxcui = 'rxcui';
  static const String colRequiresEmptyStomach = 'requires_empty_stomach';
  static const String colRequiresFood = 'requires_food';
  static const String colCircadianPreference = 'circadian_preference';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS user_medications (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      rxcui TEXT,
      requires_empty_stomach BOOLEAN DEFAULT 0,
      requires_food BOOLEAN DEFAULT 0,
      circadian_preference TEXT DEFAULT 'ANY',
      FOREIGN KEY(user_id) REFERENCES user_routines(user_id) ON DELETE CASCADE
    );
  ''';
}

class ScheduledDosesTable {
  static const String tableName = 'scheduled_doses';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colMedicationId = 'medication_id';
  static const String colMedicationName = 'medication_name';
  static const String colDosage = 'dosage';
  static const String colScheduledMinute = 'scheduled_minute';
  static const String colActualTakenMinute = 'actual_taken_minute';
  static const String colStatus = 'status';
  static const String colClinicalInstruction = 'clinical_instruction';
  static const String colSafeFoodWindowNote = 'safe_food_window_note';
  static const String colScheduleDate = 'schedule_date';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS scheduled_doses (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      medication_id TEXT NOT NULL,
      medication_name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      scheduled_minute INTEGER NOT NULL,
      actual_taken_minute INTEGER,
      status TEXT DEFAULT 'SCHEDULED',
      clinical_instruction TEXT,
      safe_food_window_note TEXT,
      schedule_date TEXT NOT NULL
    );
  ''';
}
