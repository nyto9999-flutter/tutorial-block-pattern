import 'dart:async';
import 'package:article_finder/data/article.dart';
import 'package:article_finder/data/rw_client.dart';
import 'bloc.dart';
import 'package:rxdart/rxdart.dart';
/*note: separate BLoCs for each Screen
ArticleListScreen uses ArticleListBloc */

class ArticleListBloc implements Bloc {
  /*1. Create instance of RWClient to communicate with raywenderlich.com
  based on HTTP protocol */
  final _client = RWClient();

  /*2. It will manage the input sink for this BloC
  SteamController use generics to tell the type system
  what kind of object the stream will emit. */
  final _searchQueryController = StreamController<String?>();

  /*3. Sink<String?> is a public sink interface for your input
  controller '_searchQueryController'. using this sink to send
  events to the BLoC */
  Sink<String?> get searchQuery => _searchQueryController.sink;

  /*4. articleSteam acts as a bridge between 'ArticleListScreen'
  and 'ArticleListBloC' The BLoC will stream a list of articles
  onto the screen*/
  late Stream<List<Article>?> articlesStream;

  ArticleListBloc() {
    articlesStream = _searchQueryController.stream
        .startWith(null) // 1
        .debounceTime(const Duration(milliseconds: 100)) // 2
        .switchMap(
          // 3
          (query) => _client
              .fetchArticles(query)
              .asStream() // 4 convert Future to stream
              .startWith(null), // 5
        );
  }

  void dispose() {
    _searchQueryController.close();
  }
}
