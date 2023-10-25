import 'package:da4_management_client_point/analisis/pembukuan_toko_point.dart';
import 'package:da4_management_client_point/backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/material.dart';
import 'pembukuan_toko.dart';

class TokoPembukuanMenuScreen extends StatefulWidget {
  final String chooseTokoID;
  final String chooseTokoName;
  final bool isPoint;

  TokoPembukuanMenuScreen({
    required this.chooseTokoID,
    required this.chooseTokoName,
    required this.isPoint,
  });

  @override
  _TokoPembukuanMenuScreenState createState() =>
      _TokoPembukuanMenuScreenState();
}

class _TokoPembukuanMenuScreenState extends State<TokoPembukuanMenuScreen> {
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
    final tempList = await LaporanDatabaseHandlerFirestore.instance
        .getLaporanList();

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
              onTap: () {
                if (listSelectedDate.length != 0) {
                  if (widget.isPoint == false) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PembukuanTokoScreen(
                                  chooseTokoID: widget.chooseTokoID,
                                  listDate: listSelectedDate,
                                  chooseTokoName: widget.chooseTokoName,
                                )));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PembukuanTokoPointScreen(
                                  chooseTokoID: widget.chooseTokoID,
                                  listDate: listSelectedDate,
                                  chooseTokoName: widget.chooseTokoName,
                                )));
                  }
                } else {
                  null;
                }
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
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.all(4),
                  child: ListTile(
                    title: const Text(
                      'Jenis Pembukuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Laporan ${widget.chooseTokoName}',
                      style: const TextStyle(fontSize: 16),
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
