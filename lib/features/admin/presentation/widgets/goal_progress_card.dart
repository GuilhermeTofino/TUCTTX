import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GoalProgressCard extends StatelessWidget {
  final String title;
  final double current;
  final double target;
  final Color baseColor;
  final VoidCallback? onEditGoal;

  const GoalProgressCard({
    super.key,
    required this.title,
    required this.current,
    required this.target,
    required this.baseColor,
    this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    // Evita divisão por zero
    final percentage = target > 0 ? (current / target) : 0.0;
    final clampedPercentage = percentage.clamp(0.0, 1.0);
    final displayPercentage = (percentage * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              if (onEditGoal != null)
                GestureDetector(
                  onTap: onEditGoal,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 16, color: baseColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Circular Indicator
              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 10,
                          color: baseColor.withOpacity(0.1),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: clampedPercentage),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeOutExpo,
                          builder: (context, value, _) =>
                              CircularProgressIndicator(
                                value: value,
                                strokeWidth: 10,
                                color: baseColor,
                                strokeCap: StrokeCap.round,
                              ),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$displayPercentage%",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Text Logic
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Arrecadado",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: "R\$",
                        locale: "pt_BR",
                      ).format(current),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Meta",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: "R\$",
                        locale: "pt_BR",
                      ).format(target),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (target > 0 && current >= target) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    "Meta Atingida!",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
