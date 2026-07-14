import 'package:flutter/material.dart';
import '../core/colors.dart';

class AppCard extends StatelessWidget {
  final int value;
  final String title;
  final String desc;
  const AppCard({
    super.key,
    required this.value,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 48,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4,
        children: [
          Icon(Icons.star_half_rounded, color: AppColors.grey7, size: 26),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(desc, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
