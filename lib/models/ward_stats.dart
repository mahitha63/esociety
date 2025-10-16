// TODO Implement this library.
import 'package:flutter/foundation.dart';

class WardStats {
  final String? wardId;
  final double? collectedAmount;
  final double? pendingAmount;
  final int? defaulterCount;

  WardStats({
    this.wardId,
    this.collectedAmount,
    this.pendingAmount,
    this.defaulterCount,
  });

  // Factory constructor to create a WardStats object from a JSON map
  factory WardStats.fromJson(Map<String, dynamic> json) {
    return WardStats(
      wardId: json['wardId'] as String?,
      collectedAmount: (json['collectedAmount'] as num?)?.toDouble(),
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble(),
      defaulterCount: (json['defaulterCount'] as num?)?.toInt(),
    );
  }
}