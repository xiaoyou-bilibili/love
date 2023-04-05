import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:love/utils/http.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final ImagePicker _picker = ImagePicker();
  final String _id;
  String _title = '';
  String _content = '';
  int _timestamp = 0;
  int _sex = 0;
  bool _preview = false; // 预览模式

  _PageEditState(this._id) {
    if (_id != '') {
      ApiService.getNote(_id).then((note) => {
            setState(() {
              _preview = true;
              _title = note.title;
              _content = note.content;
              _timestamp = note.timestamp;
              _sex = note.sex;
            })
          });
    }
  }

  void _actionSuccess(BuildContext context) {
    BrnToast.show("操作成功", context);
    Navigator.pop(context);
  }

  // 点击保存或更新按钮的操作
  void _actionSaveOrUpdate() {
    NoteInfo info = NoteInfo(
      title: _title,
      content: _content,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      sex: Storage.getSexSync(),
    );
    if (_id != '') {
      info.id = _id;
      ApiService.updateNote(info).then((value) => _actionSuccess(context));
    } else {
      ApiService.addNoteInfo(info).then((value) => _actionSuccess(context));
    }
  }

  // 上传图片
  void _uploadImage() {
    _picker.pickImage(source: ImageSource.gallery).then((image) => {
          if (image != null)
            {
              ApiService.uploadFile(image).then((value) => {
                    setState(() {
                      _content = "$_content\n\n ![图片]($host/$value)";
                    }),
                    (context as Element).markNeedsBuild(),
                  })
            }
        });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _controller = TextEditingController();
    _controller.text = _content;
    // 添加一个监听器监听文本变化
    _controller.addListener(() {
      _content = _controller.text;
    });
    // markDown编辑器
    Widget _edit = MarkdownField(
      key: Key(_content),
      controller: _controller,
      emojiConvert: true,
      expands: true,
    );
    if (_preview) {
      // 预览模式设置各种触发事件
      _edit = MarkdownParse(
          data: _content,
          onTapLink: (String text, String? href, String title) =>
              href != null ? launchUrl(Uri.parse(href)) : "",
          imageBuilder: (Uri uri, String? title, String? alt) =>
              CachedNetworkImage(imageUrl: uri.toString()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_id == '' ? '添加笔记' : '编辑笔记')),
      body: Column(
        children: [
          BrnTextInputFormItem(
            key: Key(_title),
            controller: TextEditingController(text: _title),
            title: "笔记标题",
            hint: "输入标题~",
            onChanged: (newValue) {
              _title = newValue;
            },
          ),
          // editable text with toolbar by default
          Expanded(child: _edit),
          BrnBottomButtonPanel(
            mainButtonName: _id == '' ? '保存' : '更新',
            mainButtonOnTap: _actionSaveOrUpdate,
            iconButtonList: [
              BrnVerticalIconButton(
                  name: _preview ? "编辑" : "预览",
                  iconWidget:
                      Icon(_preview ? Icons.edit : Icons.remove_red_eye_sharp),
                  onTap: () => setState(() => _preview = !_preview)),
              BrnVerticalIconButton(
                  name: "图片",
                  iconWidget: const Icon(Icons.image),
                  onTap: _uploadImage),
              BrnVerticalIconButton(
                  name: "表格",
                  iconWidget: const Icon(Icons.table_view),
                  onTap: () => setState(() => _content =
                      "$_content\n\n |标题1|标题2|\n|-----------|-----------|\n|内容1|内容2|")),
              BrnVerticalIconButton(
                  name: "todo",
                  iconWidget: const Icon(Icons.toc_outlined),
                  onTap: () =>
                      setState(() => _content = "$_content\n\n - [x] 代办1")),
            ],
          )
        ],
      ),
    );
  }
}
