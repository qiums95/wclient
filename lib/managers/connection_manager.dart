import 'dart:async';
import 'package:wclient/managers/data_manager.dart';
import 'package:wclient/services/network/websocket_service.dart';

class ConnectionManager {
  // 单例模式
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  String currentUrl = '';
  StreamSubscription<WebSocketStatus>? _statusSub;
  bool _isReconnecting = false;
  final int reconnectDelay = 3;

  /// 启动连接与监听
  void start([String? url]) {
    if (url != null) {
      currentUrl = url;
    }

    // 取消旧的监听，断开旧连接，防止内存泄漏和重复订阅
    _statusSub?.cancel();
    WebSocketManager().disconnect();

    // 发起新连接
    WebSocketManager().connect(currentUrl);

    // 监听状态并接管重连逻辑
    _statusSub = WebSocketManager().statusStream.listen((status) async {
      if (status == WebSocketStatus.connected) {
        print('WebSocket 连接成功');
        _loadData(); // 连接成功后拉取数据
        _isReconnecting = false;
      }
      else if (status == WebSocketStatus.disconnected || status == WebSocketStatus.error) {
        if (_isReconnecting) return;
        _isReconnecting = true;

        print('WebSocket 断开/异常，将在 $reconnectDelay 秒后尝试重连...');

        await Future.delayed(Duration(seconds: reconnectDelay));

        if (WebSocketManager().currentStatus != WebSocketStatus.connected) {
          print('正在尝试重新连接...');
          _isReconnecting = false;
          WebSocketManager().connect(currentUrl);
        }
      }
    });
  }

  /// 供 UI 层调用的切换服务器方法
  void changeServer(String newUrl) {
    if (newUrl.isEmpty || newUrl == currentUrl) return;
    print("开始切换服务器至: $newUrl");
    start(newUrl); // start 方法内部会自动处理旧连接的清理
  }

  /// 集中处理数据拉取
  void _loadData() {
    DataManager().loadProfile();
    DataManager().loadContacts();
    DataManager().syncMessagesFromServer();
  }
}