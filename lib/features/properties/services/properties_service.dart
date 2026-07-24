import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class PropertiesService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
    bool? includeDeleted,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParameters['categoryId'] = categoryId;
      }
      if (areaId != null && areaId.isNotEmpty) {
        queryParameters['areaId'] = areaId;
      }
      if (listingTypeId != null && listingTypeId.isNotEmpty) {
        queryParameters['listingTypeId'] = listingTypeId;
      }
      if (createdBy != null && createdBy.isNotEmpty) {
        queryParameters['createdBy'] = createdBy;
      }
      if (isVerified != null) {
        queryParameters['isVerified'] = isVerified.toString();
      }
      if (includeDeleted != null) {
        queryParameters['includeDeleted'] = includeDeleted.toString();
      }

      final response = await _apiClient.get(
        '/properties',
        queryParameters: queryParameters,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getPropertyMetadata() async {
    try {
      final response = await _apiClient.get('/properties/metadata');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiClient.post('/properties', propertyData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateProperty(String id, Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiClient.put('/properties/$id', propertyData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> togglePropertyVerification(String id, bool isVerified) async {
    try {
      final response = await _apiClient.patch(
        '/properties/$id/verify',
        {'isVerified': isVerified},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> softDeleteProperty(String id) async {
    try {
      final response = await _apiClient.delete('/properties/$id');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> restoreProperty(String id) async {
    try {
      final response = await _apiClient.patch('/properties/$id/restore', {});
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createCity(String name) async {
    try {
      final response = await _apiClient.post('/properties/cities', {'city_name': name});
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createArea(String cityId, String name, String pincode) async {
    try {
      final response = await _apiClient.post('/properties/areas', {
        'city_id': cityId,
        'area_name': name,
        'pincode': pincode,
      });
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createAmenity(String name) async {
    try {
      final response = await _apiClient.post('/properties/amenities', {
        'name': name,
      });
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createLookup(String masterType, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.post('/lookup/$masterType', payload);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> checkDuplicate(Map<String, dynamic> checkParams) async {
    try {
      final response = await _apiClient.post('/properties/check-duplicate', checkParams);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> deleteCity(String id) async {
    try {
      await _apiClient.delete('/properties/cities/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> deleteArea(String id) async {
    try {
      await _apiClient.delete('/properties/areas/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getBinProperties() async {
    try {
      final response = await _apiClient.get(
        '/properties',
        queryParameters: {'includeDeleted': 'true'},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }


  Future<void> permanentDeleteProperty(String id) async {
    try {
      await _apiClient.delete('/properties/$id/permanent');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> emptyBin() async {
    try {
      await _apiClient.delete('/properties/bin/empty');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
