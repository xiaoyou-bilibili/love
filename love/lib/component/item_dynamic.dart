// 朋友圈动态组件
import 'dart:html';

import 'package:bruno/bruno.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love/component/component_avatar.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/http.dart' show host;
import 'package:love/utils/storage.dart';

class ComponentItemDynamic extends StatelessWidget {
  final DynamicComment info;
  ComponentItemDynamic(this.info, {super.key});

  late BuildContext _context;

  // 打开图片
  void _openImage() {
    List<String> urls = [];
    for (var images in info.dynamicInfo.images) {
      urls.add("$host/$images");
    }
    //通过url快速生成配置
    List<BrnPhotoGroupConfig> allConfig = [
      BrnPhotoGroupConfig.url(title: '图片', urls: urls)
    ];
    Navigator.push(_context, MaterialPageRoute(
      builder: (BuildContext context) {
        return BrnGalleryDetailPage(
          allConfig: allConfig,
          initGroupId: 0,
          initIndexId: 4,
        );
      },
    ));
  }

  // 打开评论
  void _openComment(String id) {
    BrnMiddleInputDialog(
        title: "评论内容",
        hintText: '输入评论内容',
        onConfirm: (value) {
          ApiService.addComment(CommentInfo(
                  relationId: id,
                  content: value,
                  timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  sex: Storage.getSexSync()))
              .then((value) {
            BrnToast.show("评论成功~刷新后生效", _context);
            Navigator.pop(_context);
          }).onError((error, stackTrace) {
            BrnToast.show(error.toString(), _context);
          });
        },
        onCancel: () => Navigator.pop(_context)).show(_context);
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    DateTime timestamp =
        DateTime.fromMillisecondsSinceEpoch(info.dynamicInfo.timestamp * 1000);
    // 组装图片列表，这里替换为压缩后的图片
    List<CachedNetworkImage> images = [];
    for (var image in info.dynamicInfo.images) {
      String cache = image.replaceAll("static/", "static/compose/");
      images.add(CachedNetworkImage(
        imageUrl: "$host/$cache",
        fit: BoxFit.fitHeight, // 设置图片为正方形
        placeholder: (context, url) => const Center(
            child: SizedBox(
                width: 50, height: 50, child: CircularProgressIndicator())),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ));
    }
    // 拼装评论列表
    List<Widget> comments = [];
    for (var comment in info.comments) {
      comments.add(Row(children: [
        Text(comment.sex == 1 ? "小老弟：" : "小老妹：",
            style: const TextStyle(color: Colors.blue, fontSize: 13)),
        Text(comment.content, style: const TextStyle(fontSize: 13)),
      ]));
    }
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ComponentAvatar(info.dynamicInfo.sex),
          const SizedBox(width: 10),
          Text(DateTimeFormatter.formatDate(timestamp, 'yyyy年MM月dd日'),
              style: const TextStyle(fontSize: 20)),
          Flexible(child: Container()),
          InkWell(
              child: const Icon(Icons.comment, color: Colors.grey, size: 20),
              onTap: () => _openComment(info.dynamicInfo.id)), // 点击评论
        ]),
        const SizedBox(height: 10),
        Text(info.dynamicInfo.content),
        const SizedBox(height: 10),
        InkWell(
            onTap: _openImage,
            child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: images)),
        Visibility(
            visible: comments.isNotEmpty,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(5),
              width: double.maxFinite,
              color: const Color.fromRGBO(248, 248, 248, 1),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: comments),
            ))
      ]),
      // 评论区
    );
  }
}
