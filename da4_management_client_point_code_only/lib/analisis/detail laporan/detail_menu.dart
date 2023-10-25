import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class MenuDetailScreen extends StatelessWidget {
  final List<dynamic> selectedMenuItems;

  MenuDetailScreen({required this.selectedMenuItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Laporan'),
      ),
      body: ListView(
        children: [
          // Menu Terjual
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Total Menu Terjual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedMenuItems.length,
                  itemBuilder: (context, index) {
                    final menu = selectedMenuItems[index];
                    final quantity = menu['quantity'] ?? 0;
                    return Card(
                      
                      child: ListTile(
                        title: Text(menu['name']),
                        subtitle: Text(formatPrice(menu['jual'])),
                        trailing: SizedBox(
                          width: 60,
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            initialValue: '$quantity',
                            enabled: false,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatPrice(num price) {
    var formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    String formattedPrice = formatCurrency.format(price);
    int decimalIndex = formattedPrice.indexOf('');
    if (decimalIndex != -1) {
      formattedPrice = formattedPrice.substring(0, decimalIndex);
    }
    return formattedPrice;
  }

  void showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Loading...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoadingOverlay(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class ThousandsSeparatorDigitsOnlyInputFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String parsedValue = newValue.text.replaceAll(',', '');
    final String formattedValue =
        NumberFormat('#,###', 'en_US').format(int.parse(parsedValue));

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
