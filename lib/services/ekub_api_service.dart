import '../models/ekub_model.dart';
import 'api_service.dart';

class EkubApiService {
  /// Discover Ekub groups with search and filters
  static Future<List<EkubModel>> discoverEkubs({
    String? search,
    String? category,
    String? type,
    String? frequency,
    double? minContribution,
    double? maxContribution,
    bool? availableSlotsOnly,
  }) async {
    final queryParams = <String>[];
    if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');
    if (category != null && category.isNotEmpty && category != 'All') queryParams.add('category=${Uri.encodeComponent(category.toUpperCase())}');
    if (type != null && type.isNotEmpty && type != 'All') queryParams.add('type=${Uri.encodeComponent(type.toUpperCase())}');
    if (frequency != null && frequency.isNotEmpty && frequency != 'All') queryParams.add('frequency=${Uri.encodeComponent(frequency.toUpperCase())}');
    if (minContribution != null) queryParams.add('minContribution=$minContribution');
    if (maxContribution != null) queryParams.add('maxContribution=$maxContribution');
    if (availableSlotsOnly == true) queryParams.add('availableSlotsOnly=true');

    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final data = await ApiService.get('/ekubs$queryString');

    if (data is List) {
      return data.map((json) => EkubModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get single Ekub details by ID
  static Future<EkubModel> getEkubDetails(String id) async {
    final data = await ApiService.get('/ekubs/$id');
    return EkubModel.fromJson(data as Map<String, dynamic>);
  }

  /// Get members roster for an Ekub
  static Future<List<Map<String, dynamic>>> getMembers(String ekubId) async {
    final data = await ApiService.get('/ekubs/$ekubId/members');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Join an Ekub group
  static Future<Map<String, dynamic>> joinEkub(String ekubId) async {
    final data = await ApiService.post('/ekubs/$ekubId/join');
    return data as Map<String, dynamic>;
  }

  /// Leave/Withdraw from an Ekub group
  static Future<Map<String, dynamic>> leaveEkub(String ekubId) async {
    final data = await ApiService.post('/ekubs/$ekubId/leave');
    return data as Map<String, dynamic>;
  }

  /// Get draw results for an Ekub
  static Future<List<Map<String, dynamic>>> getDrawResults(String ekubId) async {
    final data = await ApiService.get('/ekubs/$ekubId/draw-results');
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
