import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'fragment.dart';

class MoreFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;
  final Function callback;

  const MoreFragment(this._key, this.callback) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _MoreFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _MoreFragmentState).addCallback();
  }
}

class _MoreFragmentState extends State<MoreFragment> {

  void addCallback() {
    BrnToast.show("小老弟正在加紧开发中！", context);
  }

  // 渲染菜单
  Widget _renderMenu(
    IconData icon,
    String title,
    Color color,
    VoidCallback callback,
  ) {
    return InkWell(
      onTap: callback,
      child: Material(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 30),
              Text(title, style: TextStyle(color: color, fontSize: 20))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        _renderMenu(
          Icons.check_box_outlined,
          "计划",
          Colors.blue,
          () => widget.callback(4),
        ),
        _renderMenu(
          Icons.edit_note_sharp,
          "笔记",
          Colors.green,
          () => widget.callback(5),
        ),
        _renderMenu(
          Icons.photo_album_outlined,
          "相册",
          Colors.pinkAccent,
          () => widget.callback(6),
        )
      ],
    );
  }
}
