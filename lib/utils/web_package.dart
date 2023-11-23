import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'html.dart';

export 'html.dart';

abstract class WebWebViewController extends PlatformWebViewController {
  factory WebWebViewController(PlatformWebViewControllerCreationParams params) {
    final webViewControllerDelegate = WebViewPlatform.instance!
        .createPlatformWebViewController(params) as WebWebViewController;

    return webViewControllerDelegate;
  }
  IFrameElement get iFrame;
}
