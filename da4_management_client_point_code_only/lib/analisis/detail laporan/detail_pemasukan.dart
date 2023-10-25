//import 'package:da4_management_client_point/backend/control.dart';
import '../../backend/moduleDataHandler.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../backend/buktiDataHandlerAndroid.dart';

class TokoPemasukanScreen extends StatefulWidget {
  final List<dynamic> pemasukanItems;
  final String chooseTokoID;

  TokoPemasukanScreen({
    required this.pemasukanItems,
    required this.chooseTokoID,
  });

  @override
  _TokoPemasukanScreenState createState() => _TokoPemasukanScreenState();
}

class _TokoPemasukanScreenState extends State<TokoPemasukanScreen> {
  Map<String, dynamic> moduleSetting = {};
  bool dataLoaded = false;

  List<String> pemasukkanExternalJenis = [
    'Grab',
    'Gojek',
    'QRIS',
    'OVO',
    'GoPay',
    'Card',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();

    initModule();
  }

  void initModule() {
    getModuleSetting();
  }

  void setUpModule() {
    pemasukkanExternalJenis = List<String>.from(moduleSetting['pemasukkan']);
    dataLoaded = true;
    setState(() {});
  }

  Future<void> getModuleSetting() async {
    if ((await ModuleHandler().checkModuleExist()) == true) {
      moduleSetting = await ModuleHandler().getModuleData();
    } else {
      await ModuleHandler().uploadModuleDataDefault();
      moduleSetting = await ModuleHandler().getModuleData();
    }
    setUpModule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Pemasukkan External'),
      ),
      body: ListView(
        children: [
          //
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Pemasukan External',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.pemasukanItems.length,
                  itemBuilder: (context, index) {
                    final pemasukan = widget.pemasukanItems[index] ??
                        {}; // Initialize with an empty map if null
                    final TextEditingController namaController =
                        TextEditingController(text: pemasukan['nama']);
                    final TextEditingController jumlahController =
                        TextEditingController(
                            text: pemasukan['jumlah']?.toString() ?? null);
                    final String photo = pemasukan['photo'] ?? '';

                    if (pemasukan['type'] == null) {
                      pemasukan['type'] == pemasukkanExternalJenis[0];
                    }

                    final TextEditingController _typePemasukanController =
                        TextEditingController(
                            text: pemasukan['type'] ??
                                pemasukkanExternalJenis[0]);

                    return Card(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: namaController,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Nama pemasukan',
                              ),
                              onChanged: (value) {},
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DropdownButtonFormField<String>(
                              enableFeedback: false,
                              value: _typePemasukanController.text,
                              items: pemasukkanExternalJenis.map((option) {
                                return DropdownMenuItem<String>(
                                  value: option,
                                  enabled: false,
                                  child: Text(option),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Tipe',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              enabled: false,
                              controller: jumlahController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Total Harga (Rupiah)',
                              ),
                              keyboardType: TextInputType.number,
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
                                        pemasukan['imageName'],
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
                                  pemasukan['tanggal'],
                                  pemasukan['imageName'],
                                );
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
