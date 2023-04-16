import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:love/component/item_notebook.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/pages/page_edit.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';

class NotebookFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const NotebookFragment(this._key) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _NotebookFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _NotebookFragmentState).addNote();
  }
}

class _NotebookFragmentState extends State<NotebookFragment>
    with TickerProviderStateMixin {
  // 所有的标签
  List<String> _tags = [""];
  // 当前选中的标签
  String _tag = "";
  // 下标index
  int _index = 0;

  // 跳转到添加文章的页面
  void addNote() {
    Navigator.push(context,
            MaterialPageRoute(builder: (context) => const PageEdit('')))
        .then((value) => setState(() {}));
  }

  @override
  void initState() {
    // 页面初始化获取一下所有的tag
    ApiService.getNoteTagList().then((tags) => {
          tags.isNotEmpty
              ? setState(() {
                  _tags = tags;
                  _tag = tags.first;
                })
              : null,
        });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 顶部标签
    var tabs = <BadgeTab>[];
    for (String tab in _tags) {
      tabs.add(BadgeTab(text: tab));
    }
    TabController controller =
        TabController(length: tabs.length, vsync: this, initialIndex: _index);
    return Column(children: [
      BrnTabBar(
        padding: const EdgeInsets.all(0),
        tabs: tabs,
        controller: controller,
        onTap: (state, index) {
          setState(() {
            _index = index;
            _tag = _tags[index];
          });
        },
      ),
      Expanded(
        child: AnimationLimiter(
            child: FutureBuilder(
          future: ApiService.getNoteList(_tag),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              List<NoteInfo> data = snapshot.data;
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                          child: InkWell(
                        onTap: () {
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PageEdit(data[index].id)))
                              .then((value) => setState(() {}));
                        },
                        child: ComponentItemNoteBook(data[index]),
                      )),
                    ),
                  );
                },
              );
            }
            return const BrnPageLoading();
          },
        )),
      )
    ]);
  }
}
