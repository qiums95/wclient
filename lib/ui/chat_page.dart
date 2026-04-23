import 'package:flutter/material.dart';
import 'package:wclient/managers/data_manager.dart';
import 'package:wclient/managers/message_manager.dart';
import 'package:wclient/models/receive_message_model.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    DataManager().activeChatId == widget.chatId;
    // 使用 WidgetsBinding 延迟到第一帧渲染结束后再发起历史记录请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DataManager().loadChatHistory(widget.chatId);
    });
  }

  @override
  void dispose() {
    if (DataManager().activeChatId == widget.chatId) {
      DataManager().activeChatId = null;
    }
    _textController.dispose();
    super.dispose();
  }

  // 发送消息逻辑
  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      // 执行发送
      MessageManager().sendText(widget.chatId, text);
      // 清空输入框，因为开了 reverse: true，新消息会自动出现在列表最底部，无需手动滚动
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = DataManager().getDisplayName(widget.chatId);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          // 消息列表区域
          Expanded(
            child: ListenableBuilder(
              listenable: DataManager(), // 监听 DataManager 的数据变化
              builder: (context, child) {
                // 直接从 DataManager 获取活跃消息列表

                final messages = DataManager().activeMessages;

                if (messages.isEmpty) {
                  return const Center(child: Text("暂无聊天记录", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  // 核心魔法：反向列表。索引 0 会固定在屏幕最底端。
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          // 输入栏
          _buildInputBar(),
        ],
      ),
    );
  }

  // 消息气泡构建
  Widget _buildMessageBubble(Message msg) {
    bool isMe = msg.isSelf == 1;
    String avatar = DataManager().getAvatar(msg.senderId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(avatar),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF95EC69) : Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                msg.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) _buildAvatar(avatar),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[300],
      ),
      child: url.isNotEmpty
          ? ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(url, fit: BoxFit.cover))
          : const Icon(Icons.person, color: Colors.white),
    );
  }

  // 底部输入栏
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFFF7F7F7),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.mic_none, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.emoji_emotions_outlined, size: 28),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("发送", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}