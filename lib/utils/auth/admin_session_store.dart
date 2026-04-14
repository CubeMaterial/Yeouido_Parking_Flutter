import 'package:get_storage/get_storage.dart';

class AdminSessionStore {
  AdminSessionStore._();

  static final GetStorage _box = GetStorage();

  static const _keyStatus = 'admin.status';
  static const _keyAdminId = 'admin.admin_id';
  static const _keyAdminEmail = 'admin.admin_email';
  static const _keyAdminName = 'admin.admin_name';

  static bool get isAuthenticated => _box.read(_keyStatus) == 'authenticated';

  static int? get adminId => _box.read(_keyAdminId) as int?;
  static String? get adminEmail => _box.read(_keyAdminEmail) as String?;
  static String? get adminName => _box.read(_keyAdminName) as String?;

  static Future<void> save({
    required int adminId,
    required String adminEmail,
    String? adminName,
  }) async {
    await _box.write(_keyStatus, 'authenticated');
    await _box.write(_keyAdminId, adminId);
    await _box.write(_keyAdminEmail, adminEmail);
    await _box.write(_keyAdminName, adminName);
  }

  static Future<void> clear() async {
    await _box.remove(_keyStatus);
    await _box.remove(_keyAdminId);
    await _box.remove(_keyAdminEmail);
    await _box.remove(_keyAdminName);
  }
}
