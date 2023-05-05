import 'package:bruno/bruno.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:love/pages/page_photo_view.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PageAlbumDetail extends StatefulWidget {
  // 相册id
  final String _id;

  const PageAlbumDetail(this._id, {super.key});

  @override
  State<StatefulWidget> createState() => _PageAlbumDetailState();
}

class _PageAlbumDetailState extends State<PageAlbumDetail> {
  Album _album = Album(title: "", photos: [], timestamp: 0, sex: 0);

  // 相册刷新
  void _refreshAlbum() {
    // 获取相册详情
    ApiService.getAlbumInfo(widget._id)
        .then((info) => setState(() => _album = info));
  }

  // 添加图片
  void _addImage() {
    uploadImage(
      context: context,
      onSuccess: (url) {
        var resp = ApiService.albumAddPhoto(
          widget._id,
          AlbumPhotoInfo(url: [url]),
        );
        requestProcess(context, resp, _refreshAlbum);
      },
    );
  }

  // 删除图片
  void _deleteImage(String url) {
    BrnDialogManager.showConfirmDialog(
      context,
      cancel: "取消",
      confirm: "确定",
      title: "确定删除？",
      onConfirm: () {
        var resp = ApiService.albumDelPhoto(
          widget._id,
          AlbumPhotoInfo(url: [url]),
        );
        Navigator.pop(context);
        Navigator.pop(context);
        requestProcess(context, resp, _refreshAlbum);
      },
      onCancel: () {
        Navigator.pop(context);
      },
    );
  }

  // 打开图片
  void _openImage(int index) {
    // 构建图片列表
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PagePhotoView(_album.photos, index, _deleteImage),
      ),
    );
  }

  @override
  void initState() {
    _refreshAlbum();
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
          _album.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: BrnIconAction(
          iconPressed: _addImage,
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: List.generate(
            _album.photos.length,
            (index) => InkWell(
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: getCompressImage(_album.photos[index]),
              ),
              onTap: () => _openImage(index),
            ),
          ),
        ),
      ),
    );
  }
}
