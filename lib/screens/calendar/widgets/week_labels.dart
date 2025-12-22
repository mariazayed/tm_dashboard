import 'package:flutter/cupertino.dart';

class WeekLabels extends StatelessWidget {
  const WeekLabels({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      children: labels
          .map(
            (e) => Expanded(
              child: Center(
                child: Text(e, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          )
          .toList(),
    );
  }
}
