import 'package:flutter/material.dart';
import 'package:love/pages/fragment.dart';


// 个人视图
class MeFragment extends StatefulWidget implements PageFragment {
  const MeFragment({super.key});

  @override
  State<StatefulWidget> createState() => _MeFragmentState();

  @override
  void addCallback() {
    // TODO: implement addCallback
  }
}


class _MeFragmentState extends State<MeFragment> with TickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Stack(
            alignment: const Alignment(0.6, 0.6),
            children: [
               Image.network('https://gitea.xiaoyou.host/avatars/a4508f985f8a99ea2c5eff4acfc260b3'),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                ),
                child: const Text(
                  'Mia B',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        ]
    );
  }
}