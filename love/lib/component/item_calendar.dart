import 'package:flutter/material.dart';
import 'package:love/component/component_avatar.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';

// 日程组件
class ComponentItemCalendar extends StatefulWidget {
  final CalendarInfo info;

  const ComponentItemCalendar(this.info, {super.key});

  @override
  State<ComponentItemCalendar> createState() => _ComponentItemCalendarState();
}

class _ComponentItemCalendarState extends State<ComponentItemCalendar> {
  late CalendarInfo info;

  @override
  Widget build(BuildContext context) {
    info = widget.info;
    return Card(
        child: Container(
      color: Colors.white,
      margin: const EdgeInsets.all(10),
      child: Row(
        children: [
          ComponentAvatar(info.sex),
          const SizedBox(width: 5),
          // Flexible(child: Container()),
          Text(info.title),
          const SizedBox(width: 5),
          Text(info.desc, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    ));
  }
}
