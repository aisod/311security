import 'package:security_311_user/services/supabase_service.dart';
import 'package:security_311_user/models/emergency_contact.dart';
import 'package:security_311_user/core/logger.dart';

/// Service for managing emergency contacts
class EmergencyContactService {
  final SupabaseService _supabase = SupabaseService();

  /// Get all emergency contacts for the current user
  Future<List<EmergencyContact>> getUserEmergencyContacts() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('emergency_contacts')
          .select()
          .eq('user_id', user.id)
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      return response.map((json) => EmergencyContact.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting user emergency contacts: $e');
      return [];
    }
  }

  /// Get active emergency contacts (ordered by priority)
  Future<List<EmergencyContact>> getActiveEmergencyContacts() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return [];

      final response = await _supabase.client
          .from('emergency_contacts')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      return response.map((json) => EmergencyContact.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Error getting active emergency contacts: $e');
      return [];
    }
  }

  /// Create a new emergency contact
  Future<EmergencyContact?> createEmergencyContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    int priority = 3,
    String? notes,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final data = {
        'user_id': user.id,
        'name': name,
        'phone_number': phoneNumber,
        'relationship': relationship,
        'priority': priority,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('emergency_contacts')
          .insert(data)
          .select()
          .single();

      return EmergencyContact.fromJson(response);
    } catch (e) {
      AppLogger.error('Error creating emergency contact: $e');
      return null;
    }
  }

  /// Update an emergency contact
  Future<EmergencyContact?> updateEmergencyContact(
    String contactId, {
    String? name,
    String? phoneNumber,
    String? relationship,
    int? priority,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (relationship != null) updates['relationship'] = relationship;
      if (priority != null) updates['priority'] = priority;
      if (isActive != null) updates['is_active'] = isActive;
      if (notes != null) updates['notes'] = notes;

      final response = await _supabase.client
          .from('emergency_contacts')
          .update(updates)
          .eq('id', contactId)
          .eq('user_id', user.id)
          .select()
          .single();

      return EmergencyContact.fromJson(response);
    } catch (e) {
      AppLogger.error('Error updating emergency contact: $e');
      return null;
    }
  }

  /// Delete an emergency contact
  Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      await _supabase.client
          .from('emergency_contacts')
          .delete()
          .eq('id', contactId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      AppLogger.error('Error deleting emergency contact: $e');
      return false;
    }
  }

  /// Get a specific emergency contact
  Future<EmergencyContact?> getEmergencyContact(String contactId) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final response = await _supabase.client
          .from('emergency_contacts')
          .select()
          .eq('id', contactId)
          .eq('user_id', user.id)
          .single();

      return EmergencyContact.fromJson(response);
    } catch (e) {
      AppLogger.error('Error getting emergency contact: $e');
      return null;
    }
  }

  /// Set contact priority (reorders other contacts automatically)
  Future<bool> setContactPriority(String contactId, int newPriority) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return false;

      // First, update the target contact's priority
      await _supabase.client
          .from('emergency_contacts')
          .update({
            'priority': newPriority,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contactId)
          .eq('user_id', user.id);

      // Get all contacts and reorder priorities if needed
      final contacts = await getUserEmergencyContacts();
      final activeContacts = contacts.where((c) => c.isActive).toList();

      // Sort by current priority and reassign sequential priorities
      activeContacts.sort((a, b) => a.priority.compareTo(b.priority));

      for (int i = 0; i < activeContacts.length; i++) {
        final expectedPriority = i + 1;
        if (activeContacts[i].priority != expectedPriority) {
          await _supabase.client.from('emergency_contacts').update({
            'priority': expectedPriority,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', activeContacts[i].id);
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Error setting contact priority: $e');
      return false;
    }
  }

  /// Get emergency contact statistics
  Future<Map<String, dynamic>> getEmergencyContactStats() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {};

      final response = await _supabase.client
          .from('emergency_contacts')
          .select('relationship, is_active')
          .eq('user_id', user.id);

      final stats = <String, dynamic>{
        'total': response.length,
        'active': 0,
        'relationships': <String, int>{},
      };

      for (final contact in response) {
        final relationship = contact['relationship'] as String;
        final isActive = contact['is_active'] as bool? ?? true;

        if (isActive) {
          stats['active'] = (stats['active'] as int) + 1;
        }

        final relationships = stats['relationships'] as Map<String, int>;
        relationships[relationship] = (relationships[relationship] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      AppLogger.error('Error getting emergency contact stats: $e');
      return {};
    }
  }

  /// Listen to changes in user's emergency contacts
  Stream<List<EmergencyContact>> watchUserEmergencyContacts() {
    final user = _supabase.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase.client
        .from('emergency_contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('priority', ascending: true)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => EmergencyContact.fromJson(json)).toList());
  }
}
