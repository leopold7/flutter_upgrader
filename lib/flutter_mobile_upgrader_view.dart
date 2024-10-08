import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobile_upgrader/flutter_mobile_upgrader.dart';
import 'package:flutter_mobile_upgrader/flutter_mobile_upgrader_indicator.dart';

// 升级提示 View
class SimpleUpgradeViewWidget extends StatefulWidget {
  const SimpleUpgradeViewWidget({
    required this.title,
    required this.contents,
    Key? key,
    this.titleStyle,
    this.contentStyle,
    this.cancelText,
    this.cancelTextStyle,
    this.okText,
    this.okTextStyle,
    this.okBackgroundColors,
    this.progressBar,
    this.progressBarColor,
    this.borderRadius = 10,
    this.downloadUrl,
    this.force = false,
    this.isBackground = false,
    this.iosAppId,
    this.appMarketInfo,
    this.onCancel,
    this.onOk,
    this.downloadProgress,
    this.downloadStatusChange,
  }) : super(key: key);

  // 升级标题
  final String title;

  // 升级提示内容
  final List<String> contents;

  // 标题样式
  final TextStyle? titleStyle;

  // 提示内容样式
  final TextStyle? contentStyle;

  // 下载进度条
  final Widget? progressBar;

  // 进度条颜色
  final Color? progressBarColor;

  // 确认按钮文本
  final String? okText;

  // 确认按钮样式
  final TextStyle? okTextStyle;

  // 确认按钮背景颜色, 2种颜色左到右线性渐变
  final List<Color>? okBackgroundColors;

  // 取消按钮文本
  final String? cancelText;

  // 取消按钮样式
  final TextStyle? cancelTextStyle;

  // app安装包下载 url,没有下载跳转到应用宝等渠道更新
  final String? downloadUrl;

  // 圆角半径
  final double borderRadius;

  // 是否强制升级,设置true没有取消按钮
  final bool force;

  // 是否后台更新，设置true后，点击更新按钮弹窗消失
  final bool isBackground;

  // ios app id,用于跳转app store
  final String? iosAppId;

  // 指定跳转的应用市场，如果不指定将会弹出提示框，让用户选择哪一个应用市场。
  final AppMarketInfo? appMarketInfo;

  // 相关事件回调
  final VoidCallback? onOk;
  final VoidCallback? onCancel;
  final DownloadProgressCallback? downloadProgress;
  final DownloadStatusChangeCallback? downloadStatusChange;

  @override
  SimpleUpgradeViewWidgetState createState() => SimpleUpgradeViewWidgetState();
}

class SimpleUpgradeViewWidgetState extends State<SimpleUpgradeViewWidget> {
  DownloadStatus _downloadStatus = DownloadStatus.none;
  double _downloadProgress = 0.0;

  late BorderRadius borderRadius = BorderRadius.only(
    bottomLeft: widget.force ? Radius.circular(widget.borderRadius) : Radius.zero,
    bottomRight: Radius.circular(widget.borderRadius),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Stack(
        children: <Widget>[
          _buildInfoWidget(context),
          _downloadProgress > 0
              ? Positioned.fill(child: _buildDownloadProgress())
              : Container(height: 10)
        ],
      ),
    );
  }

  // 信息展示 widget
  Widget _buildInfoWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[_buildTitle(), _buildAppInfo(), _buildAction()],
    );
  }

  // 下载处理
  Future downloadApkHandler({required String url, required String path, bool isBackground = false}) async {
    if (_downloadStatus == DownloadStatus.downloading || _downloadStatus == DownloadStatus.start || _downloadStatus == DownloadStatus.done) {
      debugPrint('当前下载状态：$_downloadStatus, 不能重复下载。');
      return;
    }
    _downloadStatus = DownloadStatus.start;
    widget.downloadStatusChange?.call(_downloadStatus, error: null);

    if (isBackground) {
      // 启动后台下载
      await _startBackgroundDownload(url, path);
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      // 前台下载
      await _startDownload(url, path);
    }
  }

  Future<void> _startDownload(String url, String path) async {
    try {
      await Dio().download(url, path, onReceiveProgress: (int count, int total) {
        if (total == -1) {
          _downloadProgress = 0.01;
        } else {
          widget.downloadProgress?.call(count, total);
          _downloadProgress = count / total.toDouble();
        }

        setState(() {});

        if (_downloadProgress == 1) {
          _downloadStatus = DownloadStatus.done;
          widget.downloadStatusChange?.call(DownloadStatus.done);
          FlutterUpgradeChanneler.installAppForAndroid(path);
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _downloadProgress = 0;
      _downloadStatus = DownloadStatus.error;
      widget.downloadStatusChange?.call(DownloadStatus.error, error: e);
    }
  }

  Future<void> _startBackgroundDownload(String url, String path) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_backgroundDownload, [receivePort.sendPort, url, path]);
    receivePort.listen((message) {
      if (message is double) {
        if (mounted) {
          setState(() {
            _downloadProgress = message;
            debugPrint('下载进度：$_downloadProgress');
          });
        }
      } else if (message == 'done') {
        _downloadStatus = DownloadStatus.done;
        widget.downloadStatusChange?.call(DownloadStatus.done);
        FlutterUpgradeChanneler.installAppForAndroid(path);
      } else if (message is Exception) {
        _downloadStatus = DownloadStatus.error;
        widget.downloadStatusChange?.call(DownloadStatus.error, error: message);
      }
    });
  }

  static Future<void> _backgroundDownload(List<dynamic> args) async {
    final sendPort = args[0] as SendPort;
    final url = args[1] as String;
    final path = args[2] as String;

    try {
      await Dio().download(url, path, onReceiveProgress: (int count, int total) {
        if (total != -1) {
          final progress = count / total.toDouble();
          sendPort.send(progress);
        }
      });
      sendPort.send('done');
    } catch (e) {
      sendPort.send(e);
    }
  }

  // 构建标题
  _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 30,
      ),
      child: Text(
        widget.title,
        style: widget.titleStyle ?? const TextStyle(fontSize: 22),
      ),
    );
  }

  // 构建版本更新信息
  _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
      height: 200,
      child: ListView(
        children: widget.contents.map((text) {
          return Text(
            text,
            style: widget.contentStyle ?? const TextStyle(),
          );
        }).toList(),
      ),
    );
  }

  // 构建取消或者升级按钮
  _buildAction() {
    if (widget.force == true) {
      return Column(
        children: <Widget>[
          const Divider(
            height: 1,
            color: Colors.grey,
          ),
          Row(
            children: <Widget>[
              Container(),
              Expanded(child: _buildOkActionButton()),
            ],
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        const Divider(
          height: 1,
          color: Colors.grey,
        ),
        Row(
          children: <Widget>[
            Expanded(child: _buildCancelActionButton()),
            Expanded(child: _buildOkActionButton()),
          ],
        ),
      ],
    );
  }

  // 确定按钮
  _buildOkActionButton() {
    var okBackgroundColors = widget.okBackgroundColors?.length != 2
        ? [Theme.of(context).primaryColor, Theme.of(context).primaryColor]
        : widget.okBackgroundColors!;

    return Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [okBackgroundColors[0], okBackgroundColors[1]],
        ),
        borderRadius: borderRadius,
      ),
      child: InkWell(
        borderRadius: borderRadius,
        child: Container(
          height: 45,
          alignment: Alignment.center,
          child: Text(
            widget.okText ?? '立即体验',
            style: widget.okTextStyle ?? const TextStyle(color: Colors.white),
          ),
        ),
        onTap: () async {
          widget.onOk?.call();

          if (Platform.isIOS) {
            FlutterUpgradeChanneler.jumpAppStore(widget.iosAppId);
            Navigator.of(context).pop();
            return;
          }

          if (widget.downloadUrl == null || widget.downloadUrl!.isEmpty) {
            FlutterUpgradeChanneler.jumpMarket(widget.appMarketInfo);
            Navigator.of(context).pop();
            return;
          }

          String name = 'app_download.apk';
          String path = await FlutterUpgradeChanneler.apkDownloadPath;

          downloadApkHandler(url : widget.downloadUrl!, path: '$path/$name', isBackground: widget.isBackground);
        },
      ),
    );
  }

  // 取消按钮
  _buildCancelActionButton() {
    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(widget.borderRadius),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(widget.borderRadius),
        ),
        child: Container(
          height: 45,
          alignment: Alignment.center,
          child: Text(
            widget.cancelText ?? '以后再说',
            style: widget.cancelTextStyle ?? const TextStyle(),
          ),
        ),
        onTap: () {
          widget.onCancel?.call();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // 下载进度
  _buildDownloadProgress() {
    final primaryColor = Theme.of(context).primaryColor.withOpacity(0.4);
    final progressBarColor = widget.progressBarColor ?? primaryColor;

    return widget.progressBar ??
        LiquidProgressIndicator(
          value: _downloadProgress,
          direction: Axis.vertical,
          valueColor: AlwaysStoppedAnimation(progressBarColor),
          borderRadius: widget.borderRadius,
        );
  }
}
