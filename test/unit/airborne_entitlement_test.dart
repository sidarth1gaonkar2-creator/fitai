import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:fitai/providers/entitlement_providers.dart';
import 'package:fitai/services/revenuecat_service.dart';

class _MockCustomerInfo extends Mock implements CustomerInfo {}

const _airborneEntitlement = EntitlementInfo(
  kAirborneEntitlementId,
  true,
  true,
  '2026-07-01T00:00:00Z',
  '2026-07-01T00:00:00Z',
  'rc_airborne_monthly',
  true,
);

/// CustomerInfo whose active entitlements are exactly [active].
CustomerInfo _customerInfo({required bool airborne}) {
  final info = _MockCustomerInfo();
  final active = airborne
      ? {kAirborneEntitlementId: _airborneEntitlement}
      : <String, EntitlementInfo>{};
  when(() => info.entitlements).thenReturn(EntitlementInfos(active, active));
  return info;
}

void main() {
  group('airborneActiveFrom', () {
    test('true when the airborne entitlement is active', () {
      expect(airborneActiveFrom(_customerInfo(airborne: true)), isTrue);
    });

    test('false when no airborne entitlement is active', () {
      expect(airborneActiveFrom(_customerInfo(airborne: false)), isFalse);
    });
  });

  group('AirborneEntitlementNotifier', () {
    test('degraded mode (unconfigured) is inert: false, no SDK calls', () async {
      var fetchCalls = 0;
      var listenerAdds = 0;
      final notifier = AirborneEntitlementNotifier(
        configured: false,
        getCustomerInfo: () async {
          fetchCalls++;
          return _customerInfo(airborne: true);
        },
        addListener: (_) => listenerAdds++,
        removeListener: (_) {},
      );
      await pumpEventQueue();
      expect(notifier.state, isFalse);
      expect(fetchCalls, 0);
      expect(listenerAdds, 0);
      notifier.dispose();
    });

    test('initial refresh flips state to true for an entitled user', () async {
      final notifier = AirborneEntitlementNotifier(
        configured: true,
        getCustomerInfo: () async => _customerInfo(airborne: true),
        addListener: (_) {},
        removeListener: (_) {},
      );
      expect(notifier.state, isFalse); // before the async fetch lands
      await pumpEventQueue();
      expect(notifier.state, isTrue);
      notifier.dispose();
    });

    test('initial refresh stays false for a free user', () async {
      final notifier = AirborneEntitlementNotifier(
        configured: true,
        getCustomerInfo: () async => _customerInfo(airborne: false),
        addListener: (_) {},
        removeListener: (_) {},
      );
      await pumpEventQueue();
      expect(notifier.state, isFalse);
      notifier.dispose();
    });

    test('customer-info update listener drives state both directions',
        () async {
      CustomerInfoUpdateListener? captured;
      final notifier = AirborneEntitlementNotifier(
        configured: true,
        getCustomerInfo: () async => _customerInfo(airborne: false),
        addListener: (l) => captured = l,
        removeListener: (_) {},
      );
      await pumpEventQueue();
      expect(captured, isNotNull);

      captured!(_customerInfo(airborne: true)); // purchase lands
      expect(notifier.state, isTrue);

      captured!(_customerInfo(airborne: false)); // expiry / logOut
      expect(notifier.state, isFalse);
      notifier.dispose();
    });

    test('fetch failure keeps the previous state (never yanks a paid unlock)',
        () async {
      CustomerInfoUpdateListener? captured;
      var shouldThrow = false;
      final notifier = AirborneEntitlementNotifier(
        configured: true,
        getCustomerInfo: () async {
          if (shouldThrow) throw Exception('network down');
          return _customerInfo(airborne: true);
        },
        addListener: (l) => captured = l,
        removeListener: (_) {},
      );
      await pumpEventQueue();
      expect(notifier.state, isTrue);

      shouldThrow = true;
      await notifier.refresh(); // must not throw
      expect(notifier.state, isTrue, reason: 'error must not reset the state');
      expect(captured, isNotNull);
      notifier.dispose();
    });

    test('dispose unregisters the SDK listener', () async {
      CustomerInfoUpdateListener? added;
      CustomerInfoUpdateListener? removed;
      final notifier = AirborneEntitlementNotifier(
        configured: true,
        getCustomerInfo: () async => _customerInfo(airborne: false),
        addListener: (l) => added = l,
        removeListener: (l) => removed = l,
      );
      await pumpEventQueue();
      notifier.dispose();
      expect(removed, isNotNull);
      expect(identical(added, removed), isTrue);
    });
  });
}
