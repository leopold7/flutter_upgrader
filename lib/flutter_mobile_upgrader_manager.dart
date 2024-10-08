import 'package:flutter/material.dart';
import 'package:flutter_mobile_upgrader/flutter_mobile_upgrader.dart';
import 'package:flutter_mobile_upgrader/flutter_mobile_upgrader_view.dart';

class AppUpgradeManager {
  static upgrade(
    BuildContext context,
    Future<AppUpgradeInfo> future, {
    TextStyle? titleStyle,
    TextStyle? contentStyle,
    String? cancelText,
    TextStyle? cancelTextStyle,
    String? okText,
    TextStyle? okTextStyle,
    List<Color>? okBackgroundColors,
    Color? progressBarColor,
    double borderRadius = 20.0,
    String? iosAppId,
    AppMarketInfo? appMarketInfo,
    VoidCallback? onCancel,
    VoidCallback? onOk,
    DownloadProgressCallback? downloadProgress,
    DownloadStatusChangeCallback? downloadStatusChange,
    bool isBackground = false,
  }) {
    future.then((AppUpgradeInfo appUpgradeInfo) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            okBackgroundColors ??= [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor
            ];

            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(borderRadius),
                  ),
                ),
                child: SimpleUpgradeViewWidget(
                  title: appUpgradeInfo.title,
                  contents: appUpgradeInfo.contents,
                  titleStyle: titleStyle,
                  contentStyle: contentStyle,
                  progressBarColor: progressBarColor,
                  borderRadius: borderRadius,
                  downloadUrl: appUpgradeInfo.apkDownloadUrl,
                  force: appUpgradeInfo.force,
                  isBackground: isBackground,
                  iosAppId: iosAppId,
                  appMarketInfo: appMarketInfo,
                  downloadProgress: downloadProgress,
                  downloadStatusChange: downloadStatusChange,
                  okBackgroundColors: okBackgroundColors,
                  cancelTextStyle: cancelTextStyle,
                  okTextStyle: okTextStyle,
                  cancelText: cancelText,
                  onCancel: onCancel,
                  okText: okText,
                  onOk: onOk,
                ),
              ),
            );
          });
    }).catchError((error) {
      debugPrint('$error');
    });
  }
}

// AppInfo
class AppInfo {
  AppInfo({
    required this.versionName,
    required this.versionCode,
    required this.packageName,
  });

  final String versionName;
  final String versionCode;
  final String packageName;
}

// AppUpgradeInfo
class AppUpgradeInfo {
  AppUpgradeInfo({
    required this.title,
    required this.contents,
    this.apkDownloadUrl,
    this.force = false,
  });

  final String title;
  final List<String> contents;
  final String? apkDownloadUrl;
  final bool force;
}

// 下载进度回调
typedef DownloadProgressCallback = Function(
  int count,
  int total,
);

// 下载状态变化回调
typedef DownloadStatusChangeCallback = Function(
  DownloadStatus downloadStatus, {
  dynamic error,
});
