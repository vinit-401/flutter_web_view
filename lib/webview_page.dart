import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_demo/print_log.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final PlatformWebViewControllerCreationParams params;
  WebViewController? controller;
  double scrollPosition = 0;
  double scrollHeight = 1;
  @override
  void initState() {
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{PlaybackMediaTypes.audio, PlaybackMediaTypes.video},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    controller =
        WebViewController.fromPlatformCreationParams(params)
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse('https://www.google.com/'))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                printG("1. Page loading started..");
              },
              onPageFinished: (url) {
                printG("Page on finshed called");
              },
              onWebResourceError: (error) {
                printG(error.toString());
                printR(error.errorCode.toString());
                printR(error.description);
                printG("onwebresourceerror called");
              },
              onHttpAuthRequest: (request) {
                printG("on http auth called..");
              },
              onHttpError: (error) {
                printG("on http error called");
              },
              onProgress: (progress) {
                printG("request is in loading and progress state");
              },
              onUrlChange: (change) {
                printG("2. url was change");
              },
              onNavigationRequest: (request) {
                printG("navigation has change.. gone to another req...");
                return NavigationDecision.navigate;
              },
            ),
          )
          //external javascript added
          ..runJavaScript("""
        window.onscroll = function() {
          ScrollListener.postMessage(document.documentElement.scrollTop + ' / ' + document.documentElement.scrollHeight);
        };
        
      """)
          ..addJavaScriptChannel(
            "ScrollListener",
            onMessageReceived: (JavaScriptMessage message) {
              printG("adding the javascript channel for the scroll end");
              List<String> values = message.message.split(' / ');
              setState(() {
                scrollPosition = double.parse(values[0]);
                scrollHeight = double.parse(values[1]);
              });
            },
          )
          ..setOnJavaScriptAlertDialog(_handleJavaScriptAlertDialog)
          ..enableZoom(false)
          ..canGoForward()
          // background color does not work on macOs for opaque unimplemented error
          ..setBackgroundColor(Colors.red);

    /// android configuration....
    ///
    /// The following features have been moved to an Android implementation class. See section Platform-Specific Features for details on accessing Android platform-specific features.
    // WebView.debuggingEnabled -> static AndroidWebViewController.enableDebugging
    // WebView.initialMediaPlaybackPolicy -> AndroidWebViewController.setMediaPlaybackRequiresUserGesture
    printG("setting the android enable debugging..");
    if (Platform.isAndroid) {
      if (controller!.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller!.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
    }
    printG("setting the android enable debugging.... done...");
    super.initState();
  }

  Future<void> _handleJavaScriptAlertDialog(JavaScriptAlertDialogRequest request) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("JavaScript Alert"),
            content: Text(request.message), // Message from JavaScript alert()
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Close dialog
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(child: WebViewWidget(controller: controller!, key: Key("widgetKEy"))),
            Container(
              height: 100,
              color: Colors.grey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Platform.isAndroid) Text("Android: "),
                      if (Platform.isIOS) Text("iOS: "),
                      if (Platform.isMacOS) Text("MacOS: ") else Text("Device"),
                      Text(controller!.platform.toString()),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            printB("go backed pressed");
                            await controller!.goBack();
                          },
                          child: Text("Go Back"),
                        ),
                        TextButton(
                          onPressed: () async {
                            printB("REload");
                            await controller!.reload();
                          },
                          child: Text("REload"),
                        ),
                        TextButton(
                          onPressed: () async {
                            printB("go forward pressed");
                            await controller!.goForward();
                          },
                          child: Text("Go Forward"),
                        ),
                        TextButton(
                          onPressed: () async {
                            printB("Enable Zoom");
                            await controller!.enableZoom(true);
                          },
                          child: Text("Enable Zoom"),
                        ),
                        TextButton(
                          onPressed: () async {
                            printB("Disable Zoom");
                            await controller!.enableZoom(false);
                          },
                          child: Text("Disable Zoom"),
                        ),
                        TextButton(
                          onPressed: () async {
                            printB("Scroll to end using javascript channel ");
                            controller!.runJavaScript("window.scrollTo(0, document.documentElement.scrollHeight);");
                          },
                          child: Text("Scroll Down"),
                        ),
                        TextButton(
                          onPressed: () async {
                            printB("scroll to top ");
                            controller!.scrollTo(0, 0);
                          },
                          child: Text("Scroll up"),
                        ),
                        TextButton(
                          onPressed: () async {
                            // use your alert or dialog messge in the controller
                            printB("injected javascript");
                            controller!.runJavaScript('alert("Hello. World");');
                          },
                          child: Text("Injected JavaScript Alert"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
