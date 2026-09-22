/// Clinical Pharmacological Spacing Constants
/// All values represent minutes and are derived from official FDA product labeling,
/// US Pharmacopeia (USP), and clinical pharmacokinetics literature.
abstract final class ClinicalBuffers {
  /// Minimum mandatory separation between polyvalent cations (Ca2+, Fe2+, Mg2+, Al3+)
  /// and target medications (Levothyroxine, Fluoroquinolones, Bisphosphonates)
  /// to prevent insoluble chelation complex formation.
  /// Clinical Reference: FDA Levothyroxine / Ciprofloxacin Package Inserts.
  static const int minCationChelationSeparationMinutes = 240;

  /// Standard gastric emptying pre-meal fasting buffer.
  /// Medications requiring an empty stomach must be ingested at least 60 minutes
  /// before food or beverage intake (coffee, tea, milk).
  /// Clinical Reference: FDA Guidance for Industry - Food-Effect Bioavailability.
  static const int emptyStomachPreMealBufferMinutes = 60;

  /// Standard post-prandial gastric emptying buffer.
  /// Medications requiring an empty stomach must wait at least 120 minutes
  /// after a meal before ingestion.
  static const int emptyStomachPostMealBufferMinutes = 120;

  /// Prandial co-administration buffer.
  /// Medications requiring food (e.g. Metformin, NSAIDs) must be taken within
  /// 0 to 30 minutes of beginning a meal to buffer gastric mucosa.
  static const int prandialFoodBufferMinutes = 30;

  /// Standard discrete time-step interval for domain discretization (minutes).
  /// Divides the 1440-minute day into 96 discrete, computationally tractable slots.
  static const int timeStepMinutes = 15;

  /// Circadian time bounds (minute-of-day: 0 to 1439).
  static const int morningWindowStart = 360;  // 06:00 AM
  static const int morningWindowEnd = 600;    // 10:00 AM

  static const int eveningWindowStart = 1080; // 06:00 PM
  static const int eveningWindowEnd = 1260;   // 09:00 PM

  static const int bedtimeWindowStart = 1260; // 09:00 PM
  static const int bedtimeWindowEnd = 1410;   // 11:30 PM
}
