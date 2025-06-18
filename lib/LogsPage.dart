import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'MyAppState.dart';
import 'post_card.dart'; // Asegúrate de tenerlo importado

const String query = """
query Links {
  links {
    id
    url
    description
    postedBy {
      id
      username
    }
  }
}
""";

class LogsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final myUserId = appState.userId; // Asegúrate de tener esto en tu estado

    if (appState.token.isEmpty) {
      return const Center(
        child: Text('No login yet.'),
      );
    }

    return Query(
      options: QueryOptions(document: gql(query)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(child: Text(result.exception.toString()));
        }

        final posts = result.data!['links'];
        if (posts.isEmpty) {
          return const Center(child: Text("No posts found!"));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postId = post['id'];
            final description = post['description'];
            final imageUrl = post['url'] ?? '';
            final username = post['postedBy']?['username'] ?? 'Anon';
            final userId = post['postedBy']?['id'];

            return PostCard(
              linkId: int.parse(postId.toString()),
              username: username,
              description: description,
              imageUrl: imageUrl,
              canDelete: "$userId" == "${appState.userId}", // Comparar como strings
              onDelete: () {
                // Aquí puedes implementar la mutación de eliminación
                print("Eliminar publicación $postId");
              },
            );
          },
        );
      },
    );
  }
}
