import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';

class PageEdit extends StatefulWidget {
  // 文章id
  final String _id;

  const PageEdit(this._id, {super.key});

  @override
  State<StatefulWidget> createState() => _PageEditState(_id);
}

class _PageEditState extends State<PageEdit> {
  final String _id;
  String _title = '';
  String _content = '';
  int _timestamp = 0;
  int _sex = 0;

  _PageEditState(this._id) {
    ApiService.getNote(_id).then((note) => {
      setState(() {
        _title = note.title;
        _content = note.content;
        _timestamp = note.timestamp;
        _sex = note.sex;
      })
    });
  }

  void _action_success(BuildContext context) {
    BrnToast.show("操作成功", context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    _controller.text = _content;
    _controller.addListener(() {
      _content = _controller.text;
    });
    return Scaffold(
      appBar: AppBar(title: Text(_id == '' ? '添加笔记' : '编辑笔记')),
      body: Column(
        children: [
          BrnTextInputFormItem(
            key: Key(_title),
            controller: TextEditingController(text: _title),
            title: "笔记标题",
            hint: "输入标题~",
            onChanged: (newValue) {_title = newValue;},
          ),
          // editable text with toolbar by default
         Expanded(child: MarkdownField(
           key: Key(_content),
           controller: _controller,
           emojiConvert: true,
           expands: true,
         )),
          BrnBottomButtonPanel(
            mainButtonName:_id == '' ? '保存' : '更新',
            mainButtonOnTap:() {
              NoteInfo info = NoteInfo(
                title: _title,
                content: _content,
                timestamp: DateTime.now().millisecondsSinceEpoch~/1000,
                sex: Storage.getSexSync(),
              );
              if(_id != '') {
                info.id = _id;
                print("更新内容 ${info.id} ${info.title} ${info.content}");
                ApiService.updateNote(info).then((value) => _action_success(context));
              } else {
                ApiService.addNoteInfo(info).then((value) => _action_success(context));
              }
            },
            secondaryButtonName:'取消',
            secondaryButtonOnTap: () { Navigator.pop(context); },
          )
        ],
      ),
    );
  }
}