import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../backend/buktiDataHandlerAndroid.dart';

class TokoStrukCashScreen extends StatefulWidget {
  final List<dynamic> strukCashItems;
  final String chooseTokoID;

  TokoStrukCashScreen({
    required this.strukCashItems,
    required this.chooseTokoID,
  });

  @override
  _TokoStrukCashScreenState createState() => _TokoStrukCashScreenState();
}

class _TokoStrukCashScreenState extends State<TokoStrukCashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Cash'),
      ),
      body: ListView(
        children: [
          // strukCash
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Riwayat Cash',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.strukCashItems.length,
                  itemBuilder: (context, index) {
                    final strukCash = widget.strukCashItems[index] ??
                        {}; // Initialize with an empty map if null
                    final TextEditingController namastrukCashController =
                        TextEditingController(text: strukCash['nama']);
                    final TextEditingController strukCashController =
                        TextEditingController(
                            text: strukCash['cash'].toString());
                    final TextEditingController strukJumlahController =
                        TextEditingController(
                            text: strukCash['jumlah'].toString());

                    final String photo = strukCash['photo'] ?? '';

                    return Card(
                      
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Tanggal',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              strukCash['tanggal'],
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: namastrukCashController,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Nama Struk',
                              ),
                              onChanged: (value) {},
                            ),
                          ),
                          Padding(
                            // jumlah
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              onChanged: (value) {},
                              controller: strukCashController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                ThousandsSeparatorDigitsOnlyInputFormatter(),
                              ],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Jumlah Cash (Rupiah)',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: strukJumlahController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText:
                                    'Total Pendapatan Sesuai Struk (Rupiah)',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {},
                            ),
                          ),
                          if (photo.isNotEmpty) ...[
                            const Divider(),
                            InkWell(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo),
                                      Text(
                                        strukCash['imageName'],
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              onTap: () async {
                                showLoadingOverlay(context);
                                final imageData = await BuktiDataHandlerAndroid
                                    .instance
                                    .loadBuktiFromFirestorage(
                                        strukCash['tanggal'],
                                        strukCash['imageName'],
                                        widget.chooseTokoID);
                                if (imageData != null) {
                                  hideLoadingOverlay(context);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Container(
                                            child: Image.memory(imageData)),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Close'))
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ],
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
    int decimalIndex = formattedPrice.indexOf(',');
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
