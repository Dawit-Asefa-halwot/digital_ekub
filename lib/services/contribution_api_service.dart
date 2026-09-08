import 'api_service.dart';

class ContributionApiService {
  /// Create a contribution deposit for current Ekub round
  static Future<Map<String, dynamic>> createContribution(String ekubId, {double? amount, int? roundNumber}) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    if (roundNumber != null) body['roundNumber'] = roundNumber;

    final data = await ApiService.post('/ekubs/$ekubId/contributions', body: body);
    return data as Map<String, dynamic>;
  }

  /// Get current user's contributions across Ekubs
  static Future<List<Map<String, dynamic>>> getUserContributions() async {
    final data = await ApiService.get('/contributions/me');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Get contributions history for an Ekub group
  static Future<List<Map<String, dynamic>>> getEkubContributions(String ekubId) async {
    final data = await ApiService.get('/ekubs/$ekubId/contributions');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
