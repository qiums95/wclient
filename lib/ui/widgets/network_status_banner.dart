import 'package:flutter/material.dart';
import 'package:wclient/services/network/websocket_service.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WebSocketStatus>(
      // 监听 WebSocketManager 的状态流
      stream: WebSocketManager().statusStream,
      // 传入初始状态，防止刚渲染时闪烁
      initialData: WebSocketManager().currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;

        // 如果已经连接成功，返回一个高度为 0 的空组件（隐藏横幅）
        if (status == WebSocketStatus.connected) {
          return const SizedBox.shrink();
        }

        // 根据不同状态决定文案和颜色
        String text = "网络连接不可用，正在尝试重连...";
        Color bgColor = const Color(0xFFFEEBEC); // 浅红色背景
        Color textColor = const Color(0xFFE64340); // 红色文字
        IconData icon = Icons.error_outline;

        if (status == WebSocketStatus.connecting) {
          text = "连接中...";
          bgColor = const Color(0xFFE8F4FD); // 浅蓝色背景
          textColor = const Color(0xFF1B82D2); // 蓝色文字
          icon = Icons.sync;
        }

        return Container(
          width: double.infinity,
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(color: textColor, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}