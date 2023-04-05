import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:love/utils/model.dart';

// 代办清单组件
class ComponentItemNoteBook extends StatelessWidget {
  final NoteInfo info;
  const ComponentItemNoteBook(this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    DateTime timestamp =
        DateTime.fromMillisecondsSinceEpoch(info.timestamp * 1000);
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
            Text(DateTimeFormatter.formatDate(timestamp, 'yyyy年MM月dd日'))
          ]),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(info.content),
          )
        ]));
  }
}
