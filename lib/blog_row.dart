import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

String createVoteMutation = """
mutation CreateVote(\$linkId : Int!) {
  createVote(linkId: \$linkId) {
    link {
      url
      description
    }
  }
}
""";

class BlogRow extends StatelessWidget {
  final String id;
  final String url;
  final String description;

  const BlogRow({
    Key? key,
    required this.id,
    required this.url,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'url : $url',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  'description: $description',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54, fontSize: 10),
                ),
                const SizedBox(height: 10),
                Mutation(
                  options: MutationOptions(
                    document: gql(createVoteMutation),
                    update: (cache, result) {
                      return cache;
                    },
                    onCompleted: (result) {
                      if (result == null) {
                        print('Completed with errors');
                      } else {
                        print('Mutation completed successfully:');
                        print(result);
                      }
                    },
                    onError: (error) {
                      print('Mutation error:');
                      print(error?.graphqlErrors[0].message);
                    },
                  ),
                  builder: (runMutation, result) {
                    return ElevatedButton(
                      onPressed: () {
                        final parsedId = int.tryParse(id);
                        if (parsedId != null) {
                          runMutation({"linkId": parsedId});
                        } else {
                          print('Invalid ID: $id');
                        }
                      },
                      child: const Text('Like!'),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
