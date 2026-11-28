import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // <- ВОТ ЭТОТ ИМПОРТ БЫЛ ПРОПУЩЕН

class YandexAuthScreen extends StatefulWidget {
  final Function(String token) onTokenReceived;
  const YandexAuthScreen({super.key, required this.onTokenReceived});

  @override
  State<YandexAuthScreen> createState() => _YandexAuthScreenState();
}

class _YandexAuthScreenState extends State<YandexAuthScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url != null && url.contains('access_token=')) {
              final token = Uri.parse(url).fragment.split('access_token=')[1].split('&')[0];
              widget.onTokenReceived(token);
              Navigator.pop(context);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(
        'https://oauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd418abb4b39c32c41195d',
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в Яндекс')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
