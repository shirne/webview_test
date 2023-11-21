import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'utils/utils.dart';
import '../../utils/html.dart' if (library.html) 'dart:ui' as ui;
import '../../utils/html.dart' if (library.html) 'dart:html' as htmllib;

int webviewId = 0;

/// 加载web页(url = 链接, show_app_bar = 是否显示appbar)
class WebViewPage extends StatefulWidget {
  WebViewPage(Json? config, {super.key})
      : url = config?['url'] ?? '',
        showAppBar = as<bool>(config?['show_app_bar']) ?? true;

  final String url;
  final bool showAppBar;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  WebViewController? controller;
  final title = ValueNotifier<String>('...');
  final progress = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() {
    if (kIsWeb) return;
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    controller = WebViewController.fromPlatformCreationParams(params);
// ···
    if (controller!.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(!kReleaseMode);
      (controller!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    controller!.platform.setOnPlatformPermissionRequest((request) async {
      bool granted = true;
      logger.info('request permission for ${request.types} ');
      if (request.types.contains(WebViewPermissionResourceType.camera)) {
        if (!await Permission.camera.status.isGranted) {
          await Permission.camera.request();
        }
        granted &= await Permission.camera.status.isGranted;
      }
      if (request.types.contains(WebViewPermissionResourceType.microphone)) {
        if (!await Permission.microphone.status.isGranted) {
          await Permission.microphone.request();
        }
        granted &= await Permission.microphone.status.isGranted;
      }
      if (granted) {
        request.grant();
      } else {
        request.deny();
      }
    });
    controller!
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int p) async {
            progress.value = p;
            if (title.value.isEmpty) {
              final t = await controller!.getTitle();
              if (t != null) {
                title.value = t;
              }
            }
          },
          onPageStarted: (String url) {
            title.value = '';
          },
          onPageFinished: (String url) async {
            title.value = (await controller!.getTitle()) ?? '';
          },
          onWebResourceError: (WebResourceError error) {},
          // onNavigationRequest: (NavigationRequest request) {
          // },
        ),
      )
      ..setOnConsoleMessage((message) {
        logger.info(message.message);
      })
      ..loadRequest(Uri.parse(widget.url));
  }

  Widget _buildWebview() {
    if (kIsWeb) {
      int pid = webviewId++;
      //ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory('popup-html-$pid',
          (int viewId) {
        final iframe = htmllib.IFrameElement();
        iframe.style
          ..border = 'none'
          ..width = '100%'
          ..height = '100%';
        iframe.src = widget.url;
        return iframe;
      });
      return HtmlElementView(viewType: 'popup-html-$pid');
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return WebViewWidget(
        controller: controller!,
      );
    }
    return Center(
      child: Text('Unsupported webview: ${widget.url}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: ValueListenableBuilder<String>(
                valueListenable: title,
                builder: (context, value, child) {
                  return Text(value);
                },
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: SizedBox(
                  height: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: progress,
                    builder: (context, value, child) {
                      if (value > 0 && value < 100) {
                        return OverflowBox(
                          maxHeight: 2,
                          child: LinearProgressIndicator(
                            value: value.toDouble(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    controller?.reload();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )
          : null,
      body: _buildWebview(),
    );
  }
}
