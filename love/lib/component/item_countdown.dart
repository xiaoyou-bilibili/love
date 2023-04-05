import 'package:flutter/material.dart';
import 'package:love/component/component_avatar.dart';
import 'package:love/utils/model.dart';

// 倒计时组件
class ComponentItemCountdown extends StatelessWidget {
  final CountDown countDown;

  const ComponentItemCountdown(this.countDown, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.white,
        child: Container(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Row(children: [
              ComponentAvatar(countDown.sex),
              Container(
                margin: const EdgeInsets.all(15),
                child: Column(children: [
                  Text(countDown.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(countDown.time,
                      style: const TextStyle(color: Colors.grey)),
                ]),
              ),
              Flexible(child: Container()),
              Text(countDown.count,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 40, color: Colors.red)),
            ])));
  }
}
