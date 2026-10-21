import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewardsapp/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Covers the "profile data only appears after a refresh" fix:
/// [SecureStorageService.identityChanged] must fire on every write/clear of
/// the cached identity, since that's the signal already-mounted screens
/// (Settings, Home's header) rely on to refresh without a fresh mount.
void main() {
  late MockFlutterSecureStorage storage;
  late SecureStorageService service;

  setUp(() {
    storage = MockFlutterSecureStorage();
    service = SecureStorageService(storage);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
        iOptions: any(named: 'iOptions'),
        aOptions: any(named: 'aOptions'),
        lOptions: any(named: 'lOptions'),
        webOptions: any(named: 'webOptions'),
        mOptions: any(named: 'mOptions'),
        wOptions: any(named: 'wOptions'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.delete(
        key: any(named: 'key'),
        iOptions: any(named: 'iOptions'),
        aOptions: any(named: 'aOptions'),
        lOptions: any(named: 'lOptions'),
        webOptions: any(named: 'webOptions'),
        mOptions: any(named: 'mOptions'),
        wOptions: any(named: 'wOptions'),
      ),
    ).thenAnswer((_) async {});
  });

  test('saveIdentity fires identityChanged after the write actually completes', () async {
    final events = <void>[];
    final sub = service.identityChanged.listen(events.add);

    await service.saveIdentity(userId: 'u1', fullName: 'Jane Doe', phone: '+1', countryCode: 'US');
    // StreamController.broadcast() delivers to listeners on the next
    // microtask, not synchronously within .add() itself.
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    await sub.cancel();
  });

  test('clearIdentity also fires identityChanged -- a wiped identity must revert an '
      'already-mounted screen back to the Guest state immediately too', () async {
    final events = <void>[];
    final sub = service.identityChanged.listen(events.add);

    await service.clearIdentity();
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    await sub.cancel();
  });

  test('identityChanged is a broadcast stream -- multiple listeners (Settings and Home\'s '
      'header at the same time) can both react to the same save', () async {
    var firstCount = 0;
    var secondCount = 0;
    final sub1 = service.identityChanged.listen((_) => firstCount++);
    final sub2 = service.identityChanged.listen((_) => secondCount++);

    await service.saveIdentity(userId: 'u1', fullName: 'Jane Doe');
    await Future<void>.delayed(Duration.zero);

    expect(firstCount, 1);
    expect(secondCount, 1);
    await sub1.cancel();
    await sub2.cancel();
  });
}
