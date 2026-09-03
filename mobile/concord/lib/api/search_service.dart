import 'api_client.dart';
import 'models/global_search_result_response.dart';
import 'models/paged_result.dart';

class SearchService {
  SearchService(this._client);

  final ApiClient _client;

  Future<PagedResult<GlobalSearchResultResponse>> searchMessages(
    String query, {
    required int page,
    required int pageSize,
  }) async {
    final data = await _client.get('/Search/Messages', query: {'query': query, 'page': page, 'pageSize': pageSize});
    return PagedResult.fromJson(data as Map<String, dynamic>, GlobalSearchResultResponse.fromJson);
  }
}
