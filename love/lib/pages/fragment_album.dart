import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:love/component/item_dynamic.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/utils/http.dart' show host;
import 'package:love/utils/storage.dart';

class AlbumFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const AlbumFragment(this._key): super(key: _key);

  @override
  State<StatefulWidget> createState() => _AlbumFragmentFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _AlbumFragmentFragmentState).addDynamic();
  }
}


class _AlbumFragmentFragmentState extends State<AlbumFragment> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _images = [];
  String _content = "";

  void addDynamic() {

    // 显示一个弹窗
    showDialog(context: context, builder: (BuildContext context) {
      List<Widget> children = [];
      for(int i = 0; i < _images.length; i++) {
        children.add(Image.network("$host/${_images[i]}"));
      }
      children.add(InkWell(
        onTap: () {
          _picker.pickImage(source: ImageSource.gallery).then((image) => {
            if(image != null) {
              ApiService.uploadFile(image).then((value) => {
                _images.add(value),
                (context as Element).markNeedsBuild(),
              })
            }
          });
        },
        child: const Icon(Icons.cloud_upload, color: Colors.black, size: 80),
      ));
      return AlertDialog(
        contentPadding: const EdgeInsets.all(5),
        title: const Text("新增动态"),
        content: SizedBox(height: 300, child: Column(children: [
          Container(padding: const EdgeInsets.all(10), child: BrnInputText(
            hint: "随便写点什么吧~",
            maxLength: 500,
            textString: _content,
            onTextChange: (value) {_content = value;},
          )),
          SizedBox(
            width: double.maxFinite,
            height: 200,
            child: GridView.extent(
                padding: const EdgeInsets.all(5),
                maxCrossAxisExtent: 100,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                children: children,
            ),
          )
        ])),
        actions: <Widget>[
          //关闭对话框
          TextButton(child: const Text("取消"), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: const Text("确定", style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.of(context).pop(true); //关闭对话框
              DynamicInfo info = DynamicInfo(
                content: _content,
                images: _images,
                timestamp: DateTime.now().millisecondsSinceEpoch~/1000,
                sex: Storage.getSexSync(),
              );
              // 构建请求
              ApiService.addDynamic(info).
              then((value) => {
                BrnToast.show("添加成功", context),
                setState(() {})
              }).
              onError((error, stackTrace) => {
                BrnToast.show("错误 $error", context)
              });
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimationLimiter(
        child: FutureBuilder(
          future: ApiService.getDynamicList(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if(snapshot.connectionState == ConnectionState.done) {
              List<DynamicInfo> data = snapshot.data;
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: ComponentItemDynamic(data[index]),
                      ),
                    ),
                  );
                },
              );
            }
            return const BrnPageLoading();
          },
        )
      ),
    );  }
}