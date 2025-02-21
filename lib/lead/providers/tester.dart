import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:odoo_crm_management/initilisation.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.teal, // Customize as needed
      ),
      body: Center(
        child: Consumer<OdooClientManager>(
          builder: (context, provider, child) {
            // Ensure session is available
            if (provider.currentsession == null) {
              return const Icon(Icons.person, size: 100, color: Colors.grey);
            }

            String sessionId = provider.currentsession!.id;

            // Correct the model if needed (res.users for Odoo users)
            String imageUrl =
                "${provider.url}web/image/res.partner/8/avatar_1920";

            return ClipOval(
              // Make the image circular
              child: Image.network(
                imageUrl,
                headers: {
                  "Cookie": "session_id=$sessionId", // Attach session for auth
                },
                width: 150, // Customize image size
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person,
                      size: 100, color: Colors.grey);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
