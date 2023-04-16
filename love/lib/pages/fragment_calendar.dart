import 'dart:html';

import 'package:bruno/bruno.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:love/pages/fragment.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarFragment extends StatefulWidget implements PageFragment {
  final GlobalKey _key;

  const CalendarFragment(this._key) : super(key: _key);

  @override
  State<StatefulWidget> createState() => _CalendarFragmentState();

  @override
  void addCallback() {
    // TODO: implement addCallback
  }
}

class _CalendarFragmentState extends State<CalendarFragment> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
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
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {_focusedDay = selectedDay;});
        },
        eventLoader: (day) {
          if (day.day == 1) {
            return [Event("event")];
          }
          return [];
        },
      )
    ]);
  }
}
