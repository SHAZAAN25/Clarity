enum StrategyMode {
  reduce,
  quitByDate,
  quitNow,
  stabilize;

  String get code {
    switch (this) {
      case StrategyMode.reduce:
        return 'REDUCE';
      case StrategyMode.quitByDate:
        return 'QUIT_BY_DATE';
      case StrategyMode.quitNow:
        return 'QUIT_NOW';
      case StrategyMode.stabilize:
        return 'STABILIZE';
    }
  }

  String get label {
    switch (this) {
      case StrategyMode.reduce:
        return 'Gradual Reduction';
      case StrategyMode.quitByDate:
        return 'Quit by Target Date';
      case StrategyMode.quitNow:
        return 'Smoke-Free (Quit Now)';
      case StrategyMode.stabilize:
        return 'Stabilization';
    }
  }

  static StrategyMode fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'QUIT_BY_DATE':
      case 'QUITBYDATE':
        return StrategyMode.quitByDate;
      case 'QUIT_NOW':
      case 'QUITNOW':
        return StrategyMode.quitNow;
      case 'STABILIZE':
        return StrategyMode.stabilize;
      case 'REDUCE':
      default:
        return StrategyMode.reduce;
    }
  }
}

class StrategyModeExtension {
  static StrategyMode fromCode(String? code) => StrategyMode.fromCode(code);
}

enum DailyTargetStatus {
  withinTarget,
  aboveTarget,
  smokeFree,
  smoked;

  String get code {
    switch (this) {
      case DailyTargetStatus.withinTarget:
        return 'WITHIN_TARGET';
      case DailyTargetStatus.aboveTarget:
        return 'ABOVE_TARGET';
      case DailyTargetStatus.smokeFree:
        return 'SMOKE_FREE';
      case DailyTargetStatus.smoked:
        return 'SMOKED';
    }
  }

  String get label {
    switch (this) {
      case DailyTargetStatus.withinTarget:
        return 'Steady (Within Target)';
      case DailyTargetStatus.aboveTarget:
        return 'Above Target';
      case DailyTargetStatus.smokeFree:
        return 'Smoke-Free Day';
      case DailyTargetStatus.smoked:
        return 'Slip Logged';
    }
  }
}

class DailyTargetStatusExtension {
  static String getCode(DailyTargetStatus s) => s.code;
}

enum CoverageStatus {
  unknown,
  partial,
  valid;

  String get code {
    switch (this) {
      case CoverageStatus.unknown:
        return 'UNKNOWN';
      case CoverageStatus.partial:
        return 'PARTIAL';
      case CoverageStatus.valid:
        return 'VALID';
    }
  }

  String get label {
    switch (this) {
      case CoverageStatus.unknown:
        return 'Untracked';
      case CoverageStatus.partial:
        return 'Partially Tracked';
      case CoverageStatus.valid:
        return 'Valid Tracked Day';
    }
  }

  static CoverageStatus fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'VALID':
        return CoverageStatus.valid;
      case 'PARTIAL':
        return CoverageStatus.partial;
      case 'UNKNOWN':
      default:
        return CoverageStatus.unknown;
    }
  }
}

class CoverageStatusExtension {
  static CoverageStatus fromCode(String? code) => CoverageStatus.fromCode(code);
}
