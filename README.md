[Getting Started with the BLoC Pattern](https://www.raywenderlich.com/31973428-getting-started-with-the-bloc-pattern)

資料來源

![Untitled](https://koenig-media.raywenderlich.com/uploads/2020/08/03-BLoC-layers-1.png)

![Untitled](https://koenig-media.raywenderlich.com/uploads/2020/08/04-BLoC-diagram-1.png)

StreamController:

`StreamController` 是 `dart:async` 的method， 用來管理已實例化的 `stream`

和 `sink` 。 `sink`和 `stream`是相反的，`sink`  的用途是將 API data 送到 `StreamController`， 而 `stream` 監聽。

Stream: 

`Stream` 是 sequence of async events， 所以通常是和 `Future`一起使用。

summary

`BLoCs` 是 處理和儲存 business logic 的 `objects` `sinks`接收來自API 的 input， 透過 `streams`提供 output

Instruction

1. 在創建 BLoCs 之前， 每個BLoC都會 implements 這個接口。  

```dart
abstract class Bloc {
  void dispose();
}
```

1. 創建BLoC

```dart
class ArticleListBloc implements Bloc {
  // 1 RWClient 與 API 溝通
  final _client = RWClient();
  // 2 實例化 StreamController， 它會管理 input sink， 且可以告訴它傳回來的 stream 會是什麼型別
  final _searchQueryController = StreamController<String?>();
  // 3 Sink<String?> 是 public sink interface， 它會傳送事件到這個Bloc
  Sink<String?> get searchQuery => _searchQueryController.sink;
  // 4 articlesStream 是 view 和 這個bloc 之間的橋樑，
  late Stream<List<Article>?> articlesStream;

  ArticleListBloc() {
    // 5 asyncMap 監聽 client.fetchArticles(query) 是否完成?
		//如果完成，會將結果傳到 _searchQueryControll.stream，
		// 並附值給 late<Stream<List<Article>?> articlesStream  
    articlesStream = _searchQueryController.stream
        .asyncMap((query) => _client.fetchArticles(query));
  }

  // 6 StreamController 結束之後， 需要把它關掉，不然會導致 leaking。
  @override
  void dispose() {
    _searchQueryController.close();
  }
}
```

1. BLoC 注入 widget tree 
    1. 命名為Provider 是 Flutter convention
    2. Provider 用來 保存 data 並且 'well provides’ 給它的children
    3. InheritedWidget 和 StatefulWidget 都能實現關閉所有BLoCs的功能，選擇StatefulWidget 的原因是，代碼比較簡單。
    4. 步驟三之後， BLoC layer 已完成

```dart
// 1 T extends Bloc 意味著只能保存 BLoC objects
class BlocProvider<T extends Bloc> extends StatefulWidget {
  final Widget child;
  final T bloc;
	
  BlocProvider({
    Key? key,
    required this.bloc,
    required this.child,
  }) : super(key: key);

  // 2 of method 允與 BlocProvider 獲取 它的子輩的資料 例子: articlesStream
  static T of<T extends Bloc>(BuildContext context) {
    final BlocProvider<T> provider = context.findAncestorWidgetOfExactType()!;
    return provider.bloc;
  }

  @override
  State createState() => _BlocProviderState();
}

class _BlocProviderState extends State<BlocProvider> {
  // 3 BlocProvider的context == 它的child.context， so this widget won't render anythining 
  @override
  Widget build(BuildContext context) => widget.child;

  // 4 繼承StatefulWidget 為一個原因是，可以使用 dispose()。 當事件結束， 這個widget從 widget tree 移除
	// Flutter 會呼叫 dispose()， 換言之 stream 自動地被關掉。 
  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }
}
```

1.  BLoC 和 UI 連接
    1. 

```dart
//class article_list_screen.dart....
@override
Widget build(BuildContext context) {
  // 1 BlockProvider 從 widget tree 找到 ArticleListBloc
  final bloc = BlocProvider.of<ArticleListBloc>(context);
  return Scaffold(
    appBar: AppBar(title: const Text('Articles')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Search ...',
            ),
            // 2 void add(T) 是 StreamController.sink的 function，當TextField onChanged
						// sink 會開始調用 RWClient(API) 並找到相關的 articles 然後發射給 stream
            onChanged: bloc.searchQuery.add,
          ),
        ),
        Expanded(
          child:_buildResults(bloc),
        )
      ],
    ),
  );
	
	//3 StreamBuilder 從 bloc.stream 監聽事件， 這個widget會執行 builder和更新widget tree
	//當接收到新的事件， 因為StreamBuilder 和 BLoC 在這個專案你不需要使用 setState() 來更新畫面
	Widget _buildResults(ArticleListBloc bloc) {
	  // 4 StreamBuilder透過ArticleListBloc知道了。喔~我需要拿到一堆Article 
	  return StreamBuilder<List<Article>?>(
	    stream: bloc.articlesStream, // <- Stream<list<Article>?>
	    builder: (context, snapshot) {
	      // 5 當stream還沒有資料或沒有資料
	      final results = snapshot.data;
	      if (results == null) {
	        return const Center(child: Text('Loading ...'));
	      } else if (results.isEmpty) {
	        return const Center(child: Text('No Results'));
	      }
	      // 6 將results 傳遞給常規方法。
	      return _buildSearchResults(results);
	    },
	  );
	}
	
	Widget _buildSearchResults(List<Article> results) {
  return ListView.builder(
    itemCount: results.length,
    itemBuilder: (context, index) {
      final article = results[index];
      return InkWell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // 1 
          child: ArticleListItem(article: article),
        ),
        // 2 導向 article detail page
        onTap: () {
          // TODO: Later will be implemented
        },
      );
    },
  );
}
}
```

> ***[Debouncing](https://reactivex.io/documentation/operators/debounce.html) ←連結***
 means the app skips input events that come in short intervals.
> 
1. 改善UX and performance issues
    1. 每當Textfield onchanged 就會發送網路請求，解決方法: (Debouncing)略過短時間的按鍵輸入。
    2. 當 bloc.qeury.add 時 沒有loading 畫面
    3. asyncMap 等待請求完成，因此用戶會一一看到所有輸入的查詢響應。通常，您必須忽略先前的請求結果來處理新的查詢。
    4. 以上問題可以透過 business login layer 解決

```dart

//Replace
ArticleListBloc() {
    articlesStream = _searchQueryController.stream
        .asyncMap((query) => _client.fetchArticles(query));
}

//with
ArticleListBloc() {
  articlesStream = _searchQueryController.stream
      .startWith(null) // 1 如果用戶沒有輸入任何query，將會loading 全部的Articles
			// 2 輸入間隔小於0.1秒將會被忽略，並且會忽略大部分的連續輸入直到會後一個字
      .debounceTime(const Duration(milliseconds: 100)) 
      .switchMap( // 3 只會發射最後的Stream
        (query) => _client.fetchArticles(query)
            .asStream() // 4 Convert Future to Stream
							// 5 每個fetch request開始時會刪除 StreamBuilder.Articles
							//，用來正確的顯示loading畫面
            .startWith(null), 
      );
}
```

1. Article Detail and its BLoC
    
    

```dart
//step1

class ArticleDetailBloc implements Bloc {
  final String id;
  final _refreshController = StreamController<void>();
  final _client = RWClient();

  late Stream<Article?> articleStream;

  ArticleDetailBloc({
    required this.id,
  }) {
    articleStream = _refreshController.stream
        .startWith({})
        .mapTo(id)
        .switchMap(
          (id) => _client.getDetailArticle(id).asStream(),
    )
    .asBroadcastStream();
  }

  @override
  void dispose() {
    _refreshController.close();
  }
}

//step 2
class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //  1 BlockProvider 從 widget tree 找到 ArticleDetailBloc
    final bloc = BlocProvider.of<ArticleDetailBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles detail'),
      ),
      body: Container(
        alignment: Alignment.center,
      
        child: _buildContent(bloc),
      ),
    );
  }

  Widget _buildContent(ArticleDetailBloc bloc) {
    return StreamBuilder<Article?>(
      stream: bloc.articleStream,
      builder: (context, snapshot) {
        final article = snapshot.data;
        if (article == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ArticleDetail(article);
      },
    );
  }
}

//step3 更新onTap()
	Widget _buildSearchResults(List<Article> results) {
  return ListView.builder(
    itemCount: results.length,
    itemBuilder: (context, index) {
      final article = results[index];
      return InkWell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // 1 
          child: ArticleListItem(article: article),
        ),
        
				onTap: () {
				  Navigator.push(
				    context,
				    MaterialPageRoute(
				      builder: (context) => BlocProvider(
				        bloc: ArticleDetailBloc(id: article.id),
				        child: const ArticleDetailScreen(),

```

1. Refresh 功能
    1. articleStream.first is async and wait for sink.add then, render UI
    2. • Do you remember the `asBroadcastStream()` call before? It’s required because of this line. `first` creates another subscription to `articleStream`.

```dart
// 在 ArticleDetailBloc 添加refresh function
class article_detail_bloc.dart
Future refresh() {
  final future = articleStream.first; 
  _refreshController.sink.add({});
  return future;
}

//article_detail_screen.dart
...
// 1 下拉更新
body: RefreshIndicator(
  // 2 refreshIndicator 需要知道何時hide the loading indicator，所以需要用到Future
  onRefresh: bloc.refresh,
  child: Container(
    alignment: Alignment.center,
    child: _buildContent(bloc),
  ),
),
...
```

 

> ***Note***
: Dart stream doesn’t allow waiting for an event after you send something to sink in a simple way. This code can fail in rare cases when `refresh`is called at the same time an API fetch is in progress. Returned `Future`completes early, then the new update comes to `articleStream`
 and `RefreshIndicator`hides itself before the final update. It’s also wrong to send an event to sink and then request the `first`future. If a refresh event is processed immediately and a new `Article`comes before the call of `first`, the user sees infinity loading.
>
