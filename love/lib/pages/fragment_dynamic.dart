import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:love/component/item_dynamic.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/utils/http.dart' show host;
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';

class DynamicFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const DynamicFragment(this._key) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _DynamicFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _DynamicFragmentState).addDynamic();
  }
}

class _DynamicFragmentState extends State<DynamicFragment> {
  final List<String> _images = [];
  String _content = "";

  void addDynamic() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Widget> children = [];
        for (int i = 0; i < _images.length; i++) {
          children.add(Image.network("$host/${_images[i]}"));
        }
        children.add(InkWell(
          onTap: () {
            uploadImages(callback: (int current, int total) {
              BrnLoadingDialog.dismiss(context);
              BrnLoadingDialog.show(context,
                  content: "$current-$total", barrierDismissible: false);
            }).then((urls) {
              _images.addAll(urls);
              (context as Element).markNeedsBuild();
            }).whenComplete(() => BrnLoadingDialog.dismiss(context));
          },
          child: const Icon(Icons.cloud_upload, color: Colors.black, size: 80),
        ));
        return AlertDialog(
          contentPadding: const EdgeInsets.all(5),
          title: getPrimaryText("新增动态"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: BrnInputText(
                  hint: "随便写点什么吧~",
                  maxLength: 500,
                  textString: _content,
                  onTextChange: (value) {
                    _content = value;
                  },
                ),
              ),
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
            ],
          ),
          actions: <Widget>[
            //关闭对话框
            TextButton(
              child: const Text("取消", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("确定"),
              onPressed: () {
                Navigator.of(context).pop(true); //关闭对话框
                DynamicInfo info = DynamicInfo(
                  content: _content,
                  images: _images,
                  timestamp: getUnixNow(),
                  sex: Storage.getSexSync(),
                );
                // 构建请求
                var resp = ApiService.addDynamic(info);
                requestProcess(context, resp, () => setState(() {}));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimationLimiter(
        child: FutureBuilder(
          future: ApiService.getDynamicList(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<DynamicComment> data = snapshot.data;
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
        ),
      ),
    );
  }
}
