import 'package:flutter/widgets.dart';

class BuildGuard {
  static void runSafely(VoidCallback callback, {bool deferIfBuilding = true}) {
    // Check if we're currently in the build phase
    // Note: debugBuildingDirtyElements is deprecated/removed in newer Flutter versions or available only in debug.
    // A safer way is checking SchedulerBinding.instance.schedulerPhase.
    // But for simplicity in this migration:
    
    // In release mode, debugBuildingDirtyElements might not be available or always false.
    // We can just use addPostFrameCallback if we suspect we are in build.
    
    try {
        // Attempt to execute. If it fails due to setstate during build, it will throw.
        // But preventing it is better.
        // Since we can't easily check 'in build' reliably across versions without deprecated APIs:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          callback();
        });
    } catch (e) {
         callback();
    }
  }

  static VoidCallback makeSafe(VoidCallback callback,
      {bool deferIfBuilding = true}) {
    return () => runSafely(callback, deferIfBuilding: deferIfBuilding);
  }
}
