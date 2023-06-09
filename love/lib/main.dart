import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/pages/fragment_album.dart';
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
  final List<String> _titles = [appName, "日程", "动态", "功能", "计划", "笔记", "相册"];
  // 所有功能对应的新增按钮
  final List<IconData> _icons = [
    Icons.more_time_rounded,
    Icons.edit_calendar_outlined,
    Icons.add_photo_alternate_outlined,
    Icons.add,
    Icons.add_task,
    Icons.note_add_outlined,
    Icons.add_a_photo_outlined
  ];
  String _title = appName;
  String _secret = "";
  int _sex = 1;
  final _sexEnum = ["", "男", "女"];
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
    Storage.getSexAndSecret().then((value) {
      debugPrint("用户性别 $value");
      if (value == 0) {
        // 显示一个弹窗
        showCustomDialog(
          context: context,
          title: "登录",
          children: [
            BrnRadioInputFormItem(
              title: "性别",
              options: [_sexEnum[1], _sexEnum[2]],
              value: _sexEnum[1],
              onChanged: (oldValue, newValue) {
                _sex = _sexEnum.indexOf(newValue ?? "");
              },
            ),
            BrnTextInputFormItem(
              title: "密码",
              hint: "登录密码",
              onChanged: (newValue) => _secret = newValue,
            )
          ],
          onConfirm: () {
            Storage.setSex(_sex);
            Storage.setSecret(_secret);
            BrnToast.show("设置成功，刷新界面后生效", context);
          },
        );
      }
      // 获取应用设置
      ApiService.getAppSetting().then((value) {
        Storage.setAppSetting(value);
        // 刷新页面
        _changePage(0);
      });
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
      case 6:
        fragment = AlbumFragment(_key);
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
          child: Icon(_icons[_index], color: Colors.white),
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
            title: Text("更多"),
          ),
        ],
      ),
    );
  }
}
