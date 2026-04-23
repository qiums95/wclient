import 'package:flutter/material.dart';
import 'package:wclient/managers/data_manager.dart';
import 'package:wclient/models/chatroom_message_model.dart';

import 'package:wclient/ui/chat_page.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DataManager(),
      builder: (context, child) {
        // 每次监听到变化重新获取最新的联系人列表
        final List<ChatroomData> contacts = DataManager().contactCache.values.toList();

        // 字母排序
        contacts.sort((a, b) => a.nickname.compareTo(b.nickname));

        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView.builder(
            // 列表长度 = 顶部4个固定项 + 联系人列表 + 底部统计
            itemCount: contacts.length + 5,
            itemBuilder: (context, index) {
              // 渲染顶部的 4 个固定功能项
              if (index == 0) return _buildHeaderItem(Icons.person_add, "新的朋友", Colors.orange);
              if (index == 1) return _buildHeaderItem(Icons.groups, "群聊", Colors.green);
              if (index == 2) return _buildHeaderItem(Icons.local_offer, "标签", Colors.blue);
              if (index == 3) return _buildHeaderItem(Icons.person, "公众号", Colors.blueAccent);

              // 渲染联系人
              if (index < contacts.length + 4) {
                return _buildContactItem(context, contacts[index - 4]);
              }

              // 渲染底部的联系人总数统计
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: Text(
                  "${contacts.length} 位联系人",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 构建顶部固定功能项
  Widget _buildHeaderItem(IconData icon, String title, Color color) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          onTap: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(left: 68),
          child: Divider(height: 0.5, color: Color(0xFFE5E5E5)),
        ),
      ],
    );
  }

  // 构建真实的联系人列表项
  Widget _buildContactItem(BuildContext context, ChatroomData contact) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
            ),
            child: contact.avatar.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(contact.avatar, fit: BoxFit.cover),
            )
                : const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(contact.nickname, style: const TextStyle(fontSize: 16)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(chatId: contact.wxid),
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(left: 68),
          child: Divider(height: 0.5, color: Color(0xFFE5E5E5)),
        ),
      ],
    );
  }
}