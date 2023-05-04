import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:love/component/item_album.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/pages/page_album_detail.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';

class AlbumFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const AlbumFragment(this._key) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _AlbumFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _AlbumFragmentState).addAlbum();
  }
}

class _AlbumFragmentState extends State<AlbumFragment> {
  // 新增相册
  void addAlbum() {
    BrnMiddleInputDialog(
      title: "相册名称",
      hintText: '请输入相册名称',
      onConfirm: (value) {
        var resp = ApiService.addAlbum(Album(
          title: value,
          timestamp: getUnixNow(),
          photos: [],
          sex: Storage.getSexSync(),
        ));
        requestProcess(context, resp, () => setState(() {}));
        Navigator.pop(context);
      },
      onCancel: () => Navigator.pop(context),
    ).show(context);
  }

  // 打开某个相册
  void _addAlbum(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PageAlbumDetail(id)),
    ).then((value) => setState(() {}));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: AnimationLimiter(
        child: FutureBuilder(
          future: ApiService.getAlbumList(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<AlbumInfo> data = snapshot.data;
              return GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: List.generate(
                  data.length,
                  (index) => InkWell(
                    child: ComponentItemAlbum(data[index]),
                    onTap: () => _addAlbum(data[index].id),
                  ),
                ),
              );
            }
            return const BrnPageLoading();
          },
        ),
      ),
    );
  }
}
