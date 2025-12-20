import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../presentation/viewmodels/chat_view_model.dart';
import '../../../presentation/widgets/chat_bubble.dart';
import 'chat_history_dialog.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ChatViewModel>();
      viewModel.init();
    });
  }

  Future<void> _sendMessage(ChatViewModel viewModel) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    await viewModel.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _showNewChatDialog(ChatViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Tạo chat mới'),
          ],
        ),
        content: const Text(
          'Bạn có muốn bắt đầu cuộc trò chuyện mới? Lịch sử hiện tại sẽ được lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo mới'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      viewModel.startNewConversation();
      _scrollToBottom();
    }
  }

  Future<void> _showClearHistoryDialog(ChatViewModel viewModel) async {
    // Dialog này bây giờ chỉ xóa CUỘC TRÒ CHUYỆN HIỆN TẠI, không xóa toàn bộ lịch sử
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentId = viewModel.currentConversationId;
      if (currentId != null) {
        await viewModel.deleteConversation(currentId);
      }
    }
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _showChatHistory(
      BuildContext context, ChatViewModel viewModel) async {
    // Load danh sách conversations
    final chatRepository = context.read<ChatRepository>();
    final authRepository = context.read<AuthRepository>();
    final userId = authRepository.currentUser?.uid;
    if (userId == null) return;

    try {
      final conversations = await chatRepository.getAllConversations(userId);
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => ChatHistoryDialog(
          conversations: conversations,
          onConversationSelected: (conversationId) {
            Navigator.of(dialogContext).pop();
            viewModel.loadConversation(conversationId);
            _scrollToBottom();
          },
          onConversationDeleted: (conversationId) async {
            await viewModel.deleteConversation(conversationId);
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa cuộc hội thoại'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onReload: () async {
            // Không cần reload vì đã cập nhật local state trong dialog
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch sử: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('Chat với AI'),
        actions: [
          // Nút Lịch sử - luôn hiển thị để user dễ truy cập lịch sử
          Consumer<ChatViewModel>(
            builder: (context, viewModel, _) {
              return IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Lịch sử chat',
                onPressed: () => _showChatHistory(context, viewModel),
              );
            },
          ),
          Consumer<ChatViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.messages.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Tùy chọn',
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'new_chat',
                    child: const Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 12),
                        Text('Chat mới'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Xóa cuộc trò chuyện',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'new_chat') {
                    _showNewChatDialog(viewModel);
                  } else if (value == 'clear') {
                    _showClearHistoryDialog(viewModel);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading && viewModel.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null && viewModel.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.init(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final hasMessages = viewModel.messages.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ),
            child: Column(
              children: [
                Expanded(
                  child: hasMessages
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              itemCount: viewModel.messages.length +
                                  (viewModel.isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == viewModel.messages.length) {
                                  return const TypingIndicator();
                                }

                                final message = viewModel.messages[index];
                                return ChatBubble(
                                  message: message,
                                  onLongPress: () =>
                                      _copyMessage(message.content),
                                );
                              },
                            ),
                          ),
                        )
                      : _buildEmptyState(context, viewModel),
                ),
                if (viewModel.error != null && hasMessages)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            viewModel.error!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => viewModel.retryLastMessage(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                _buildInputField(context, viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatViewModel viewModel) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Xin chào! Tôi là AI Coach của bạn',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy hỏi tôi bất cứ điều gì về sức khỏe và tập luyện',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Câu hỏi thường gặp:',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...ChatViewModel.suggestedQuestions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                viewModel.sendMessage(question);
                                _scrollToBottom();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        question,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, ChatViewModel viewModel) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 12,
        right: 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Nhập câu hỏi...',
                    hintStyle: TextStyle(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(viewModel),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<ChatViewModel>(
              builder: (context, vm, _) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: vm.isTyping
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: vm.isTyping ? null : () => _sendMessage(viewModel),
                      borderRadius: BorderRadius.circular(24),
                      child: Center(
                        child: vm.isTyping
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
