import 'package:algoliasearch/algoliasearch.dart';

class AlgoliaService {
  // Приватный конструктор для Singleton
  AlgoliaService._internal();

  // Единственный экземпляр класса
  static final AlgoliaService _instance = AlgoliaService._internal();

  // Фабрика для получения экземпляра
  factory AlgoliaService() {
    return _instance;
  }

  // Инициализация клиента
  // Вставьте ваши данные appId и apiKey
  final SearchClient client = SearchClient(
    appId: 'XR4DEPQU93',
    apiKey: 'eb255f09f97a86c1c52540313c8761e6',
  );

  /// Удаление объекта по `documentId`
  Future<void> deleteObject(String documentId) async {
    await client.deleteObject(
      indexName: "notes",
      objectID: documentId,
    );
  }

  /// Поиск заметок с помощью Algolia.
  /// [text] - строка поиска
  /// [page] - номер страницы
  /// [filtersString] - фильтры для запроса
  Future<SearchResponse> searchNotes({
    String text = '',
    int page = 0,
    String? filtersString,
  }) async {
    final query = SearchForHits(
      indexName: 'notes',
      hitsPerPage: 20,
      page: page,
      query: text,
      filters: filtersString,
    );

    return await client.searchIndex(request: query);
  }
}
