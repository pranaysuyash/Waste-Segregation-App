import 'package:flutter/material.dart';
import '../models/premium_feature.dart';

class PremiumFeatureCard extends StatelessWidget {
  final PremiumFeature feature;
  final bool isEnabled;

  const PremiumFeatureCard({
    Key? key,
    required this.feature,
    required this.isEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          IconData(int.parse(feature.icon), fontFamily: 'MaterialIcons'),
          color: isEnabled ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          feature.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          feature.description,
          style: TextStyle(
            color: isEnabled ? Colors.black87 : Colors.grey,
          ),
        ),
        trailing: isEnabled
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
} 