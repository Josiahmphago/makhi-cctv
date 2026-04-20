import 'package:flutter/material.dart';

class ContributionScreen extends StatelessWidget {
  const ContributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Contributions'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Contribution Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.volunteer_activism),
            title: const Text('Monthly Contribution'),
            subtitle: const Text('Support the community with recurring donations'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Monthly contribution tapped')),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.handshake),
            title: const Text('Emergency Fund'),
            subtitle: const Text('Help families during emergencies'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency fund tapped')),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Community Purchases'),
            subtitle: const Text('Collective buying power for essentials'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Community purchases tapped')),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('View My Contributions'),
            subtitle: const Text('See your past donations and payments'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View contributions tapped')),
              );
            },
          ),
        ],
      ),
    );
  }
}
