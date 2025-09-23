import 'package:flutter/material.dart';
import 'package:esociety/models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  // Controllers to manage the text in TextFormFields
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _societyNumberController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from the UserProfile passed into the widget
    _nameController = TextEditingController(text: widget.userProfile.name);
    _emailController = TextEditingController(text: widget.userProfile.email);
    _phoneController = TextEditingController(text: widget.userProfile.phone);
    _societyNumberController = TextEditingController(
      text: widget.userProfile.societyNumber,
    );
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the tree
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _societyNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.black12,
            child: Icon(Icons.person, size: 60, color: Colors.blueGrey),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _societyNumberController,
          readOnly: true, // Society number is always read-only
          decoration: const InputDecoration(
            labelText: 'Society Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shield_outlined),
            filled: true,
            fillColor: Colors.black12,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          readOnly: !_isEditing,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          readOnly: !_isEditing,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          readOnly: !_isEditing,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, // Make button take full width
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // When saving, create a new UserProfile object and pass it up.
                  widget.onProfileUpdated(
                    UserProfile(
                      name: _nameController.text,
                      email: _emailController.text,
                      phone: _phoneController.text,
                      societyNumber: _societyNumberController.text,
                      image: widget
                          .userProfile
                          .image, // Preserve the existing image
                    ),
                  );
                  _isEditing = false;
                } else {
                  // Enter editing mode
                  _isEditing = true;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditing
                  ? Colors.green
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white, // Sets the text color
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
          ),
        ),
      ],
    );
  }
}
