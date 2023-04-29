import 'dart:convert';

import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/pages/fragment_dynamic.dart';
import 'package:love/pages/fragment_calendar.dart';
import 'package:love/pages/fragment_home.dart';
import 'package:love/pages/fragment_more.dart';
import 'package:love/pages/fragment_notebook.dart';
import 'package:love/pages/fragment_task.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';

const appName = "贴贴日常";

// 安全启动 --no-sound-null-safety
void main() {
  BrnInitializer.register(
    allThemeConfig: BrnAllThemeConfig(
      commonConfig: BrnCommonConfig(brandPrimary: Storage.getPrimaryColor()),
    ),
  );
  // SharedPreferences.setMockInitialValues({"sex": 1});
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appName,
      theme: ThemeData(
        primarySwatch: createMaterialColor(Storage.getPrimaryColor()),
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
        Locale('zh', 'CN'),
      ],
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _key = GlobalKey();
  int _index = 0;
  int _currentIndex = 0; // 当前底部导航栏下标
  final List<String> _titles = [appName, "日程", "动态", "功能", "计划", "笔记"];
  String _title = appName;
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
              BrnDialogManager.showMoreButtonDialog(
                context,
                title: "设置性别",
                actions: ['男', '女'],
                barrierDismissible: false,
                message: "检测到你第一次使用，请设置性别",
                indexedActionClickCallback: (index) => {
                  Storage.setSex(index + 1),
                  Navigator.of(context).pop(true) //关闭对话框
                },
              )
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
    _currentIndex = 3;
    _title = _titles[_index];
    // 根据下面的tab选择显示不同的页面
    switch (_index) {
      case 0:
        fragment = HomeFragment(_key);
        _currentIndex = _index;
        break;
      case 1:
        fragment = CalendarFragment(_key);
        _currentIndex = _index;
        break;
      case 2:
        fragment = DynamicFragment(_key);
        _currentIndex = _index;
        break;
      case 3:
        fragment = MoreFragment(_key, _changePage);
        break;
      case 4:
        fragment = TaskFragment(_key);
        break;
      case 5:
        fragment = NotebookFragment(_key);
        break;
    }
    return Scaffold(
      appBar: BrnAppBar(
        backgroundColor: Storage.getPrimaryColor(),
        leading: Visibility(
          visible: _index > 3,
          child: BrnIconAction(
            child: const Icon(Icons.arrow_back, color: Colors.white),
            iconPressed: () => _changePage(3),
          ),
        ),
        title: Text(
          _title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: BrnIconAction(
          iconPressed: _addCallback,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: fragment as StatefulWidget,
      // 底部导航栏
      bottomNavigationBar: BrnBottomTabBar(
        fixedColor: Storage.getPrimaryColor(),
        currentIndex: _currentIndex,
        onTap: _changePage,
        items: const <BrnBottomTabBarItem>[
          BrnBottomTabBarItem(
            icon: Icon(Icons.home),
            title: Text("主页"),
          ),
          BrnBottomTabBarItem(
            icon: Icon(Icons.date_range_sharp),
            title: Text("日程"),
          ),
          BrnBottomTabBarItem(
            icon: Icon(Icons.photo),
            title: Text("动态"),
          ),
          BrnBottomTabBarItem(
            icon: Icon(Icons.dashboard_customize),
            title: Text("功能"),
          ),
        ],
      ),
    );
  }
}
