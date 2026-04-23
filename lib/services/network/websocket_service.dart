import 'dart:async';
import 'dart:io';
import 'dart:convert';

// 证书配置
import 'package:wclient/config/security_config.dart';

/// WebSocket 连接状态
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketManager {
  // 单例模式
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  // 原生的 dart:io WebSocket 对象
  WebSocket? _socket;
  StreamSubscription? _subscription;

  // 状态流
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  // 消息流
  final _messageController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get messageStream => _messageController.stream;

  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  WebSocketStatus get currentStatus => _currentStatus;

  /// 连接服务器
  Future<void> connect(String url) async {
    // 避免重复连接
    if (_currentStatus == WebSocketStatus.connecting || _currentStatus == WebSocketStatus.connected) return;

    _updateStatus(WebSocketStatus.connecting);

    try {
      // 构建双向验证的安全上下文 (信任自定义 CA 时，withTrustedRoots 可以保持 true 或 false)
      SecurityContext securityContext = SecurityContext(withTrustedRoots: true);

      // 信任自签名的 CA 根证书
      final caBytes = utf8.encode(SecurityConfig.caCert);
      securityContext.setTrustedCertificatesBytes(caBytes);

      // 加载客户端公钥证书
      final clientCertBytes = utf8.encode(SecurityConfig.clientCert);
      securityContext.useCertificateChainBytes(clientCertBytes);

      // 加载客户端私钥
      final clientKeyBytes = utf8.encode(SecurityConfig.clientKey);
      securityContext.usePrivateKeyBytes(clientKeyBytes);

      // 创建受该安全上下文保护的 HttpClient
      HttpClient client = HttpClient(context: securityContext);

      // 强行放行域名校验（防止你用 IP 地址直连时，与证书里签发的域名/IP不匹配导致的报错）
      // 生产环境如果证书域名严丝合缝，建议移除此行以保证绝对安全
      // client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      // 3. 发起原生的 WebSocket 握手
      // 如果前面证书配置有一点不对，这里就会直接抛异常进入 catch
      _socket = await WebSocket.connect(url, customClient: client);

      // TCP 和 TLS 握手彻底完成，连接成功
      print("WSS 双向验证握手成功，已连接至: $url");
      _updateStatus(WebSocketStatus.connected);

      // 4. 监听原生 socket 流
      _subscription = _socket!.listen(
            (data) => _messageController.add(data),
        onDone: () => _updateStatus(WebSocketStatus.disconnected),
        onError: (e) {
          print("WebSocket 内部流异常断开: $e");
          _updateStatus(WebSocketStatus.error);
        },
        cancelOnError: true, // 出错即刻掐断流，交由外部的自动重连机制接管
      );

    } catch (e) {
      print("WSS 证书配置或网络握手异常: $e");
      _updateStatus(WebSocketStatus.error);
    }
  }

  /// 发送消息
  void sendMessage(dynamic message) {
    if (_socket != null && _currentStatus == WebSocketStatus.connected) {
      // 原生 socket 发送数据极其直接
      _socket!.add(message);
    }
  }

  /// 断开连接
  void disconnect() {
    _subscription?.cancel();
    _socket?.close();
    _socket = null;
    _updateStatus(WebSocketStatus.disconnected);
  }

  /// 更新内部状态
  void _updateStatus(WebSocketStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// 销毁资源
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}