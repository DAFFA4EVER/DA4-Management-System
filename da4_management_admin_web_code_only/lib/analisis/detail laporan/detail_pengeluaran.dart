import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../backend/buktiDataHandlerAndroid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../backend/moduleDataHandler.dart';

class TokoPengeluaranScreen extends StatefulWidget {
  final List<dynamic> pengeluaranItems;
  final String chooseTokoID;

  TokoPengeluaranScreen({
    required this.pengeluaranItems,
    required this.chooseTokoID,
  });

  @override
  _TokoPengeluaranScreenState createState() => _TokoPengeluaranScreenState();
}

class _TokoPengeluaranScreenState extends State<TokoPengeluaranScreen> {
  List<String> pengeluaranJenis = [
    'Listrik',
    'Gaji',
    'ATK',
    'Bahan Baku Tambahan',
    'Service',
    'Peralatan',
    'Rumah Tangga',
    'Entertainment',
    'Promosi',
    'Transportasi',
    'Admin Grab',
    'Admin Gojek',
    'Admin Bank',
    'Admin Lainnya',
    'Penyusutan',
    'Beban Ongkos Kirim',
    'Beban Produksi',
    'Lainnya',
  ];

  Map<String, dynamic> moduleSetting = {};
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();

    initModule();
  }

  void initModule() {
    getModuleSetting();
  }

  void setUpModule() {
    pengeluaranJenis = List<String>.from(moduleSetting['pemasukkan']);
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
        title: const Text('History Pengeluaran'),
      ),
      body: ListView(
        children: [
          // pengeluaran
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Pengeluaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.pengeluaranItems.length,
                  itemBuilder: (context, index) {
                    final pengeluaran = widget.pengeluaranItems[index] ??
                        {}; // Initialize with an empty map if null
                    final TextEditingController namaController =
                        TextEditingController(text: pengeluaran['nama']);
                    final TextEditingController jumlahController =
                        TextEditingController(
                            text: pengeluaran['jumlah']?.toString() ?? null);

                    if (pengeluaran['type'] == null) {
                      pengeluaran['type'] = pengeluaranJenis[0];
                    }

                    final TextEditingController _typePengeluaranController =
                        TextEditingController(text: pengeluaran['type']);

                    final String photo = pengeluaran['photo'] ?? '';

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
                                labelText: 'Nama Pengeluaran',
                              ),
                              onChanged: (value) {},
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DropdownButtonFormField<String>(
                              enableFeedback: false,
                              value: _typePengeluaranController.text,
                              items: pengeluaranJenis.map((option) {
                                return DropdownMenuItem<String>(
                                  enabled: false,
                                  value: option,
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
                                        pengeluaran['imageName'],
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
                                        pengeluaran['tanggal'],
                                        pengeluaran['imageName'],
                                        widget.chooseTokoID);
                                if (imageData != null) {
                                  hideLoadingOverlay(context);
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: Container(
                                          width: double.maxFinite,
                                          height: double.maxFinite,
                                          child: CachedNetworkImage(
                                            imageUrl: imageData,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Close'),
                                          ),
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
