// lib/payments/airtime_purchase_screen.dart
import 'package:flutter/material.dart';

class AirtimePurchaseScreen extends StatefulWidget {
  const AirtimePurchaseScreen({super.key});

  @override
  State<AirtimePurchaseScreen> createState() => _AirtimePurchaseScreenState();
}

class _AirtimePurchaseScreenState extends State<AirtimePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _network = 'Vodacom';
  String _type = 'Airtime';
  double _amount = 10;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // For now we just show a snackbar.
    // Later we plug in real payment / voucher provider.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pretending to buy $_type of R${_amount.toStringAsFixed(0)} '
          'for ${_phoneController.text} on $_network.\n'
          'Integration coming soon.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Airtime / Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Top-up for yourself or a contact.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  // Network dropdown
                  DropdownButtonFormField<String>(
                    value: _network,
                    decoration: const InputDecoration(
                      labelText: 'Network',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Vodacom', child: Text('Vodacom')),
                      DropdownMenuItem(value: 'MTN', child: Text('MTN')),
                      DropdownMenuItem(value: 'Telkom', child: Text('Telkom')),
                      DropdownMenuItem(value: 'Cell C', child: Text('Cell C')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _network = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Airtime vs Data
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Airtime', child: Text('Airtime')),
                      DropdownMenuItem(value: 'Data', child: Text('Data')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: 'e.g. 0831234567',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Enter a phone number';
                      if (v.length < 9) return 'Number looks too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amount slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: R${_amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        min: 5,
                        max: 500,
                        divisions: 99,
                        value: _amount,
                        label: 'R${_amount.toStringAsFixed(0)}',
                        onChanged: (v) {
                          setState(() => _amount = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text('Buy Now (demo)'),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'In production, this will integrate with a secure payment '
                    'provider or voucher API.\nFor now it is a demo screen.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
