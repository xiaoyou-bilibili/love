import 'package:bruno/bruno.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PagePhotoView extends StatefulWidget {
  // 初始位
  final int _index;
  // 图片列表
  final List<String> _imgList;

  const PagePhotoView(this._imgList, this._index, {super.key});

  @override
  State<StatefulWidget> createState() => _PagePhotoViewState();
}

class _PagePhotoViewState extends State<PagePhotoView> {
  int _index = 0;
  List<PhotoViewGalleryPageOptions> _imgList = [];

  @override
  void initState() {
    _index = widget._index;
    for (var image in widget._imgList) {
      _imgList.add(PhotoViewGalleryPageOptions(
        imageProvider: CachedNetworkImageProvider(getOriginImage(image)),
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrnAppBar(
        backgroundColor: Storage.getPrimaryColor(),
        leading: BrnIconAction(
          child: const Icon(Icons.arrow_back, color: Colors.white),
          iconPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${_index + 1}/${_imgList.length}",
          style: const TextStyle(color: Colors.white),
        ),
        actions: BrnIconAction(
          iconPressed: () => saveImage(context, widget._imgList[_index]),
          child: const Icon(
            Icons.download_outlined,
            color: Colors.white,
          ),
        ),
      ),
      body: PhotoViewGallery(
        pageOptions: _imgList,
        pageController: PageController(initialPage: _index),
        onPageChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
