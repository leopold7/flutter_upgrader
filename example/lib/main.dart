import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobile_upgrader/flutter_mobile_upgrader.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  TextEditingController apkDownloadUrlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Upgrader Plugin'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildInput(context),
              const SizedBox(height: 20),
              _buildNormal(context),
              const SizedBox(height: 20),
              _buildBackMode(context),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: apkDownloadUrlController,
                decoration: const InputDecoration(
                  hintText: '请输入apk下载地址',
                ),
                onChanged: (value) {
                  apkDownloadUrlController.text = value;
                },
              ))),
    ]);
  }

  Widget _buildNormal (BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButtonTheme.of(context).style,
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              '普通升级',
              style: TextStyle(fontSize: 18),
            ),
          ),
          onPressed: () {
            final Future<AppUpgradeInfo> appUpgradeInfo = Future.value(
              AppUpgradeInfo(
                  title: '更新提示',
                  contents: ['有新版本哟,请更新～'],
                  force: false,
                  apkDownloadUrl: apkDownloadUrlController.text),
            );

            if (Platform.isAndroid) {
              AppUpgradeManager.upgrade(
                context,
                appUpgradeInfo,
              );
            }

            if (Platform.isIOS) {
              AppUpgradeManager.upgrade(
                context,
                appUpgradeInfo,
                iosAppId: 'idxxxxxx',
              );
            }
          },
        )
      ],
    );
  }

  Widget _buildBackMode (BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButtonTheme.of(context).style,
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              '后台升级',
              style: TextStyle(fontSize: 18),
            ),
          ),
          onPressed: () {
            final Future<AppUpgradeInfo> appUpgradeInfo = Future.value(
              AppUpgradeInfo(
                  title: '更新提示',
                  contents: ['有新版本哟,请更新～'],
                  force: false,
                  apkDownloadUrl: apkDownloadUrlController.text),
            );

            if (Platform.isAndroid) {
              AppUpgradeManager.upgrade(
                context,
                appUpgradeInfo,
                isBackground: true,
                okText: '后台更新',
                onOk: () async {
                  debugPrint('开始后台更新');
                }
              );
            }

            if (Platform.isIOS) {
              AppUpgradeManager.upgrade(
                context,
                appUpgradeInfo,
                iosAppId: 'idxxxxxx',
              );
            }
          },
        )
      ],
    );
  }
}
