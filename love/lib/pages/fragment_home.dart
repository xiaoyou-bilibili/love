import 'dart:async';

import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:love/component/item_countdown.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';

// 主页视图
class HomeFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const HomeFragment(this._key) : super(key: _key);

  @override
  void addCallback() {
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

  String _getTime() {
    return _countDownType == 1
        ? "${_time.year}-${_time.month}-${_time.day}"
        : "${_time.month}-${_time.day}";
  }

  void addCountDown() {
    showCustomDialog(
      context: context,
      title: "添加倒计时",
      children: [
        BrnTextInputFormItem(
          title: "倒计时标题",
          hint: "输入倒计时标题",
          onChanged: (newValue) {
            _title = newValue;
          },
        ),
        BrnRadioInputFormItem(
          title: "倒计时类型",
          options: [_countDownTypeList[1], _countDownTypeList[2]],
          value: _countDownTypeList[_countDownType],
          onChanged: (oldValue, newValue) {
            setState(() {
              _countDownType = newValue == _countDownTypeList[1] ? 1 : 2;
            });
          },
        ),
        BrnTitleFormItem(
          title: "时间",
          subTitle: _getTime(),
          operationLabel: "设置时间",
          onTap: () {
            BrnDatePicker.showDatePicker(
              context,
              initialDateTime: DateTime.now(),
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
      ],
      onConfirm: () {
        // 构建请求
        var resp = ApiService.addCountDown(AddCountDownReq(
          _title,
          _getTime(),
          _countDownType,
          Storage.getSexSync(),
        ));
        requestProcess(context, resp, () => setState(() {}));
      },
    );
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
            return const BrnPageLoading();
          },
        ),
      ),
    );
  }
}
