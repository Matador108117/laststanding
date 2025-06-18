import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String reactionsByLinkQuery = r'''
query ReactionsByLink($linkId: Int!) {
  reactionsByLink(linkId: $linkId) {
    id
    reaction { id description }
    user { id username }
  }
}
''';

const String commentsByLinkQuery = r'''
query CommentsByLink($linkId: Int!) {
  commentsByLink(linkId: $linkId) {
    id
    description
    user { id username }
  }
}
''';

const String toggleReactionMutation = r'''
mutation ToggleReaction($linkId: Int!, $reactionId: Int!) {
  createOrToggleBoatLinkReaction(linkId: $linkId, reactionId: $reactionId) {
    success
    message
  }
}
''';

const String createCommentMutation = r'''
mutation CreateComment($linkId: Int!, $description: String!) {
  createComment(linkId: $linkId, description: $description) {
    comment {
      id
      description
      user { id username }
    }
  }
}
''';

class PostCard extends StatefulWidget {
  final int linkId;
  final String username;
  final String description;
  final String imageUrl; // puede ser '' si no hay imagen
  final bool canDelete;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.linkId,
    required this.username,
    required this.description,
    required this.imageUrl,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.username,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing:
                  widget.canDelete
                      ? IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: widget.onDelete,
                      )
                      : null,
            ),

            // Descripción
            Text(widget.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),

            // Imagen segura
            // Imagen segura
            if (widget.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),

            const SizedBox(height: 10),

            // Reacciones
            Query(
              options: QueryOptions(
                document: gql(reactionsByLinkQuery),
                variables: {"linkId": widget.linkId},
                pollInterval: const Duration(seconds: 5),
              ),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return const SizedBox(height: 24);
                }
                if (result.hasException) {
                  return Text(
                    result.exception.toString(),
                    style: const TextStyle(color: Colors.red),
                  );
                }
                final reactions = result.data?['reactionsByLink'] as List;
                print('Reactions: $reactions');
                final likeCount =
                    reactions
                        .where((r) => r['reaction']['description'] == 'LIKE')
                        .length;
                final dislikeCount =
                    reactions
                        .where((r) => r['reaction']['description'] == 'DISLIKE')
                        .length;

                return Mutation(
                  options: MutationOptions(
                    document: gql(toggleReactionMutation),
                    onCompleted: (_) => refetch!(),
                  ),
                  builder: (runMutation, mutationResult) {
                    return Row(
                      children: [
                        _ReactionButton(
                          icon: Icons.thumb_up_alt_outlined,
                          activeIcon: Icons.thumb_up,
                          count: likeCount,
                          onTap:
                              () => runMutation({
                                "linkId": widget.linkId,
                                "reactionId": 1,
                              }),
                        ),
                        const SizedBox(width: 16),
                        _ReactionButton(
                          icon: Icons.thumb_down_alt_outlined,
                          activeIcon: Icons.thumb_down,
                          count: dislikeCount,
                          onTap:
                              () => runMutation({
                                "linkId": widget.linkId,
                                "reactionId": 2,
                              }),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const Divider(height: 24),

            // Comentarios
            Query(
              options: QueryOptions(
                document: gql(commentsByLinkQuery),
                variables: {"linkId": widget.linkId},
                pollInterval: const Duration(seconds: 5),
              ),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (result.hasException) {
                  return Text(
                    result.exception.toString(),
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final comments = result.data?['commentsByLink'] as List;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentarios',
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: comments.isEmpty ? 0 : 150,
                      child: ListView.separated(
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall,
                              children: [
                                TextSpan(
                                  text: '${c["user"]["username"]}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: c['description']),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input nuevo comentario
                    Mutation(
                      options: MutationOptions(
                        document: gql(createCommentMutation),
                        onCompleted: (_) {
                          _commentCtrl.clear();
                          refetch!();
                        },
                      ),
                      builder: (runMutation, __) {
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Comentar algo...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                final txt = _commentCtrl.text.trim();
                                if (txt.isNotEmpty) {
                                  runMutation({
                                    "linkId": widget.linkId,
                                    "description": txt,
                                  });
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 4),
          Text('$count'),
        ],
      ),
    );
  }
}
