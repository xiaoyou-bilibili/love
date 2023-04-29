import 'package:bruno/bruno.dart';
import 'package:flutter/material.dart';
import 'package:love/component/item_calendar.dart';
import 'package:love/pages/fragment.dart';
import 'package:love/utils/api.dart';
import 'package:love/utils/model.dart';
import 'package:love/utils/storage.dart';
import 'package:love/utils/utils.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const CalendarFragment(this._key) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _CalendarFragmentState();

  @override
  void addCallback() {
    (_key.currentState as _CalendarFragmentState).addCalendar();
  }
}

class _CalendarFragmentState extends State<CalendarFragment> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // 日程列表
  final Map<String, List<CalendarInfo>> _info = {};
  // 当前日程列表
  List<CalendarInfo> _current = [];
  // 日程标题
  String _title = "";
  // 日程备注
  String _desc = "";
  // 日程类型
  int _type = 1;
  // 日程开始时间和结束时间
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();

  @override
  void initState() {
    _getCalendarList(_focusedDay.year, _focusedDay.month);
    super.initState();
  }

  void addCalendar() {
    // 日程类型
    final calendarTypeList = ["", "时间段", "大姨妈"];
    // 显示一个弹窗
    showCustomDialog(
      context: context,
      title: "添加日程",
      children: [
        BrnTextInputFormItem(
          title: "日程标题",
          hint: "输入日程标题",
          onChanged: (newValue) => _title = newValue,
        ),
        BrnTextInputFormItem(
          title: "备注",
          hint: "输入备注",
          onChanged: (newValue) => _desc = newValue,
        ),
        BrnRadioInputFormItem(
          title: "日程类型",
          options: [calendarTypeList[1], calendarTypeList[2]],
          value: calendarTypeList[_type],
          onChanged: (oldValue, newValue) =>
              _type = newValue == calendarTypeList[1] ? 1 : 2,
        ),
        BrnTitleFormItem(
          title: "时间范围",
          subTitle: "${formatDate(_start)} - ${formatDate(_end)}",
          operationLabel: "设置时间",
          onTap: () {
            DateTime now = DateTime.now();
            BrnDateRangePicker.showDatePicker(
              context,
              minDateTime: DateTime.parse('${now.year}-01-01 00:00:00'),
              maxDateTime: DateTime.parse('${now.year}-12-31 23:59:59'),
              pickerMode: BrnDateTimeRangePickerMode.date,
              dateFormat: 'MM月-dd日',
              initialStartDateTime: now,
              initialEndDateTime: now,
              onConfirm: (startDateTime, endDateTime, startlist, endlist) {
                _start = startDateTime;
                _end = endDateTime;
                (context as Element).markNeedsBuild();
              },
            );
          },
        ),
      ],
      onConfirm: () {
        var resp = ApiService.addCalendar(AddCalendarReq(
          title: _title,
          desc: _desc,
          startTime: getUnix(_start),
          endTime: getUnix(_end),
          calendarType: _type,
          timestamp: getUnix(DateTime.now()),
          sex: Storage.getSexSync(),
        ));
        requestProcess(
          context,
          resp,
          () => _getCalendarList(_focusedDay.year, _focusedDay.month),
        );
      },
    );
  }

  // 获取日程列表
  void _getCalendarList(int year, int month) {
    ApiService.getCalendarList("$year", "$month").then((value) {
      setState(() {
        _info.clear();
        for (var item in value) {
          if (_info[item.date] == null) {
            _info[item.date] = [item];
          } else {
            _info[item.date]?.add(item);
          }
        }
        _onDaySelected(_focusedDay, _focusedDay);
      });
    });
  }

  // 时间被选择
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = selectedDay;
      _start = selectedDay;
      _end = selectedDay;
      if (_info[formatDate(selectedDay)] != null) {
        _current = _info[formatDate(selectedDay)]!;
      } else {
        _current = [];
      }
    });
  }

  // 根据事件来展示内容
  List<Widget> _getCycleContent(List<CalendarInfo> info) {
    List<Widget> list = [];
    for (var item in info) {
      Color co = Colors.blue;
      if (item.calendarType == 2) {
        co = const Color.fromRGBO(252, 139, 171, 10);
      } else if (item.sex == 2) {
        co = Colors.red;
      }
      list.add(Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: co,
        ),
        width: 8,
        height: 8,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // 获取标签
    List<ComponentItemCalendar> calendarList = [];
    for (var item in _current) {
      calendarList.add(ComponentItemCalendar(item));
    }
    return Column(children: [
      TableCalendar(
        locale: 'zh_CN',
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        currentDay: _focusedDay,
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _getCalendarList(focusedDay.year, focusedDay.month);
        },
        onDaySelected: _onDaySelected,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            String key = formatDate(day);
            if (_info.containsKey(key)) {
              return Positioned(
                bottom: 1,
                child: Row(children: _getCycleContent(_info[key]!)),
              );
            }
          },
          defaultBuilder: (context, day, focusedDay) {
            Color defaultColor = Colors.black;
            DateTime now = DateTime.now();
            if (day.year == now.year &&
                day.month == now.month &&
                day.day == now.day) {
              defaultColor = Storage.getPrimaryColor();
            }
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              child: Text(
                day.day.toString(),
                style: TextStyle(color: defaultColor),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Storage.getPrimaryColor(),
                shape: BoxShape.circle,
              ),
              child: Text(
                day.day.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: calendarList,
        ),
      )
    ]);
  }
}
