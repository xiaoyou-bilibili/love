import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/storage.dart';

// color转换为Material color
MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds * 2).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds * 2).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds * 2).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

// 设置一个带主题颜色的文本标签
Widget getPrimaryText(String text) {
  return Text("添加倒计时", style: TextStyle(color: Storage.getPrimaryColor()));
}

// 自定义弹窗
void showCustomDialog({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(2),
        title: getPrimaryText(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            onPressed: () => {
              Navigator.of(context).pop(true),
              onConfirm(),
            },
            child: const Text("确定"),
          ),
        ],
      );
    },
  );
}

// 异步函数处理
void requestProcess<T>(
  BuildContext context,
  Future<T> resp,
  VoidCallback onSuccess,
) {
  resp
      .then((value) => {BrnToast.show("操作成功！", context), onSuccess()})
      .onError((error, stackTrace) => {BrnToast.show("错误 $error", context)});
}

// 时间格式化
String formatDate(DateTime date) {
  return date.toString().split(" ")[0];
}

// 时间戳转换
int getUnix(DateTime date) {
  return date.millisecondsSinceEpoch ~/ 1000;
}
