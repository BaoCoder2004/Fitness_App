import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../domain/entities/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  final ChatMessage message;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            gradient: isUser
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: isUser
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            border: isUser
                ? null
                : Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị markdown cho AI messages, text thuần cho user messages
              isUser
                  ? Text(
                      message.content,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        h1: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h2: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h3: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        strong: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        em: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        code: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          backgroundColor: theme.colorScheme.surface,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        blockquote: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      shrinkWrap: true,
                    ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person : Icons.smart_toy,
                    size: 12,
                    color: isUser
                        ? theme.colorScheme.onPrimary.withOpacity(0.7)
                        : theme.colorScheme.primary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Widget để hiển thị typing indicator
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            _buildDot(0, theme),
            const SizedBox(width: 6),
            _buildDot(1, theme),
            const SizedBox(width: 6),
            _buildDot(2, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.3;
        final animationValue = ((value + delay) % 1.0);
        final opacity = animationValue < 0.5 ? 0.3 : 1.0;
        final scale = animationValue < 0.5 ? 0.8 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(opacity),
                  theme.colorScheme.primary.withOpacity(opacity * 0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

