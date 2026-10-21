import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Contract consumed by the redesigned UI. A VPS adapter can implement it
/// once the server contract exists, without changing screen data models.
abstract class RewardsRepository extends ChangeNotifier {
  String? get email;
  String get name;
  int get character;
  int get balance;
  List<Map<String, dynamic>> get orders;
  List<Map<String, dynamic>> get entries;
  List<Map<String, dynamic>> get notifications;
  String? get pendingEmail;
  int get pendingStage;
  Future<void> saveOnboarding(String email, int stage);
  Future<bool> restore();
  Future<bool> accountExists(String email);
  Future<bool> login(String email, String password);
  Future<void> createAccount(String email, String password, int character);
  Future<void> logout();
  Future<bool> resetPassword(String email, String password);
  Future<bool> redeem(DemoProduct product, {Map<String, String> fulfillmentDetails = const {}});
  Future<String?> enterGiveaway(DemoGiveaway giveaway);
  Future<void> readNotification(int index);
  Future<void> updateProfile(String name, int character);
}

class DemoCategory {
  const DemoCategory(this.id, this.title, this.subtitle, this.colors, this.icon);
  final String id;
  final String title;
  final String subtitle;
  final List<int> colors;
  final String icon;
}

class DemoProduct {
  const DemoProduct(
    this.id,
    this.categoryId,
    this.title,
    this.points,
    this.icon, [
    this.group = 'Top-Ups',
  ]);
  final String id;
  final String categoryId;
  final String title;
  final int points;
  final String icon;
  final String group;

  /// Local presentation metadata with the same field concepts as PRD-002.
  /// A catalog adapter can supply product-specific definitions later.
  List<DemoFulfillmentField> get fulfillmentFields => switch (categoryId) {
    'battle' => const [
      DemoFulfillmentField(
        'player_id',
        'PUBG Player ID',
        'معرّف لاعب ببجي',
        type: DemoFieldType.number,
        minLength: 5,
        maxLength: 12,
        confirmEntry: true,
      ),
    ],
    'tactical' => const [
      DemoFulfillmentField(
        'riot_id',
        'Riot ID',
        'معرّف رايوت',
        hint: 'Player#TAG',
        hintAr: 'اللاعب#الرمز',
        pattern: r'^.{3,16}#[A-Za-z0-9]{3,5}$',
      ),
    ],
    'social' => const [
      DemoFulfillmentField('profile', 'Instagram username or URL', 'اسم مستخدم إنستغرام أو الرابط'),
    ],
    'video' => const [
      DemoFulfillmentField('profile', 'TikTok username or URL', 'اسم مستخدم تيك توك أو الرابط'),
    ],
    'community' => const [
      DemoFulfillmentField(
        'profile',
        'Facebook profile URL',
        'رابط ملف فيسبوك',
        type: DemoFieldType.url,
      ),
    ],
    'phones' => const [
      DemoFulfillmentField('full_name', 'Recipient name', 'اسم المستلم'),
      DemoFulfillmentField('phone', 'Phone number', 'رقم الهاتف', type: DemoFieldType.phone),
      DemoFulfillmentField('address_line1', 'Shipping address', 'عنوان الشحن'),
      DemoFulfillmentField('city', 'City', 'المدينة'),
    ],
    _ => const [],
  };
}

enum DemoFieldType { text, number, url, phone }

class DemoFulfillmentField {
  const DemoFulfillmentField(
    this.key,
    this.label,
    this.labelAr, {
    this.hint,
    this.hintAr,
    this.type = DemoFieldType.text,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.confirmEntry = false,
  });
  final String key;
  final String label;
  final String labelAr;
  final String? hint;
  final String? hintAr;
  final DemoFieldType type;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final bool confirmEntry;
}

class DemoGiveaway {
  const DemoGiveaway(this.id, this.title, this.subtitle, this.icon);
  final String id;
  final String title;
  final String subtitle;
  final String icon;
}

const demoCategories = <DemoCategory>[
  DemoCategory('battle', 'PUBG Mobile', 'UC Top-Ups', [0xff0777ca, 0xff91c9f9], ''),
  DemoCategory('tactical', 'Valorant', 'Points & Skins', [0xff30217f, 0xffef4873], ''),
  DemoCategory('social', 'Instagram', 'Followers & Likes', [0xffdd1883, 0xffff7b53], ''),
  DemoCategory('video', 'TikTok', 'Followers & Engagement', [0xff0d1028, 0xff4045a1], ''),
  DemoCategory('community', 'Facebook', 'Followers & Page Growth', [0xff0758dd, 0xff26bbff], ''),
  DemoCategory('phones', 'Phones', 'Smartphones & Accessories', [0xffcdaff8, 0xff90b9fa], ''),
];

const demoProducts = <DemoProduct>[
  DemoProduct('credits60', 'battle', '60 UC', 1200, ''),
  DemoProduct('credits180', 'battle', '180 UC', 3200, ''),
  DemoProduct('credits325', 'battle', '325 UC', 5500, ''),
  DemoProduct('credits660', 'battle', '660 UC', 10000, ''),
  DemoProduct('credits1800', 'battle', '1800 UC', 25000, ''),
  DemoProduct('credits3850', 'battle', '3850 UC', 50000, ''),
  DemoProduct('outfit', 'battle', 'Hero Outfit', 7500, '', 'Items & Skins'),
  DemoProduct('skin', 'tactical', 'Hero Skin', 4000, ''),
  DemoProduct('bundle', 'tactical', 'Premium Bundle', 9500, ''),
  DemoProduct('creator', 'social', 'Creator Pack', 2800, ''),
  DemoProduct('video', 'video', 'Video Pack', 2400, ''),
  DemoProduct('community', 'community', 'Community Pack', 3000, ''),
  DemoProduct('phone', 'phones', 'Phone Accessories', 7000, ''),
];

const demoGiveaways = <DemoGiveaway>[
  DemoGiveaway('earbuds', 'AirPods Pro', 'Apple • Ends in 5 days', ''),
  DemoGiveaway('smartphone', 'iPhone 15 Pro', 'Apple • Ends in 12 days', ''),
  DemoGiveaway('console', 'PlayStation 5', 'Console • Ends in 2 days', ''),
  DemoGiveaway('coffee', 'Coffee Machine', 'Home & Living • Coming soon', ''),
];

/// Local demo implementation. No calls to Supabase or production services.
/// Passwords and the current session are stored in platform secure storage;
/// the demo ledger and presentation data are persisted in a separate Hive box.
class LocalRewardsRepository extends RewardsRepository {
  LocalRewardsRepository(this._box, this._secure);
  final Box _box;
  final FlutterSecureStorage _secure;
  String? _email;
  Future<void> _pendingMutation = Future<void>.value();
  String get _prefix => 'user:${_email ?? ''}:';

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pendingMutation.then((_) => operation());
    _pendingMutation = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }

  static Future<LocalRewardsRepository> open() async {
    await Hive.initFlutter();
    return LocalRewardsRepository(
      await Hive.openBox('redesign_demo_v1'),
      const FlutterSecureStorage(),
    );
  }

  @override
  String? get email => _email;
  @override
  String? get pendingEmail => _box.get('onboarding_email') as String?;
  @override
  int get pendingStage => _box.get('onboarding_stage', defaultValue: 0) as int;

  @override
  Future<void> saveOnboarding(String email, int stage) async {
    await _box.put('onboarding_email', email.toLowerCase().trim());
    await _box.put('onboarding_stage', stage);
  }

  @override
  String get name =>
      _box.get('${_prefix}name', defaultValue: _email?.split('@').first ?? 'Guest') as String;
  @override
  int get character => _box.get('${_prefix}character', defaultValue: 1) as int;
  @override
  int get balance => _box.get('${_prefix}balance', defaultValue: 0) as int;
  @override
  List<Map<String, dynamic>> get orders => _maps('${_prefix}orders');
  @override
  List<Map<String, dynamic>> get entries => _maps('${_prefix}entries');
  @override
  List<Map<String, dynamic>> get notifications => _maps('${_prefix}notifications');

  List<Map<String, dynamic>> _maps(String key) => ((_box.get(key) as List?) ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  Future<void> _saveList(String key, List<Map<String, dynamic>> value) => _box.put(key, value);

  @override
  Future<bool> restore() async {
    final storedEmail = await _secure.read(key: 'redesign_session_email');
    final expiry = int.tryParse(await _secure.read(key: 'redesign_session_expiry') ?? '');
    if (storedEmail == null || expiry == null || DateTime.now().millisecondsSinceEpoch >= expiry) {
      await logout();
      return false;
    }
    _email = storedEmail;
    notifyListeners();
    return true;
  }

  Future<void> _startSession(String email) async {
    _email = email.toLowerCase().trim();
    await _secure.write(key: 'redesign_session_email', value: _email);
    await _secure.write(
      key: 'redesign_session_expiry',
      value: DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch.toString(),
    );
    notifyListeners();
  }

  @override
  Future<bool> login(String email, String password) async {
    final normalized = email.toLowerCase().trim();
    final stored = await _secure.read(key: 'redesign_password:$normalized');
    if (stored == null || stored != password) return false;
    await _startSession(normalized);
    return true;
  }

  @override
  Future<bool> accountExists(String email) async =>
      await _secure.read(key: 'redesign_password:${email.toLowerCase().trim()}') != null;

  @override
  Future<void> createAccount(String email, String password, int character) async {
    final normalized = email.toLowerCase().trim();
    if (await _secure.read(key: 'redesign_password:$normalized') != null) {
      throw StateError('An account with this email already exists');
    }
    await _secure.write(key: 'redesign_password:$normalized', value: password);
    await _startSession(normalized);
    await _box.delete('onboarding_email');
    await _box.delete('onboarding_stage');
    await _box.put('${_prefix}name', normalized.split('@').first);
    await _box.put('${_prefix}character', character);
    await _box.put('${_prefix}balance', 6000);
    await _saveList('${_prefix}notifications', [
      {
        'title': 'Welcome to Creative Rewards',
        'body': '6,000 demo points were added to your wallet.',
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      },
    ]);
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    _email = null;
    await _secure.delete(key: 'redesign_session_email');
    await _secure.delete(key: 'redesign_session_expiry');
    notifyListeners();
  }

  @override
  Future<bool> resetPassword(String email, String password) async {
    final normalized = email.toLowerCase().trim();
    if (await _secure.read(key: 'redesign_password:$normalized') == null) return false;
    await _secure.write(key: 'redesign_password:$normalized', value: password);
    return true;
  }

  @override
  Future<bool> redeem(DemoProduct product, {Map<String, String> fulfillmentDetails = const {}}) =>
      _serialize(() async {
        if (_email == null || balance < product.points) return false;
        final updatedOrders = orders;
        updatedOrders.insert(0, {
          'id': 'DEMO-${DateTime.now().microsecondsSinceEpoch}',
          'title': product.title,
          'points': product.points,
          'fulfillmentDetails': Map<String, String>.from(fulfillmentDetails),
          'fulfillmentFields': product.fulfillmentFields
              .map((field) => {'key': field.key, 'label': field.label, 'labelAr': field.labelAr})
              .toList(),
          'date': DateTime.now().toIso8601String(),
          'status': 'Demo order • no fulfillment',
        });
        final updatedNotifications = notifications;
        updatedNotifications.insert(0, {
          'title': 'Demo order created',
          'body': '${product.title} was redeemed for ${product.points} points.',
          'createdAt': DateTime.now().toIso8601String(),
          'read': false,
        });
        await _box.putAll({
          '${_prefix}balance': balance - product.points,
          '${_prefix}orders': updatedOrders,
          '${_prefix}notifications': updatedNotifications,
        });
        notifyListeners();
        return true;
      });

  @override
  Future<String?> enterGiveaway(DemoGiveaway giveaway) => _serialize(() async {
    if (_email == null || giveaway.id == 'coffee') return null;
    final existing = entries.where((e) => e['giveaway'] == giveaway.id);
    if (existing.isNotEmpty) return existing.first['number'] as String;
    final number = (100000 + Random.secure().nextInt(900000)).toString();
    final updated = entries;
    updated.insert(0, {'giveaway': giveaway.id, 'title': giveaway.title, 'number': number});
    final updatedNotifications = notifications;
    updatedNotifications.insert(0, {
      'title': 'Demo entry created',
      'body': '${giveaway.title}: your number is $number.',
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    });
    await _box.putAll({
      '${_prefix}entries': updated,
      '${_prefix}notifications': updatedNotifications,
    });
    notifyListeners();
    return number;
  });

  @override
  Future<void> readNotification(int index) async {
    final updated = notifications;
    if (index < 0 || index >= updated.length) return;
    updated[index]['read'] = true;
    await _saveList('${_prefix}notifications', updated);
    notifyListeners();
  }

  @override
  Future<void> updateProfile(String name, int character) async {
    await _box.put('${_prefix}name', name.trim());
    await _box.put('${_prefix}character', character);
    notifyListeners();
  }
}
