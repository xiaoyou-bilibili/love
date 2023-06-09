import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:love/utils/http.dart';
import 'package:love/utils/utils.dart';
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
  State<StatefulWidget> createState() => _PageEditState();
}

class _PageEditState extends State<PageEdit> {
  String _id = '';
  String _title = '';
  String _content = '';
  int _timestamp = 0;
  int _sex = 0;
  bool _preview = false; // 预览模式
  // 标签选择部分
  List<String> _tags = [];
  String _tag = "";
  List<bool> _selectStatus = [];

  @override
  void initState() {
    _id = widget._id;
    // 页面初始化获取一下所有的tag
    ApiService.getNoteTagList().then((tags) => {
          tags.isNotEmpty
              ? setState(() {
                  _selectStatus = List.generate(tags.length, (index) => false);
                  _tags = tags;
                })
              : null
        });
    // 判断id是否存在
    if (_id != '') {
      ApiService.getNote(_id).then((note) => {
            setState(() {
              _preview = true;
              _title = note.title;
              _content = note.content;
              _timestamp = note.timestamp;
              _sex = note.sex;
              _tag = note.tag;
            })
          });
    }
    super.initState();
  }

  void _actionSuccess(BuildContext context) {
    BrnToast.show("操作成功", context);
    Navigator.pop(context);
  }

  // 点击保存或更新按钮的操作
  void _actionSaveOrUpdate() {
    NoteInfo info = NoteInfo(
      tag: _tag,
      title: _title,
      content: _content,
      timestamp: getUnixNow(),
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
    uploadImage(
      context: context,
      onSuccess: (url) =>
          setState(() => _content = "$_content\n\n ![图片]($host/$url)"),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    controller.text = _content;
    // 添加一个监听器监听文本变化
    controller.addListener(() {
      _content = controller.text;
    });
    // markDown编辑器
    Widget edit = MarkdownField(
      key: Key(_content),
      controller: controller,
      emojiConvert: true,
      expands: true,
    );
    if (_preview) {
      // 预览模式设置各种触发事件
      edit = MarkdownParse(
        data: _content,
        onTapLink: (String text, String? href, String title) =>
            href != null ? launchUrl(Uri.parse(href)) : "",
        imageBuilder: (Uri uri, String? title, String? alt) =>
            CachedNetworkImage(imageUrl: uri.toString()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title == '' ? '无标题' : _title,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Visibility(
            visible: !_preview,
            child: BrnTextInputFormItem(
              key: Key(_title),
              controller: TextEditingController(text: _title),
              title: "笔记标题",
              hint: "输入标题~",
              onChanged: (newValue) {
                _title = newValue;
              },
            ),
          ),
          Visibility(
            visible: !_preview,
            child: BrnTextQuickSelectFormItem(
              title: "标签",
              btnsTxt: _tags,
              value: _tag,
              isBtnsScroll: true,
              selectBtnList: _selectStatus,
              prefixIconType: BrnPrefixIconType.add,
              onBtnSelectChanged: (index) {
                setState(() {
                  _tag = _tags[index];
                  // 修改其他按钮的状态，只能有一个按钮被点击
                  for (var i = 0; i < _tags.length; i++) {
                    _selectStatus[i] = i == index;
                  }
                });
              },
              onAddTap: () {
                BrnMiddleInputDialog(
                  title: "标签名称",
                  hintText: '新标签名称',
                  onConfirm: (value) {
                    _tag = value;
                    Navigator.pop(context);
                    (context as Element).markNeedsBuild();
                  },
                  onCancel: () => Navigator.pop(context),
                ).show(context);
              },
            ),
          ),
          // editable text with toolbar by default
          Expanded(child: edit),
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
                  iconWidget: const Icon(Icons.table_chart),
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
