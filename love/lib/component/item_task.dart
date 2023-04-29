import 'package:flutter/material.dart';
import 'package:love/component/component_avatar.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';

// 代办清单组件
class ComponentItemTaskBox extends StatefulWidget {
  final TaskInfo info;

  const ComponentItemTaskBox(this.info, {super.key});

  @override
  State<ComponentItemTaskBox> createState() => _ComponentItemTaskBoxState();
}

class _ComponentItemTaskBoxState extends State<ComponentItemTaskBox> {
  late TaskInfo info;

  _changeCheckState(bool? value) {
    bool done = value ?? false;
    // 调用接口去修改状态
    ApiService.updateTask(UpdateTaskReq(info.id, done)).then(
      (value) => setState(() {
        info.done = done;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    info = widget.info;
    return Card(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.all(3),
        child: Row(
          children: [
            Checkbox(value: info.done, onChanged: _changeCheckState),
            const SizedBox(width: 5),
            Text(
              info.title,
              style: TextStyle(
                decoration: info.done ? TextDecoration.lineThrough : null,
              ),
            ),
            Flexible(child: Container()),
            ComponentAvatar(info.sex)
          ],
        ),
      ),
    );
  }
}
