import 'package:da4_management_client_point/backend/laporanDataHandlerFirestore.dart';
import 'package:da4_management_client_point/backend/moduleDataHandler.dart';
import 'package:da4_management_client_point/pembelian/pembelian.dart';
import 'package:da4_management_client_point/pembelian/printState.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../backend/control.dart';
import 'select_menu_page.dart' as SelectMenu;
import 'choosePrintStruk.dart';

class AddPesanan extends StatefulWidget {
  @override
  State<AddPesanan> createState() => _AddPesananState();
}

class _AddPesananState extends State<AddPesanan> {
  List<Map<String, dynamic>> pembayaranItems = [];
  List<Map<String, dynamic>> selectedMenuItems = [];
  List<Map<String, dynamic>> lastMenuItems = [];
  List<String> listOrderCode = [];

  List<Map<String, dynamic>> pembayaranItemsBackup = [];
  List<Map<String, dynamic>> lastMenuItemsBackup = [];
  List<String> listOrderCodeBackup = [];

  final laporanHelper = LaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> laporanData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  String previousDate = '';
  DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  bool dataLoaded = false;
  String codeOrder = '';
  num totalMenu = 0;
  int cashBayar = 0;
  bool bayarCash = false;
  bool isCashValid = false;

  List<String> jenisPembayaranList = [
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
    DateTime now = DateTime.now();
    currentDate = DateFormat('yyyy-MM-dd').format(now);

    canEdit = true;
    checkLaporanExist();
  }

  Future<void> checkLaporanExist() async {
    try {
      printState.resetState();
      print('a');
      if (await laporanHelper.checkLaporanExist(currentDate) == false) {
        laporanData = laporanHelper.laporanTemplate(currentDate);
        LaporanDatabaseHandlerFirestore.instance
            .saveLaporanToFirestore(laporanData, currentDate);
      } else {
        laporanData = await laporanHelper.loadLaporanFromFirestore(currentDate);
      }
      lastMenuItems = List<Map<String, dynamic>>.from(laporanData['menu']);
      listOrderCode = List<String>.from(laporanData['order list']);
      // Backup
      print('x');
      pembayaranItemsBackup =
          List<Map<String, dynamic>>.from(laporanData['pemasukan external']);
      print('xx');
      lastMenuItemsBackup =
          List<Map<String, dynamic>>.from(laporanData['menu']);
      print('xxx');
      listOrderCodeBackup = List<String>.from(laporanData['order list']);
      print('xxxx');
      //
      if (laporanData['uploaded'] == true) {
        canEdit = false;
      }
      getModuleSetting();
    } catch (e) {
      print(e);
    }
    codeOrder = await generateOrderCode();
    setState(() {
      tokoNama = laporanData['namaToko'];
      tanggal = laporanData['date'];

      dataLoaded = true;
    });
  }

  Map<String, dynamic> moduleSetting = {};

  void setUpModule() {
    jenisPembayaranList = List<String>.from(moduleSetting['pemasukkan']);
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

  void navigateToSelectMenuScreen() async {
    if (canEdit) {
      final selected = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => SelectMenu.SelectMenuScreen(
            initialSelectedItems: selectedMenuItems,
            onSelectionChanged: (updatedSelection) {
              setState(() {
                selectedMenuItems = updatedSelection;
                getGrandTotal();
                validCash();
              });
            },
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          selectedMenuItems = selected;
          getGrandTotal();
          validCash();
        });
      }
    }
  }

  Future<String> generateOrderCode() async {
    List<int> orderCodeList = [];
    for (final menuItem in lastMenuItems) {
      int lastDigits = int.tryParse(
              menuItem['order'].substring(menuItem['order'].length - 4)) ??
          0;
      if (!listOrderCode.contains(menuItem['order'])) {
        listOrderCode.add(menuItem['order']);
      }
      orderCodeList.add(lastDigits);
    }
    int maxLastDigits = orderCodeList.isNotEmpty
        ? orderCodeList.reduce((a, b) => a > b ? a : b)
        : 0;
    int newLastDigits = maxLastDigits + 1;

    DateTime now = DateTime.now();
    String formattedDate =
        "${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}";

    String newOrderCode =
        '${TokoID.tokoID}$formattedDate${newLastDigits.toString().padLeft(4, '0')}';
    listOrderCode.add(newOrderCode);
    return newOrderCode;
  }

  String formatPrice(int price) {
    var formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    String formattedPrice = formatCurrency.format(price);
    int decimalIndex = formattedPrice.indexOf(',');
    if (decimalIndex != -1) {
      formattedPrice = formattedPrice.substring(0, decimalIndex);
    }
    return formattedPrice;
  }

  void getGrandTotal() {
    totalMenu = 0;

    for (int i = 0; i < selectedMenuItems.length; i++) {
      totalMenu +=
          (selectedMenuItems[i]['jual'] * selectedMenuItems[i]['quantity']);
    }

    setState(() {});
  }

  bool checkEmptyField() {
    if (selectedMenuItems.isEmpty) {
      kosongMessage = 'Data menu belum lengkap';
      return true;
    }

    if (selectedMenuItems.any((item) => item['quantity'] == 0)) {
      kosongMessage = 'Data menu belum lengkap';
      return true;
    }

    return false;
  }

  void validCash() {
    if (bayarCash) {
      if ((totalMenu as int) <= cashBayar) {
        isCashValid = true;
      } else {
        isCashValid = false;
      }
    } else {
      isCashValid = true;
    }
  }

  void updateLaporanData() {
    if (canEdit) {
      for (final menuItem in selectedMenuItems) {
        laporanData['menu'].add(menuItem);
      }
      laporanData['pemasukan external'].add(pembayaranItems.first);
      laporanData['order list'] = listOrderCode;
      LaporanDatabaseHandlerFirestore.instance
          .updateLaporanMenuInFirestore(laporanData, currentDate);
    }
  }

  void updateLaporanDataBackup() {
    if (canEdit) {
      laporanData['menu'] = lastMenuItemsBackup;
      laporanData['pemasukan external'] = pembayaranItemsBackup;
      laporanData['order list'] = listOrderCodeBackup;
      LaporanDatabaseHandlerFirestore.instance
          .updateLaporanMenuInFirestore(laporanData, currentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          print(printState.statePrinter);
          if (checkEmptyField()) {
            if (canEdit && dataLoaded) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Masih Kosong'),
                    content: Text(
                        "$kosongMessage. Pesanan akan dibatalkan jika keluar"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                        child: const Text('Tidak'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (printState.statePrinter == false) {
                            //updateLaporanDataBackup();
                            print('Cancelled order');
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Order Cancelled'),
                              duration: Duration(seconds: 2),
                            ));
                          }
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PembelianMenu(),
                                maintainState: false),
                            (route) => false,
                          );
                          // Code to be executed after the delay
                        },
                        child: const Text('Ya'),
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text(
                      'Pesanan akan dibatalkan. Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the dialog
                      },
                      child: const Text('Tidak'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Save the updated data
                        if (printState.statePrinter == false) {
                          //updateLaporanDataBackup();
                          print('Cancelled order');
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Order Cancelled'),
                            duration: Duration(seconds: 2),
                          ));
                        }
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PembelianMenu(),
                              maintainState: false),
                          (route) => false,
                        );
                        // Code to be executed after the delay
                      },
                      child: const Text('Ya'),
                    ),
                  ],
                );
              },
            );
          }
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Tambah Pesanan'),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PrintStrukPage()),
                    );
                  },
                  icon: Icon(Icons.settings),
                  tooltip: 'Select Printer',
                )
              ],
            ),
            body: (dataLoaded == false)
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Loading data',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ListView(
                        children: [
                          // Tanggal
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(16),
                            child: ListTile(
                              title: const Text(
                                'Tanggal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                tanggal,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          // Toko Nama
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(16),
                            child: ListTile(
                              title: const Text(
                                'Toko',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                tokoNama,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          // Order Code
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(16),
                            child: ListTile(
                              title: const Text(
                                'Order No',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                codeOrder.substring(codeOrder.length - 4),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          // Menu Terjual
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Order Menu',
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
                                    int quantity = menu['quantity'] ?? 0;
                                    selectedMenuItems[index]['order'] =
                                        codeOrder;
                                    selectedMenuItems[index]['status'] = 'cook';
                                    return Card(
                                      child: ListTile(
                                        title: Text(menu['name']),
                                        subtitle:
                                            Text(formatPrice(menu['jual'])),
                                        trailing: SizedBox(
                                          width: 60,
                                          child: TextFormField(
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            initialValue: '$quantity',
                                            enabled: (canEdit && dataLoaded),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.all(8),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                menu['quantity'] =
                                                    int.tryParse(value) ?? 0;
                                                getGrandTotal();
                                                validCash();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                (canEdit && dataLoaded)
                                    ? ElevatedButton(
                                        onPressed: navigateToSelectMenuScreen,
                                        child: const Icon(Icons.add),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          // Jenis Pembayaran
                          Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Jenis Pembayaran',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: pembayaranItems.length,
                                  itemBuilder: (context, index) {
                                    final pemasukan = pembayaranItems[index] ??
                                        {}; // Initialize with an empty map if null

                                    if (pemasukan['type'] == null) {
                                      pemasukan['type'] =
                                          jenisPembayaranList[0];
                                    }

                                    if (jenisPembayaranList.any((element) =>
                                            element == pemasukan['type']) ==
                                        false) {
                                      jenisPembayaranList
                                          .add(pemasukan['type']);
                                    }

                                    pembayaranItems[index]['status'] =
                                        'ongoing';

                                    pembayaranItems[index]['print'] = 0;

                                    pembayaranItems[index]['type'] =
                                        pemasukan['type'];

                                    pembayaranItems[index]['jumlah'] =
                                        totalMenu as int;

                                    final TextEditingController
                                        _typePemasukanController =
                                        TextEditingController(
                                            text: pemasukan['type'] ??
                                                jenisPembayaranList[0]);

                                    validCash();
                                    return Card(
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child:
                                                DropdownButtonFormField<String>(
                                              value:
                                                  _typePemasukanController.text,
                                              items: jenisPembayaranList
                                                  .map((option) {
                                                return DropdownMenuItem<String>(
                                                  value: option,
                                                  enabled:
                                                      (canEdit && dataLoaded),
                                                  child: Text(option),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                cashBayar = totalMenu as int;
                                                bayarCash = false;
                                                if (value == 'Cash') {
                                                  bayarCash = true;
                                                } else {
                                                  bayarCash = false;
                                                  pembayaranItems[index]
                                                          ['jumlah'] =
                                                      totalMenu as int;
                                                }
                                                pemasukan['type'] = value!;
                                                pembayaranItems[index]['type'] =
                                                    pemasukan['type'];

                                                validCash();
                                                setState(() {});
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Tipe',
                                              ),
                                            ),
                                          ),
                                          (pembayaranItems[index]['type'] ==
                                                  'Cash')
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: TextFormField(
                                                    enabled: canEdit,
                                                    autofocus: true,
                                                    initialValue:
                                                        totalMenu.toString(),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly,
                                                    ],
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText:
                                                          'Total Uang (Rupiah)',
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (value) {
                                                      cashBayar =
                                                          int.tryParse(value) ??
                                                              0;
                                                      bayarCash = true;
                                                      pembayaranItems[index]
                                                              ['jumlah'] =
                                                          totalMenu as int;

                                                      validCash();

                                                      setState(() {});
                                                    },
                                                  ),
                                                )
                                              : SizedBox.shrink(),
                                          (canEdit && dataLoaded)
                                              ? IconButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      pembayaranItems
                                                          .removeAt(index);
                                                      validCash();
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.delete_forever),
                                                )
                                              : SizedBox.shrink(),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                (canEdit &&
                                        dataLoaded &&
                                        selectedMenuItems.isNotEmpty &&
                                        pembayaranItems.isEmpty)
                                    ? ElevatedButton(
                                        onPressed: () async {
                                          pembayaranItems.add({
                                            'type': jenisPembayaranList.first,
                                            'order': codeOrder,
                                            'jumlah': 0,
                                            'time': DateFormat('HH:mm:ss')
                                                .format(DateTime.now()),
                                          });
                                          bayarCash = false;
                                          validCash();
                                          setState(() {});
                                        },
                                        child: const Icon(Icons.add),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 100,
                          )
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Card(
                          elevation: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Total
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 16,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      formatPrice(totalMenu as int),
                                      style: TextStyle(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 16,
                                  ),
                                  // Other content for the docked card
                                ],
                              ),
                              // Kembalian
                              (bayarCash == true)
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            'Kembalian',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            formatPrice(
                                                cashBayar - (totalMenu as int)),
                                            style: TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        // Other content for the docked card
                                      ],
                                    )
                                  : SizedBox.shrink(),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: (pembayaranItems.isNotEmpty &&
                                        selectedMenuItems.isNotEmpty &&
                                        totalMenu != 0 &&
                                        isCashValid)
                                    ? InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Konfirmasi'),
                                                content: (printState
                                                                .printer.name !=
                                                            '' &&
                                                        printState.printer
                                                                .address !=
                                                            '')
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                              'Pesanan akan diproses. Anda yakin?'),
                                                          Text(
                                                              'Printer : ${printState.printer.name}'),
                                                        ],
                                                      )
                                                    : Text(
                                                        'Silahkan pilih printer'),
                                                actions: [
                                                  (printState.printer.name !=
                                                              '' &&
                                                          printState.printer
                                                                  .address !=
                                                              '')
                                                      ? TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context); // Close the dialog
                                                          },
                                                          child: const Text(
                                                              'Tidak'),
                                                        )
                                                      : SizedBox.shrink(),
                                                  TextButton(
                                                    onPressed: () async {
                                                      if (printState.printer
                                                                  .name !=
                                                              '' &&
                                                          printState.printer
                                                                  .address !=
                                                              '') {
                                                        // Save the updated data
                                                        printState.resetState();
                                                        print(
                                                            '--------------------------------------------');
                                                        print(
                                                            '--------------------------------------------');

                                                        await PrintingStruk(
                                                                selectedMenuItems,
                                                                pembayaranItems
                                                                    .first,
                                                                pembayaranItemsBackup,
                                                                lastMenuItemsBackup,
                                                                listOrderCodeBackup,
                                                                tanggal,
                                                                false)
                                                            .printReceipt(
                                                                context);

                                                        Navigator.pop(context);
                                                        // Success
                                                        if (printState
                                                                .statePrinter ==
                                                            true) {
                                                          Future.delayed(
                                                              Duration(
                                                                  seconds: 2),
                                                              () {
                                                            updateLaporanData();

/*
                                                            Navigator
                                                                .pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          PembelianMenu(),
                                                                  maintainState:
                                                                      false),
                                                              (route) => false,
                                                            );
                                                            */
                                                          });
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  SnackBar(
                                                            content: Text(
                                                                'Print Struk'),
                                                            duration: Duration(
                                                                seconds: 4),
                                                          ));

                                                          // Failed
                                                        } else {
                                                          Future.delayed(
                                                              Duration(
                                                                  seconds: 2),
                                                              () {
                                                            //updateLaporanDataBackup();
                                                          });
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  SnackBar(
                                                            content: Text(
                                                                'Printer error!'),
                                                            duration: Duration(
                                                                seconds: 4),
                                                          ));
                                                        }
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  PrintStrukPage(),
                                                              maintainState:
                                                                  false),
                                                        );
                                                      }
                                                      Navigator
                                                          .pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                PembelianMenu(),
                                                            maintainState:
                                                                false),
                                                        (route) => false,
                                                      );
                                                    },
                                                    child: (printState.printer
                                                                    .name !=
                                                                '' &&
                                                            printState.printer
                                                                    .address !=
                                                                '')
                                                        ? Text('Ya')
                                                        : Text('Cari'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Card(
                                          color: Colors.green,
                                          child: Row(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Text(
                                                  'Lanjut',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    : Card(
                                        color: Colors.red,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                'Lanjut',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )));
  }
}
