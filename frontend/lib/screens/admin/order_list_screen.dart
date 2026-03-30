import 'package:flutter/material.dart';

class OrderListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Orders")),
      body: ListView.builder(
        itemCount: 5, // Replace with dynamic list from backend
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text("#${index + 1}")),
              title: Text("Customer Name"),
              subtitle: Text("Total: \$120.00 | Status: Pending"),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  // Logic: Update order status via backend API
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'Shipped', child: Text("Mark as Shipped")),
                  PopupMenuItem(value: 'Delivered', child: Text("Mark as Delivered")),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}