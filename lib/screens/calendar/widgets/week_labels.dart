import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeekLabels extends StatelessWidget {
  const WeekLabels({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: labels
            .map(
              (e) => Expanded(
                child: Center(
                  child: Text(
                    e.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
