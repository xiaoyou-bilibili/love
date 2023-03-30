import 'dart:async';

import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:love/component/item_countdown.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';

// 主页视图
class HomeFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const HomeFragment(this._key): super(key: _key);

  @override
  void addCallback () {
    (_key.currentState as _HomeFragmentState).addCountDown();
  }

  @override
  State<StatefulWidget> createState() => _HomeFragmentState();

}
class _HomeFragmentState extends State<HomeFragment> {
  // 倒计时类型
  final _countDownTypeList = ["", "正计时", "倒计时"];
  String _title = ""; // 倒计时标题
  int _countDownType = 1;
  DateTime _time = DateTime.now();

  String _getTime(){
    return _countDownType == 1 ? "${_time.year}-${_time.month}-${_time.day}" : "${_time.month}-${_time.day}";
  }

  void addCountDown() {
    // 显示一个弹窗
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.all(2),
        title: const Text("添加倒计时"),
        content: SizedBox(height: 200, child: Column(children: [
          BrnTextInputFormItem(
            title: "倒计时标题",
            hint: "输入倒计时标题",
            onChanged: (newValue) {_title = newValue;},
          ),
          BrnRadioInputFormItem(
              title: "倒计时类型",
              options: [_countDownTypeList[1], _countDownTypeList[2]],
              value: _countDownTypeList[_countDownType],
              onChanged: (oldValue, newValue) {
                setState(() {_countDownType = newValue == _countDownTypeList[1] ? 1:2;});
              },
          ),
          BrnTitleFormItem(
            title: "时间",
            subTitle: _getTime(),
            operationLabel: "设置时间",
            onTap: () {
              BrnDatePicker.showDatePicker(context,
                  initialDateTime: DateTime.now(),
                  // 支持DateTimePickerMode.date、DateTimePickerMode.datetime、DateTimePickerMode.time
                  pickerMode: BrnDateTimePickerMode.date,
                  pickerTitleConfig: BrnPickerTitleConfig.Default,
                  dateFormat: _countDownType == 1 ? "yyyy-MM-dd" : "MM-dd",
                  onConfirm: (dateTime, list) {
                    // 强制要求更新，避免时间错乱
                    (context as Element).markNeedsBuild();
                    _time = dateTime;
                  },
              );
            },
          ),
        ])),
        actions: <Widget>[
          //关闭对话框
          TextButton(child: const Text("取消"), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: const Text("确定", style: TextStyle(color: Colors.blue)),
            onPressed: () {
              Navigator.of(context).pop(true); //关闭对话框
              // 构建请求
              ApiService.addCountDown(AddCountDownReq(_title, _getTime(), _countDownType, Storage.getSexSync())).
              then((value) =>{
                BrnToast.show("添加成功", context),
                setState(() {})
              }).
              onError((error, stackTrace) => {
                BrnToast.show("错误 $error", context)
              });
            },
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimationLimiter(
        child: FutureBuilder(
          future: ApiService.getCountDown(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            // 请求已结束
            if (snapshot.connectionState == ConnectionState.done) {
              List<CountDown> data = snapshot.data;
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: ComponentItemCountdown(data[index]),
                      ),
                    ),
                  );
                },
              );
            }
            //请求完成
            return const Text("加载中。。");
          }
        )
      ),
    );
  }
}
