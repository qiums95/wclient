import 'package:flutter/material.dart';
import 'package:wclient/managers/data_manager.dart';
import 'package:wclient/models/receive_message_model.dart';

import 'package:wclient/ui/chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder 监听 DataManager
    return ListenableBuilder(
      listenable: DataManager(),
      builder: (context, child) {
        // 内部获取列表
        final chatList = DataManager().getSortedChatList();

        // 根据最新状态决定返回什么 UI
        if (chatList.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text("暂无消息", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final msg = chatList[index];
              final String wxid = msg.chatId;

              return _buildChatItem(msg, wxid);
            },
          ),
        );
      },
    );
  }

  Widget _buildChatItem(Message msg, String wxid) {
    // 翻译逻辑
    final String displayName = DataManager().getDisplayName(wxid);
    final String avatarUrl = DataManager().getAvatar(wxid);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey[200],
            ),
            child: avatarUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(avatarUrl, fit: BoxFit.cover),
            )
                : const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
          subtitle: Text(
            msg.content, // 显示最后一条消息的内容
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          trailing: Text(
            _formatTime(msg.msgtime), // 格式化时间
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(chatId: msg.chatId), // 传入点击项的 chatId
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(left: 76),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
      ],
    );
  }

  // 简单处理时间显示逻辑
  String _formatTime(String msgtime) {
    if (msgtime.length >= 16) {
      return msgtime.substring(11, 16); // 只取 HH:mm
    }
    return msgtime;
  }
}