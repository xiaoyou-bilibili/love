import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/utils.dart';

// 日程组件
class ComponentCacheImage extends StatefulWidget {
  final String url;

  const ComponentCacheImage(this.url, {super.key});

  @override
  State<ComponentCacheImage> createState() => _ComponentCacheImageState();
}

class _ComponentCacheImageState extends State<ComponentCacheImage> {
  int width = 500;
  int height = 500;

  @override
  void initState() {
    super.initState();
    // 获取图片宽高
    ApiService.getImageInfo(widget.url).then(
      (value) => setState(() {
        width = (value.width/5).ceil();
        height = (value.height/5).ceil();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fit: BoxFit.cover,
      memCacheWidth: width,
      memCacheHeight: height,
      imageUrl: getCompressImage(widget.url),
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}
