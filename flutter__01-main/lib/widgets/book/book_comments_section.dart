import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/book_comment_model.dart';

/// Sección "¿Qué te pareció este libro?": botón de me gusta con
/// contador, formulario para comentar y lista de comentarios, con
/// eliminación de 2 clics para el autor del comentario o un
/// moderador/admin — igual que en la versión web.
class BookCommentsSection extends StatefulWidget {
  final int likeCount;
  final bool hasLiked;
  final VoidCallback onToggleLike;
  final List<BookCommentModel> comments;
  final bool isLoading;
  final String currentUserId;
  final bool canModerateAny;
  final Future<void> Function(String texto) onAddComment;
  final Future<void> Function(String commentId) onDeleteComment;

  const BookCommentsSection({
    super.key,
    required this.likeCount,
    required this.hasLiked,
    required this.onToggleLike,
    required this.comments,
    required this.isLoading,
    required this.currentUserId,
    required this.canModerateAny,
    required this.onAddComment,
    required this.onDeleteComment,
  });

  @override
  State<BookCommentsSection> createState() => _BookCommentsSectionState();
}

class _BookCommentsSectionState extends State<BookCommentsSection> {
  final _controller = TextEditingController();
  bool _isSending = false;
  final Set<String> _pendingDeleteConfirm = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    await widget.onAddComment(text);
    if (mounted) {
      _controller.clear();
      setState(() => _isSending = false);
    }
  }

  void _handleDeleteTap(String commentId) {
    if (_pendingDeleteConfirm.contains(commentId)) {
      _pendingDeleteConfirm.remove(commentId);
      widget.onDeleteComment(commentId);
    } else {
      setState(() => _pendingDeleteConfirm.add(commentId));
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _pendingDeleteConfirm.remove(commentId));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Qué te pareció este libro?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: widget.onToggleLike,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      widget.hasLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: widget.hasLiked ? AppColors.error : null,
                    ),
                    const SizedBox(width: 6),
                    Text('${widget.likeCount} me gusta'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              onPressed: _isSending ? null : _send,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Sé el primero en comentar este libro.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.comments.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final comment = widget.comments[index];
              final canDelete = widget.canModerateAny ||
                  comment.usuarioId == widget.currentUserId;
              final confirming = _pendingDeleteConfirm.contains(comment.id);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.nombreMostrado,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(comment.comentario),
                      ],
                    ),
                  ),
                  if (canDelete)
                    IconButton(
                      icon: Icon(
                        confirming
                            ? Icons.warning_rounded
                            : Icons.delete_outline_rounded,
                        color: confirming ? AppColors.error : null,
                        size: 20,
                      ),
                      tooltip: confirming
                          ? 'Toca de nuevo para confirmar'
                          : 'Eliminar comentario',
                      onPressed: () => _handleDeleteTap(comment.id),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
