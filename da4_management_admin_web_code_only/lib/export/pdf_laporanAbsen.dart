import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'dart:typed_data';

class AbsenItem {
  final String nama;
  final String shift;
  final String tanggal;
  final String masuk;
  final String keluar;
  final String keterangan;

  AbsenItem(
    this.nama,
    this.shift,
    this.tanggal,
    this.masuk,
    this.keluar,
    this.keterangan,
  );
}

class PembukuanAbsenPDFScreen {
  final List<dynamic> listAbsenData;
  final List<dynamic> listDate;
  //final List<dynamic> tempCashLaporanData;

  final String chooseTokoID;
  final String chooseTokoName;

  PembukuanAbsenPDFScreen({
    required this.chooseTokoID,
    required this.chooseTokoName,
    required this.listAbsenData,
    required this.listDate,
  });

  void createPdfAndPrint() {
    final absenItems = listAbsenData.map((item) {
      return AbsenItem(item['nama'], item['shift'], item['tanggal'],
          item['masuk'], item['keluar'], item['keterangan']);
    }).toList();

    final pdf = pw.Document();

    String lastTanggal = ''; // Variable to store the last tanggal value

    pdf.addPage(
      pw.MultiPage(
        build: (context) => <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Column(
              children: [
                pw.Text('Laporan Rekap Absen ${chooseTokoName}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.Text(
                  'Periode (${listDate[0]}) - (${listDate[listDate.length - 1]})',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          pw.Header(level: 1, child: pw.Text('Absensi')),
          pw.Table.fromTextArray(
            context: context,
            data: <List<String>>[
              <String>[
                'Tanggal',
                'Nama',
                'Shift',
                'Masuk',
                'Keluar',
                'Keterangan'
              ],
              ...absenItems.map((item) {
                // Check if the current "tanggal" is different from the last one
                bool isDifferentTanggal = item.tanggal != lastTanggal;

                // Update the last "tanggal" value to the current one
                lastTanggal = item.tanggal;

                // Create a list containing the row data with or without the separator
                List<String> rowData = [
                  isDifferentTanggal
                      ? item.tanggal
                      : '', // Add an empty cell for the repeated "tanggal"
                  item.nama,
                  item.shift,
                  item.masuk,
                  item.keluar,
                  item.keterangan,
                ];

                return rowData;
              }),
            ],
          ),
        ],
      ),
    );
    printPdf(pdf);
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

  Future<void> printPdf(pw.Document pdf) async {
    // Generate the PDF data
    Uint8List pdfData = await pdf.save();

    // Create a blob with the PDF data and get its URL
    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element and click it to start the download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'pembukuan_rekap_absen_${chooseTokoID}_${listDate[0]}_${listDate[listDate.length - 1]}.pdf')
      ..click();
  }
}
