// import 'dart:html' show AnchorElement, Blob, Url;
import 'dart:typed_data';
import 'package:bruno/bruno.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/http.dart' show host;
import 'package:love/utils/api.dart';
import 'package:love/utils/const.dart';
import 'package:universal_platform/universal_platform.dart';

final ImagePicker _picker = ImagePicker();

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
  return Text(text, style: TextStyle(color: Storage.getPrimaryColor()));
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

// 获取当前时间的unix时间戳
int getUnixNow() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}

// 时间戳转时间
DateTime unix2DateTime(int unix) {
  return DateTime.fromMillisecondsSinceEpoch(unix * 1000);
}

// 获取压缩图片地址
String getCompressImage(String url) {
  String cache = url.replaceAll("static/", "static/compose/");
  return "$host/$cache";
}

// 获取原图地址
String getOriginImage(String url) {
  return "$host/$url";
}

// 上传图片
Future<String> uploadImageAsync() async {
  XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    return ApiService.uploadFile(image);
  }
  return throw Exception("未选择图片！");
}

// 上传图片
void uploadImage({
  required BuildContext context,
  required StringCallback onSuccess,
}) {
  BrnLoadingDialog.show(context, content: "上传中", barrierDismissible: false);
  uploadImageAsync()
      .then((value) => {BrnToast.show("上传成功！", context), onSuccess(value)})
      .onError((error, stackTrace) => {BrnToast.show("上传失败 $error", context)})
      .whenComplete(() => BrnLoadingDialog.dismiss(context));
}

// 上传多张图片
Future<List<String>> uploadImages({required ProcessCallback callback}) async {
  List<XFile> images = await _picker.pickMultiImage();
  List<String> urls = [];
  if (images.isNotEmpty) {
    for (int i = 0; i < images.length; i++) {
      callback((((i + 1) / images.length) * 100).ceil());
      String url = await ApiService.uploadFile(images[i]);
      urls.add(url);
    }
    return urls;
  }
  return throw Exception("未选择图片！");
}

// 保存图片到本地
Future<void> saveImageAsync(String url) async {
  Response resp = await ApiService.client.downloadFile(url);
  final result = await ImageGallerySaver.saveImage(
    Uint8List.fromList(resp.data),
    quality: 100,
    name: "${getUnixNow()}",
  );
  if (!result["isSuccess"]) {
    throw Exception("保存失败");
  }
}

// 保存图片到本地
void saveImage(BuildContext context, String url) {
  BrnLoadingDialog.show(context, content: "下载中", barrierDismissible: false);
  Future<void> resp =
      UniversalPlatform.isWeb ? webDownloadImage(url) : saveImageAsync(url);
  resp
      .then((value) => BrnToast.show("保存成功！", context))
      .catchError((error) => BrnToast.show("保存失败 $error", context))
      .whenComplete(() => BrnLoadingDialog.dismiss(context));
}

Future<void> webDownloadImage(String url) async {
  // Response resp = await ApiService.client.downloadFile(url);
  // final bytes = resp.data;
  // var anchor = AnchorElement(href: Url.createObjectUrlFromBlob(Blob([bytes])));
  // anchor.download = 'image.png';
  // anchor.click();
  // Url.revokeObjectUrl(url);
}
