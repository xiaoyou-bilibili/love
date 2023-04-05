import 'dart:convert';

import 'package:bruno/bruno.dart';
import 'package:bubble_bottom_bar/bubble_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/pages/fragment_album.dart';
import 'package:love/pages/fragment_home.dart';
import 'package:love/pages/fragment_me.dart';
import 'package:love/pages/fragment_notebook.dart';
import 'package:love/pages/fragment_task.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 安全启动 --no-sound-null-safety
void main() {
  // SharedPreferences.setMockInitialValues({"sex": 1});
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '贴贴日常',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      // 国际化支持
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        BrnLocalizationDelegate.delegate,
      ],
      // 新增
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: const MyHomePage(title: '贴贴日常'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _key = GlobalKey();
  int _index = 0;
  late PageFragment fragment;

  // 首页切换界面
  void _changePage(int index) {
    setState(() {
      _index = index;
    });
  }

  // 进入页面首先判断一下用户是否设置性别
  @override
  void initState() {
    ApiService.getAppSetting().then((value) => {
          debugPrint("应用设置 ${jsonEncode(value)}"),
          Storage.setAppSetting(value)
        });
    Storage.getSex().then((value) => {
          debugPrint("用户性别 $value"),
          if (value == 0)
            {
              BrnDialogManager.showMoreButtonDialog(context,
                  title: "设置性别",
                  actions: ['男', '女'],
                  barrierDismissible: false,
                  message: "检测到你第一次使用，请设置性别",
                  indexedActionClickCallback: (index) => {
                        Storage.setSex(index + 1),
                        Navigator.of(context).pop(true) //关闭对话框
                      })
            }
        });
    super.initState();
  }

  // 点击添加按钮的回调
  void _addCallback() {
    fragment.addCallback();
  }

  @override
  Widget build(BuildContext context) {
    // 根据下面的tab选择显示不同的页面
    switch (_index) {
      case 0:
        fragment = HomeFragment(_key);
        break;
      case 1:
        fragment = TaskFragment(_key);
        break;
      case 2:
        fragment = AlbumFragment(_key);
        break;
      case 3:
        fragment = NotebookFragment(_key);
        break;
      case 4:
        fragment = const MeFragment();
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: fragment as StatefulWidget,
      // 浮动按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _addCallback,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
      ),
      // 浮动按钮方向
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      // 底部导航栏
      bottomNavigationBar: BubbleBottomBar(
        opacity: .2,
        currentIndex: _index,
        onTap: _changePage,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        elevation: 8,
        fabLocation: BubbleBottomBarFabLocation.end, //new
        hasNotch: true, //new
        hasInk: true, // new, gives a cute ink effect
        inkColor: Colors.black12, //optional, uses theme color if not specified
        items: const <BubbleBottomBarItem>[
          BubbleBottomBarItem(
              backgroundColor: Colors.red,
              icon: Icon(
                Icons.home,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.home,
                color: Colors.red,
              ),
              title: Text("主页")),
          BubbleBottomBarItem(
              backgroundColor: Colors.deepPurple,
              icon: Icon(
                Icons.check_box,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.check_box,
                color: Colors.deepPurple,
              ),
              title: Text("计划")),
          BubbleBottomBarItem(
              backgroundColor: Colors.indigo,
              icon: Icon(
                Icons.photo,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.photo,
                color: Colors.indigo,
              ),
              title: Text("动态")),
          BubbleBottomBarItem(
              backgroundColor: Colors.green,
              icon: Icon(
                Icons.edit_document,
                color: Colors.black,
              ),
              activeIcon: Icon(
                Icons.edit_document,
                color: Colors.green,
              ),
              title: Text("笔记")),
          // BubbleBottomBarItem(
          //     backgroundColor: Colors.green,
          //     icon: Icon(Icons.people, color: Colors.black,),
          //     activeIcon: Icon(Icons.people, color: Colors.green,),
          //     title: Text("个人")
          // )
        ],
      ),
    );
  }
}
