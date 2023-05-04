import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';

// 笔记组件
class ComponentItemNoteBook extends StatelessWidget {
  final NoteInfo info;
  const ComponentItemNoteBook(this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    DateTime timestamp = unix2DateTime(info.timestamp);
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        Row(children: [
          Text(
            info.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Flexible(child: Container()),
          Text(
            DateTimeFormatter.formatDate(timestamp, 'yyyy年MM月dd日'),
            style: TextStyle(color: Storage.getSecondaryColor()),
          )
        ]),
        const SizedBox(height: 10),
        Container(
          alignment: Alignment.centerLeft,
          child: Text(info.content),
        )
      ]),
    );
  }
}
