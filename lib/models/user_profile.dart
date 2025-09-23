import 'dart:io';

class UserProfile {
  String name;
  String email;
  String phone;
  String societyNumber;
  File? image; // Use File for a picked image

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.societyNumber,
    this.image,
  });
}
