import 'package:flutter/material.dart';
import 'package:wclient/managers/data_manager.dart';
import 'package:wclient/models/profile_message_model.dart';
import 'package:wclient/managers/connection_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    // 初始化时回显当前的服务器 URL
    _urlController = TextEditingController(text: ConnectionManager().currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleSwitchServer() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("地址不能为空")));
      return;
    }

    FocusScope.of(context).unfocus(); // 收起键盘
    ConnectionManager().changeServer(newUrl); // 触发全局切换逻辑

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("正在切换至 $newUrl")));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DataManager(),
      builder: (context, child) {
        final user = DataManager().selfProfile;

        return Scaffold(
          backgroundColor: const Color(0xFFEDEDED),
          // 加入 SingleChildScrollView 防止弹出键盘时 UI 溢出
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(user),
                const SizedBox(height: 12),
                _buildServerConfig(), // 渲染服务器配置卡片
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProfileInfoResponse? user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 24, right: 24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: user?.avatar != null && user!.avatar.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(user.avatar, fit: BoxFit.cover),
            )
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? "未登录",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  "微信号: ${user?.alias ?? user?.wxid ?? '未知'}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildServerConfig() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("服务器设置", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: "wss://...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF07C160)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _handleSwitchServer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text("切换网络", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}