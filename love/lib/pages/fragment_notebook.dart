import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:love/component/item_notebook.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/pages/page_edit.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';


class NotebookFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const NotebookFragment(this._key): super(key: _key);

  @override
  State<StatefulWidget> createState() => _NotebookFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _NotebookFragmentState).addNote();
  }
}


class _NotebookFragmentState extends State<NotebookFragment> {

  // 跳转到添加文章的页面
  void addNote() {
    Navigator.
    push(context, MaterialPageRoute(builder: (context) => const PageEdit(''))).
    then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimationLimiter(
        child: FutureBuilder(
          future: ApiService.getNoteList(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if(snapshot.connectionState == ConnectionState.done) {
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
                            Navigator.
                            push(context, MaterialPageRoute(builder: (context) => PageEdit(data[index].id))).
                            then((value) => setState(() {}));
                          },
                          child: ComponentItemNoteBook(data[index]),
                        )
                      ),
                    ),
                  );
                },
              );
            }
            return const Text("加载中");
          },
        )
      ),
    );
  }
}