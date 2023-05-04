import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/utils.dart';

// 日程组件
class ComponentItemAlbum extends StatefulWidget {
  final AlbumInfo info;

  const ComponentItemAlbum(this.info, {super.key});

  @override
  State<ComponentItemAlbum> createState() => _ComponentItemAlbumState();
}

class _ComponentItemAlbumState extends State<ComponentItemAlbum> {
  late AlbumInfo info;

  @override
  Widget build(BuildContext context) {
    info = widget.info;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: getCompressImage(info.preview),
            height: 100,
            width: 100,
            errorWidget: (context, url, error) =>
                const Icon(Icons.photo_size_select_actual_outlined),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(info.title),
          const SizedBox(width: 2),
          Text(
            "(${info.count.toString()})",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ])
      ],
    );
  }
}
