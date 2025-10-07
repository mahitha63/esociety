import 'package:flutter/material.dart';

enum NotificationType { upcoming, due, late, confirmation }

class AppNotification {
  final String title;
  final String body;
  final DateTime date;
  final NotificationType type;
  final IconData icon;
  final Color color;

  AppNotification(
      {required this.title, required this.body, required this.date, required this.type, required this.icon, required this.color});
}