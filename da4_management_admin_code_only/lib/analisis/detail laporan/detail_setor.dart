import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../backend/buktiDataHandlerAndroid.dart';

class TokoSetorScreen extends StatefulWidget {
  final List<dynamic> setorItems;
  final String chooseTokoID;

  TokoSetorScreen({
    required this.setorItems,
    required this.chooseTokoID,
  });

  @override
  _TokoSetorScreenState createState() => _TokoSetorScreenState();
}

class _TokoSetorScreenState extends State<TokoSetorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Setor'),
      ),
      body: ListView(
        children: [
          // setor
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Setor Ke Bank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.setorItems.length,
                  itemBuilder: (context, index) {
                    final setor = widget.setorItems[index] ??
                        {}; // Initialize with an empty map if null
                    final TextEditingController setorNamaController =
                        TextEditingController(text: setor['nama']);
                    final TextEditingController setorBankController =
                        TextEditingController(text: setor['bank']);
                    final TextEditingController setorRekeningController =
                        TextEditingController(text: setor['rekening']);
                    final TextEditingController setorJumlahController =
                        TextEditingController(
                            text: setor['jumlah']?.toString() ?? null);

                    final String photo = setor['photo'] ?? '';

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
                              setor['tanggal'],
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            // nama setor
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: setorNamaController,
                              onChanged: (value) {},
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Penanggung Jawab Setor',
                              ),
                            ),
                          ),
                          Padding(
                            // nama bank
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: setorBankController,
                              onChanged: (value) {},
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Bank Tujuan',
                              ),
                            ),
                          ),
                          Padding(
                            // no rekening
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: setorRekeningController,
                              onChanged: (value) {},
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'No Rekening',
                              ),
                            ),
                          ),
                          Padding(
                            // jumlah
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              onChanged: (value) {},
                              controller: setorJumlahController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                ThousandsSeparatorDigitsOnlyInputFormatter(),
                              ],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Jumlah (Rupiah)',
                              ),
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
                                        setor['imageName'],
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
                                        setor['tanggal'],
                                        setor['imageName'],
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
          )
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
