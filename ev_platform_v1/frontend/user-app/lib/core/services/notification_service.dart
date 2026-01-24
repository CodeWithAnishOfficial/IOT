// Conditional export to handle platform-specific implementations
// This prevents the flutter_local_notifications plugin from causing crashes on Web
export 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';
