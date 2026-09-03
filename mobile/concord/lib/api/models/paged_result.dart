import 'json_utils.dart';

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems = json.field('Items') as List<dynamic>? ?? const [];
    return PagedResult<T>(
      items: rawItems.map((e) => itemFromJson(e as Map<String, dynamic>)).toList(),
      page: json.field('Page') as int,
      pageSize: json.field('PageSize') as int,
      totalCount: json.field('TotalCount') as int,
    );
  }

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasNextPage => page * pageSize < totalCount;
}
