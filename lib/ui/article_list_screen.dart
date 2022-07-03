import 'package:article_finder/bloc/article_detail_bloc.dart';
import 'package:article_finder/bloc/article_list_bloc.dart';
import 'package:article_finder/bloc/bloc_provider.dart';
import 'package:article_finder/ui/article_detail_screen.dart';
import 'package:article_finder/ui/article_list_item.dart';
import 'package:flutter/material.dart';

import '../data/article.dart';

class ArticleListScreen extends StatelessWidget {
  const ArticleListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlockProvider.of<ArticleListBloc>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'Search ...'),
              //onChanged to submit keywords to BLoC
              onChanged: bloc.searchQuery.add,
            ),
          ),
          Expanded(
            //builds the list with Article objects
            child: _buildResults(bloc),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ArticleListBloc bloc) {
    return StreamBuilder<List<Article>?>(
      stream: bloc.articlesStream,
      builder: (context, snapshot) {
        final results = snapshot.data;
        if (results == null) {
          return const Center(child: Text('Loading ....'));
        } else if (results.isEmpty) {
          return const Center(child: Text('No Results'));
        }
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
          // 2
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BlockProvider(
                          bloc: ArticleDetailBloc(id: article.id),
                          child: const ArticleDetailScreen(),
                        )));
          },
        );
      },
    );
  }
}
