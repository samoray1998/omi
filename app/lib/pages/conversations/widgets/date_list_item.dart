import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/utils/other/temp.dart';

class DateListItem extends StatelessWidget {
  final bool isFirst;
  final DateTime date;

  const DateListItem({super.key, required this.date, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    var now = DateTime.now();
    var yesterday = now.subtract(const Duration(days: 1));
    var isToday = date.month == now.month && date.day == now.day && date.year == now.year;
    var isYesterday = date.month == yesterday.month && date.day == yesterday.day && date.year == yesterday.year;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 0 : 20, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isToday
                ? 'Your moments'
                : isYesterday
                    ? 'Yesterday'
                    : dateTimeFormat('MMM dd', date),
            style: const TextStyle(color: Color.fromRGBO(13, 41, 81, 1), fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
            ),
          ),
          InkWell(
            onTap: () {
              print("the calender is clicked ");
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: FaIcon(
                FontAwesomeIcons.calendarWeek,
                color: Color.fromRGBO(229, 221, 198, 1),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              print("the calender is clicked ");
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: FaIcon(
                FontAwesomeIcons.expand,
                color: Color.fromRGBO(229, 221, 198, 1),
              ),
            ),
          )
        ],
      ),
    );
  }
}
