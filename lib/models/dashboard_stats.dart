import 'package:flutter/foundation.dart';

// Import the WardStats class from its dedicated file
import 'ward_stats.dart';

// A Dart class for the main DashboardStats model
class DashboardStats {
  final double? totalCollected;
  final double? totalPending;
  final int? totalDefaulters;
  final List<WardStats>? wardStatistics;
  final String? period;

  DashboardStats({
    this.totalCollected,
    this.totalPending,
    this.totalDefaulters,
    this.wardStatistics,
    this.period,
  });

  // Factory constructor to create a DashboardStats object from a JSON map.
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Safely parse the list of WardStats. If it's null, set it to an empty list.
    var wardStatsList = (json['wardStatistics'] as List?)
        ?.map((i) => WardStats.fromJson(i as Map<String, dynamic>))
        .toList();

    return DashboardStats(
      totalCollected: (json['totalCollected'] as num?)?.toDouble(),
      totalPending: (json['totalPending'] as num?)?.toDouble(),
      totalDefaulters: (json['totalDefaulters'] as num?)?.toInt(),
      wardStatistics: wardStatsList ?? [],
      period: json['period'] as String?,
    );
  }
}