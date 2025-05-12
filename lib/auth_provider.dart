import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentRole;
  String? _currentAreaId;
  String? _currentPinId;

  String? get currentRole => _currentRole;
  String? get currentAreaId => _currentAreaId;
  String? get currentPinId => _currentPinId;
  bool get isAuthenticated => _currentRole != null;

  Future<bool> verifyPin(String pin, String module) async {
    if (pin.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      await _logAccess(null, module, false);
      return false;
    }

    try {
      final response = await _supabase
          .from('auth_pins')
          .select('*, area:area_id(*)')
          .eq('pin_code', pin)
          .eq('is_active', true)
          .gte('expires_at', DateTime.now().toUtc().toIso8601String())
          .maybeSingle();

      if (response != null) {
        // Si es admin, permitir acceso sin verificar restricciones
        if (response['role'] == 'admin') {
          _setAuthState(response);
          await _logAccess(response['id'], module, true);
          return true;
        }

        // Para otros roles, verificar restricciones si existen
        final restriction = await _supabase
            .from('pin_restrictions')
            .select()
            .eq('pin_id', response['id'])
            .eq('module_name', module)
            .maybeSingle();

        if (restriction == null || restriction['can_view'] == true) {
          _setAuthState(response);
          await _logAccess(response['id'], module, true);
          return true;
        }
      }

      await _logAccess(response?['id'], module, false);
      return false;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      await _logAccess(null, module, false);
      return false;
    }
  }

  void _setAuthState(Map<String, dynamic> response) {
    _currentRole = response['role'];
    _currentAreaId = response['area_id'];
    _currentPinId = response['id'];
  }

  Future<bool> _checkModuleAccess(String pinId, String module) async {
    final response = await _supabase
        .from('pin_restrictions')
        .select()
        .eq('pin_id', pinId)
        .eq('module_name', module)
        .maybeSingle();

    // Si no hay restricción específica, permitir acceso
    return response == null || response['can_view'] == true;
  }

  Future<void> _logAccess(
    String? pinId,
    String module,
    bool success,
  ) async {
    try {
      await _supabase.from('pin_access_logs').insert({
        'pin_id': pinId,
        'module_accessed': module,
        'access_status': success ? 'success' : 'failed',
        'access_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging access: $e');
      // Opcional: Crear una versión simplificada del log si falla
      await _supabase.from('pin_access_logs').insert({
        'pin_id': pinId,
        'module_accessed': module,
        'access_time': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPinId = prefs.getString('last_pin_id');

    if (lastPinId != null) {
      // Verificar si el PIN sigue siendo válido
      final response = await _supabase
          .from('auth_pins')
          .select()
          .eq('id', lastPinId)
          .eq('is_active', true)
          .gte('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response != null) {
        _currentPinId = lastPinId;
        _currentRole = prefs.getString('last_role');
        _currentAreaId = prefs.getString('last_area_id');
        notifyListeners();
      } else {
        await logout();
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_pin_id');
    await prefs.remove('last_role');
    await prefs.remove('last_area_id');

    _currentRole = null;
    _currentAreaId = null;
    _currentPinId = null;

    notifyListeners();
  }
}
