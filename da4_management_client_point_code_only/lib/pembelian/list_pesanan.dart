import 'package:da4_management_client_point/pembelian/choosePrintStruk.dart';
import 'package:da4_management_client_point/pembelian/pembelian.dart';
import 'package:da4_management_client_point/pembelian/printState.dart';
import 'package:flutter/material.dart';
import '../backend/control.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'package:intl/intl.dart';

class ListPesanan extends StatefulWidget {
  final String currentdate;
  final bool edit;

  ListPesanan({required this.currentdate, required this.edit});

  @override
  State<ListPesanan> createState() => _ListPesananState();
}

class _ListPesananState extends State<ListPesanan> {
  String selectedFilter = 'semua';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController(text: '');
  List<int> searchResult = [];
  List<Map<String, dynamic>> pembayaranItems = [];
  Map<String, dynamic> laporanData = {};
  List<Map<String, dynamic>> listPesanan = [];
  late String currentDate;
  String laporanDate = '';
  late bool canEdit;
  String tokoNama = '';
  bool dataLoaded = false;
  final laporanHelper = LaporanDatabaseHandlerFirestore.instance;
  List<bool> expandMenuList = [];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    if (widget.currentdate == '') {
      currentDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      currentDate = widget.currentdate;
    }

    canEdit = widget.edit;
    laporanDate = currentDate;
    checkLaporanExist();
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

  Future<void> checkLaporanExist() async {
    try {
      dataLoaded = false;
      print('a');
      if (await laporanHelper.checkLaporanExist(currentDate) == false) {
        laporanData = laporanHelper.laporanTemplate(currentDate);
      } else {
        laporanData = await laporanHelper.loadLaporanFromFirestore(currentDate);
      }
      print('b');
      pembayaranItems =
          List<Map<String, dynamic>>.from(laporanData['pemasukan external']);

      searchResult = List.generate(pembayaranItems.length, (index) => index);

      listPesanan = List<Map<String, dynamic>>.from(laporanData['menu']);

      laporanDate = laporanData['date'];

      if (canEdit == true) {
        if (laporanData['uploaded'] == true) {
          canEdit = false;
        }
      }

      dataLoaded = true;
    } catch (e) {
      print(e);
    }

    if (laporanData['namaToko'] == null) {
      laporanData['namaToko'] = TokoID.tokoName;
      laporanData['date'] = currentDate;
      laporanData['cash'] = 0;
    }

    setState(() {
      expandMenuList = List.generate(pembayaranItems.length, (index) => false);
    });
  }

  void updateLaporanData() {
    if (canEdit) {
      laporanData['pemasukan external'] = pembayaranItems;
      LaporanDatabaseHandlerFirestore.instance
          .updateLaporanMenuInFirestore(laporanData, currentDate);
      checkLaporanExist();
    }
  }

  void showPesananList(BuildContext context, String orderName,
      List<Map<String, dynamic>> pesananOrder) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          // Content of the bottom sheet
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Order Code",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        orderName,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      ListView.builder(
                          shrinkWrap: true,
                          itemCount: pesananOrder.length,
                          itemBuilder: (context, index) {
                            String menuName = pesananOrder[index]['name'];
                            int menuHarga = pesananOrder[index]['jual'];
                            int jumlah = pesananOrder[index]['quantity'];

                            String status = pesananOrder[index]['status'];

                            status = status.substring(0, 1).toUpperCase() +
                                status.substring(1);

                            return Container(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menuName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(formatPrice(menuHarga)),
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        jumlah.toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void searchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Pencarian'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: searchController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Code Pesanan'),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'semua';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'semua'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Semua',
                            style: TextStyle(
                                color: (selectedFilter == 'semua')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'ongoing';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'ongoing'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Ongoing',
                            style: TextStyle(
                                color: (selectedFilter == 'ongoing')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'selesai';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'selesai'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Selesai',
                            style: TextStyle(
                                color: (selectedFilter == 'selesai')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'cancel';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'cancel'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: (selectedFilter == 'cancel')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    searchProcess();
                    Navigator.pop(context); // Close the dialog
                    setState(() {});
                  },
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void searchProcess() async {
    dataLoaded = false;
    searchQuery = searchController.text;
    if (selectedFilter == 'semua' && searchQuery != '') {
      searchResult = [];
      for (int i = 0; i < pembayaranItems.length; i++) {
        if (pembayaranItems[i]['order']
            .substring(pembayaranItems[i]['order'].length - 4,
                pembayaranItems[i]['order'].length)
            .contains(searchQuery)) {
          searchResult.add(i);
        }
      }
    } else if (selectedFilter != 'semua' && searchQuery == '') {
      searchResult = [];
      for (int i = 0; i < pembayaranItems.length; i++) {
        if ((pembayaranItems[i]['status']).contains(selectedFilter)) {
          searchResult.add(i);
        }
      }
    } else if (selectedFilter != 'semua' && searchQuery != '') {
      searchResult = [];
      for (int i = 0; i < pembayaranItems.length; i++) {
        if ((pembayaranItems[i]['status']).contains(selectedFilter)) {
          if (pembayaranItems[i]['order']
              .substring(pembayaranItems[i]['order'].length - 4,
                  pembayaranItems[i]['order'].length)
              .contains(searchQuery)) {
            searchResult.add(i);
          }
        }
      }
    } else {
      searchResult = List.generate(pembayaranItems.length, (index) => index);
    }
    dataLoaded = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('List Pesanan'),
          actions: [
            IconButton(
                onPressed: () {
                  searchDialog();
                },
                icon: Icon(Icons.search))
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  (searchResult.isNotEmpty)
                      ? Scrollbar(
                          child: ListView.builder(
                              itemCount: pembayaranItems.length + 1,
                              itemBuilder: (context, index) {
                                if (index == pembayaranItems.length) {
                                  // Check if it's the last item
                                  return Container(
                                      height:
                                          90.0); // Return a container with desired height
                                }
                                final pembayaranData = pembayaranItems[index];
                                final pembayaranIndex = index;
                                String orderCode =
                                    pembayaranItems[index]['order'].substring(
                                        pembayaranItems[index]['order'].length -
                                            4,
                                        pembayaranItems[index]['order'].length);

                                String status =
                                    pembayaranItems[index]['status'];

                                status = status.substring(0, 1).toUpperCase() +
                                    status.substring(1);

                                String metodePembayaran =
                                    pembayaranItems[index]['type'];
                                int totalOrder =
                                    pembayaranItems[index]['jumlah'];

                                List<Map<String, dynamic>> pesanan = listPesanan
                                    .where((element) =>
                                        element['order'] ==
                                        pembayaranItems[index]['order'])
                                    .toList();
                                if (searchResult.contains(index) &&
                                    searchResult.isNotEmpty) {
                                  return Card(
                                      margin: EdgeInsets.all(8),
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                if (status == 'Ongoing')
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                        Icons.restore_outlined),
                                                  )
                                                else if (status == 'Selesai')
                                                  const Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Icon(Icons.done))
                                                else
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                        Icons.cancel_outlined),
                                                  ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    orderCode,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(metodePembayaran,
                                                      style: TextStyle(
                                                          fontSize: 16)),
                                                ),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Text(formatPrice(
                                                        totalOrder))),
                                              ],
                                            ),
                                            ((pembayaranItems[index]
                                                            ['status'] ==
                                                        'ongoing') &&
                                                    (canEdit == true))
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Cancel?',
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Konfirmasi'),
                                                                content:
                                                                    RichText(
                                                                  text:
                                                                      TextSpan(
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                    children: <TextSpan>[
                                                                      TextSpan(
                                                                          text:
                                                                              'Pesanan antrian '),
                                                                      TextSpan(
                                                                        text:
                                                                            orderCode,
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      TextSpan(
                                                                          text:
                                                                              ' cancel?'),
                                                                    ],
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context); // Close the dialog
                                                                    },
                                                                    child: const Text(
                                                                        'Tidak'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      // Save the updated data
                                                                      print(
                                                                          '--------------------------------------------');
                                                                      //updateLaporanData();
                                                                      setState(
                                                                          () {
                                                                        pembayaranItems[index]['status'] =
                                                                            'cancel';
                                                                        pembayaranItems[index]
                                                                            [
                                                                            'action'] = DateFormat(
                                                                                'HH:mm:ss')
                                                                            .format(DateTime.now());
                                                                        updateLaporanData();
                                                                      });
                                                                      print(
                                                                          '--------------------------------------------');
                                                                      Navigator.pop(
                                                                          context); // Close the dialog
                                                                      // Code to be executed after the delay
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            'Ya'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        icon:
                                                            Icon(Icons.cancel),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Selesai?',
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (BuildContext
                                                                    context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Konfirmasi'),
                                                                content:
                                                                    RichText(
                                                                  text:
                                                                      TextSpan(
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            16),
                                                                    children: <TextSpan>[
                                                                      TextSpan(
                                                                          text:
                                                                              'Pesanan antrian '),
                                                                      TextSpan(
                                                                        text:
                                                                            orderCode,
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      TextSpan(
                                                                          text:
                                                                              ' selesai?'),
                                                                    ],
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context); // Close the dialog
                                                                    },
                                                                    child: const Text(
                                                                        'Tidak'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      // Save the updated data
                                                                      print(
                                                                          '--------------------------------------------');
                                                                      //updateLaporanData();
                                                                      setState(
                                                                          () {
                                                                        pembayaranItems[index]['status'] =
                                                                            'selesai';
                                                                        pembayaranItems[index]
                                                                            [
                                                                            'action'] = DateFormat(
                                                                                'HH:mm:ss')
                                                                            .format(DateTime.now());
                                                                        updateLaporanData();
                                                                      });
                                                                      print(
                                                                          '--------------------------------------------');
                                                                      Navigator.pop(
                                                                          context); // Close the dialog
                                                                      // Code to be executed after the delay
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            'Ya'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        icon: Icon(
                                                            Icons.done_all),
                                                      ),
                                                      IconButton(
                                                        onPressed: () async {
                                                          if (printState.printer
                                                                      .name !=
                                                                  '' &&
                                                              printState.printer
                                                                      .address !=
                                                                  '') {
                                                            printState
                                                                .resetState();
                                                            pembayaranItems[
                                                                    pembayaranIndex]
                                                                ['print'] += 1;
                                                            await PrintingStruk(
                                                              pesanan,
                                                              pembayaranData,
                                                              [],
                                                              [],
                                                              [],
                                                              '',
                                                              true,
                                                            ).printReceipt(
                                                                context);
                                                            if (printState
                                                                    .statePrinter ==
                                                                true) {
                                                              Future.delayed(
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                                  () {
                                                                updateLaporanData();
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                content: Text(
                                                                    'Print Struk'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            4),
                                                              ));

                                                              // Failed
                                                            } else {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                content: Text(
                                                                    'Printer error!'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            4),
                                                              ));
                                                            }
                                                          } else {
                                                            Navigator
                                                                .pushReplacement(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          PrintStrukPage(),
                                                                  maintainState:
                                                                      false),
                                                            );
                                                          }
                                                        },
                                                        icon:
                                                            Icon(Icons.receipt),
                                                        tooltip: 'Copy Struk',
                                                      ),
                                                      IconButton(
                                                          tooltip:
                                                              'Lihat Pesanan',
                                                          onPressed: () {
                                                            showPesananList(
                                                                context,
                                                                orderCode,
                                                                pesanan);
                                                          },
                                                          icon: Icon(Icons
                                                              .remove_red_eye))
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () async {
                                                          if (printState.printer
                                                                      .name !=
                                                                  '' &&
                                                              printState.printer
                                                                      .address !=
                                                                  '') {
                                                            printState
                                                                .resetState();
                                                            pembayaranItems[
                                                                    pembayaranIndex]
                                                                ['print'] += 1;
                                                            await PrintingStruk(
                                                              pesanan,
                                                              pembayaranData,
                                                              [],
                                                              [],
                                                              [],
                                                              '',
                                                              true,
                                                            ).printReceipt(
                                                                context);

                                                            if (printState
                                                                    .statePrinter ==
                                                                true) {
                                                              Future.delayed(
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                                  () {
                                                                updateLaporanData();
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                content: Text(
                                                                    'Print Struk'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            4),
                                                              ));

                                                              // Failed
                                                            } else {
                                                              Future.delayed(
                                                                  const Duration(
                                                                      seconds:
                                                                          2),
                                                                  () {
                                                                Navigator.pop(
                                                                    context);
                                                              });
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                content: Text(
                                                                    'Printer error!'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            4),
                                                              ));
                                                            }
                                                          } else {
                                                            Navigator
                                                                .pushReplacement(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          PrintStrukPage(),
                                                                  maintainState:
                                                                      false),
                                                            );
                                                          }
                                                        },
                                                        icon:
                                                            Icon(Icons.receipt),
                                                        tooltip: 'Copy Struk',
                                                      ),
                                                      IconButton(
                                                          tooltip:
                                                              'Lihat Pesanan',
                                                          onPressed: () {
                                                            showPesananList(
                                                                context,
                                                                orderCode,
                                                                pesanan);
                                                          },
                                                          icon: Icon(Icons
                                                              .remove_red_eye))
                                                    ],
                                                  ),
                                          ],
                                        ),
                                      ));
                                } else {
                                  return SizedBox.shrink();
                                }
                              }),
                        )
                      : Center(
                          child: Text(
                            'Tidak tersedia',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(laporanDate),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Total Pesanan",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(pembayaranItems.length.toString()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ));
  }
}
