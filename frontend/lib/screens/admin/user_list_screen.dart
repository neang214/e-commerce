import 'package:flutter/material.dart';

class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Directory")),
      body: ListView.builder(
        itemCount: 3, // Replace with dynamic list from backend
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.person),
            title: Text("User Full Name"),
            subtitle: Text("user@example.com"),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Logic: Delete user from backend
              },
            ),
          );
        },
      ),
    );
  }
}