import 'package:flutter/material.dart';

class AddRestrictedAreaScreen extends StatefulWidget {
  const AddRestrictedAreaScreen({super.key});

  @override
  State<AddRestrictedAreaScreen> createState() =>
      _AddRestrictedAreaScreenState();
}

class _AddRestrictedAreaScreenState extends State<AddRestrictedAreaScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Restricted Area")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Area Name'),
            ),
            TextField(
              controller: _radiusController,
              decoration: const InputDecoration(labelText: 'Radius (m)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Add saving logic via RestrictedAreasProvider
                Navigator.pop(context);
              },
              child: const Text("Add Area"),
            ),
          ],
        ),
      ),
    );
  }
}
