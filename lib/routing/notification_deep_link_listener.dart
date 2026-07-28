import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'app_router.dart';

/// Consumes notification-tap deep links (retention band) and navigates to the
/// target SHELL SUB-ROUTE via plain `context.go` — the go_router cross-shell
/// safe pattern: never a push from outside the shell, never a standalone
/// route. Routes are already validated to [kRetentionAllowedRoutes] in
/// NotificationService before they reach [NotificationService.pendingDeepLink].
///
/// Renders nothing; lives as a sibling inside the app's builder so it can
/// reach the live [appRouterProvider] and stays mounted across navigation.
class NotificationDeepLinkListener extends ConsumerStatefulWidget {
  const NotificationDeepLinkListener({super.key});

  @override
  ConsumerState<NotificationDeepLinkListener> createState() =>
      _NotificationDeepLinkListenerState();
}

class _NotificationDeepLinkListenerState
    extends ConsumerState<NotificationDeepLinkListener> {
  @override
  void initState() {
    super.initState();
    NotificationService.pendingDeepLink.addListener(_handle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cold start: surface a tap that launched the app (sets pendingDeepLink,
      // which fires _handle), then sweep once for anything already pending.
      NotificationService.instance.primeLaunchDeepLink();
      _handle();
    });
  }

  @override
  void dispose() {
    NotificationService.pendingDeepLink.removeListener(_handle);
    super.dispose();
  }

  void _handle() {
    final route = NotificationService.pendingDeepLink.value;
    if (route == null) return;
    NotificationService.pendingDeepLink.value = null; // consume once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appRouterProvider).go(route);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
