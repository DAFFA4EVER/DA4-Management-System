import 'package:da4_management/analisis/pembukuan_gudang.dart';
import 'package:da4_management/backend/gudangDataHandlerFirestore.dart';
import 'package:flutter/material.dart';

class GudangPembukuanMenuScreen extends StatefulWidget {
  @override
  _GudangPembukuanMenuScreenState createState() =>
      _GudangPembukuanMenuScreenState();
}

class _GudangPembukuanMenuScreenState extends State<GudangPembukuanMenuScreen> {
  late DateTime fromDate;
  late DateTime untilDate;
  bool dataLoaded = false;
  List<String> laporanList = [];
  List<String> availableDate = [];
  List<String> listSelectedDate = [];
  DateTime? selectedFromDate;
  DateTime? selectedUntilDate;

  @override
  void initState() {
    super.initState();
    loadLaporanList();
  }

  Future<void> loadLaporanList() async {
    final tempList = await GudangLaporanDatabaseHandlerFirestore.instance
        .getLaporanGudangList();

    setState(() {
      laporanList = tempList;
      dataLoaded = true;

      for (final item in laporanList) {
        String selectedDate = item.substring(
          item.lastIndexOf("_") + 1,
        );
        availableDate.add(selectedDate);
      }
      fromDate = DateTime.parse(availableDate[0]);
      untilDate = DateTime.parse(availableDate[availableDate.length - 1]);
    });
  }

  bool isDateSelectable(DateTime date) {
    String formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return availableDate.contains(formattedDate);
  }

  void selectDate(String method) async {
    if (method == 'from') {
      selectedFromDate = await showDatePicker(
        context: context,
        initialDate: fromDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        selectableDayPredicate: (DateTime date) {
          String formattedDate =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

          return availableDate.contains(formattedDate);
        },
      );
    } else if (method == 'until') {
      selectedUntilDate = await showDatePicker(
        context: context,
        initialDate: untilDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        selectableDayPredicate: (DateTime date) {
          String formattedDate =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          return availableDate.contains(formattedDate);
        },
      );
    }

    setState(() {
      fromDate = selectedFromDate ?? fromDate;
      untilDate = selectedUntilDate ?? fromDate;
      listSelectedDate.clear();
      for (var date = fromDate;
          date.isBefore(untilDate.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))) {
        String formattedDate =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        listSelectedDate.add(
            formattedDate); //"report_${widget.chooseTokoID}_$formattedDate"
      }
    });
    listSelectedDate.removeWhere((date) => !availableDate.contains(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: dataLoaded
          ? InkWell(
              onTap: () => {
                (listSelectedDate.length != 0)
                    ? Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PembukuanGudangScreen(
                                  chooseTokoID: '',
                                  chooseTokoName: 'Mixue',
                                  listDate: listSelectedDate,
                                )))
                    : null
              },
              child: Card(
                color: Theme.of(context).primaryColor,
                elevation: 2,
                margin: const EdgeInsets.all(4),
                child: ListTile(
                  title: Text(
                    'Mulai',
                    textAlign: TextAlign.center,
                    style: (Theme.of(context).brightness == Brightness.dark)
                        ? TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)
                        : TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                  ),
                  subtitle: Text(
                    'Proses Pembukuan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            )
          : Text(''),
      appBar: AppBar(
        title: Text('Pilih Periode Pembukuan'),
      ),
      body: dataLoaded
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Card(
                  elevation: 2,
                  margin: EdgeInsets.all(4),
                  child: ListTile(
                    title: Text(
                      'Jenis Pembukuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Laporan Gudang Mixue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Tanggal
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          selectDate('from');
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            trailing: Icon(Icons.edit),
                            title: const Text(
                              'Dari\nTanggal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${fromDate.day}-${fromDate.month}-${fromDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: InkWell(
                        onTap: () {
                          selectDate('until');
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            trailing: Icon(Icons.edit),
                            title: const Text(
                              'Sampai\nTanggal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${untilDate.day}-${untilDate.month}-${untilDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.all(4),
                  child: ListTile(
                    title: const Text(
                      'Durasi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${listSelectedDate.length} Hari',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
