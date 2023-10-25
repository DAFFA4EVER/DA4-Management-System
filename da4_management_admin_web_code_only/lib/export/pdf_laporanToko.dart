import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'dart:typed_data';

class MenuItem {
  final String id;
  final String nama;
  final String type;
  final int beli;
  final int jual;
  final int qty;

  MenuItem(
    this.id,
    this.nama,
    this.beli,
    this.jual,
    this.qty,
    this.type,
  );
}

class PemasukanItem {
  final String nama;
  final String photoLink;
  final String tanggal;
  final int jumlah;
  final String type;

  PemasukanItem(
    this.nama,
    this.photoLink,
    this.tanggal,
    this.jumlah,
    this.type,
  );
}

class SetorItem {
  final String tanggal;
  final String nama;
  final String bank;
  final String rekening;
  final String photoLink;
  final int jumlah;

  SetorItem(this.tanggal, this.nama, this.bank, this.jumlah, this.rekening,
      this.photoLink);
}

class StrukCashItem {
  final String nama;
  final String photoLink;
  final String tanggal;
  final int cash;
  final int jumlah;

  StrukCashItem(
    this.nama,
    this.photoLink,
    this.tanggal,
    this.cash,
    this.jumlah,
  );
}

class PengeluaranItem {
  final String nama;
  final String photoLink;
  final String tanggal;
  final int jumlah;
  final String type;

  PengeluaranItem(
    this.nama,
    this.photoLink,
    this.tanggal,
    this.jumlah,
    this.type,
  );
}

class PembukuanTokoPDFScreen {
  final List<dynamic> listMenuLaporanData;
  final List<dynamic> listPemasukanLaporanData;
  final List<dynamic> listPengeluaranLaporanData;
  final List<dynamic> listSetorLaporanData;
  final List<dynamic> listStrukCashLaporanData;
  final List<dynamic> listDate;
  //final List<dynamic> tempCashLaporanData;

  final String chooseTokoID;
  final String chooseTokoName;

  final int totalMenuLaporanData;
  final int totalPengeluaranLaporanData;
  final int totalPemasukanLaporanData;
  final int totalCashLaporanData;
  final int setorCashLaporanData;
  final int totalStrukLaporanData;

  PembukuanTokoPDFScreen({
    required this.chooseTokoID,
    required this.chooseTokoName,
    required this.listMenuLaporanData,
    required this.listPemasukanLaporanData,
    required this.listPengeluaranLaporanData,
    required this.listSetorLaporanData,
    required this.listStrukCashLaporanData,
    required this.totalMenuLaporanData,
    required this.totalPengeluaranLaporanData,
    required this.totalPemasukanLaporanData,
    required this.totalCashLaporanData,
    required this.setorCashLaporanData,
    required this.totalStrukLaporanData,
    required this.listDate,
  });

  void createPdfAndPrint() {
    final strukCashItems = listStrukCashLaporanData.map((item) {
      return StrukCashItem(item['nama'], item['firestorage'], item['tanggal'],
          item['cash'], int.parse(item['jumlah']));
    }).toList();

    final pemasukanItems = listPemasukanLaporanData.map((item) {
      return PemasukanItem(item['nama'], item['firestorage'], item['tanggal'],
          item['jumlah'], item['type']);
    }).toList();

    final pengeluaranItems = listPengeluaranLaporanData.map((item) {
      return PengeluaranItem(item['nama'], item['firestorage'], item['tanggal'],
          item['jumlah'], item['type']);
    }).toList();

    final setorItems = listSetorLaporanData.map((item) {
      if (item['jumlah'].runtimeType == int) {
        item['jumlah'] = (item['jumlah']) as int;
      } else {
        item['jumlah'] = int.parse(item['jumlah'].replaceAll(',', '')) as int;
      }
      return SetorItem(
        item['tanggal'],
        item['nama'],
        item['bank'],
        item['jumlah'],
        item['rekening'],
        item['firestorage'],
      );
    }).toList();

    final menuItems = listMenuLaporanData.map((item) {
      return MenuItem(
        item['id'],
        item['name'],
        item['beli'],
        item['jual'],
        item['quantity'],
        item['type'],
      );
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => <pw.Widget>[
          pw.Header(
              level: 0,
              child: pw.Column(children: [
                pw.Text('Laporan Pembukuan ${chooseTokoName}',
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
                    ))
              ])),
          pw.Header(level: 1, child: pw.Text('Menu')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['ID', 'Nama', 'Type', 'Beli', 'Jual', 'Qty'],
            ...menuItems.map((item) => [
                  item.id,
                  item.nama,
                  item.type,
                  formatPrice(item.beli),
                  formatPrice(item.jual),
                  item.qty.toString()
                ]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text('Total Penjualan : ${formatPrice(totalMenuLaporanData)}'),
          ]),

          // Pemasukkan
          pw.Header(level: 1, child: pw.Text('Pemasukan External')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Tanggal', 'Type', 'Jumlah'],
            ...pemasukanItems.map(
                (item) => [item.tanggal, item.type, formatPrice(item.jumlah)]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text(
                'Total Pemasukan External : ${formatPrice(totalPemasukanLaporanData)}'),
          ]),

          // Pengeluaran
          pw.Header(level: 1, child: pw.Text('Pengeluaran')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Tanggal', 'Type', 'Jumlah'],
            ...pengeluaranItems.map(
                (item) => [item.tanggal, item.type, formatPrice(item.jumlah)]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text(
                'Total Pengeluaran : ${formatPrice(totalPengeluaranLaporanData)}'),
          ]),
          // Struk Cash
          pw.Header(level: 1, child: pw.Text('Struk Cash')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Tanggal', 'Nama', 'Jumlah Sesuai Struk', 'Jumlah Cash'],
            ...strukCashItems.map((item) => [
                  item.tanggal,
                  item.nama,
                  formatPrice(item.jumlah),
                  formatPrice(item.cash)
                ]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text(
                'Total Sesuai Struk : ${formatPrice(totalStrukLaporanData)}'),
            pw.SizedBox(height: 8),
            pw.Text('Total Uang Cash : ${formatPrice(totalCashLaporanData)}'),
          ]),
          // Setor
          pw.Header(level: 1, child: pw.Text('Setor')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Tanggal', 'Nama', 'Bank', 'Rekening', 'Jumlah'],
            ...setorItems.map((item) => [
                  item.tanggal,
                  item.nama,
                  item.bank,
                  item.rekening,
                  formatPrice(item.jumlah)
                ]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text('Total Setor : ${formatPrice(setorCashLaporanData)}'),
          ]),
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
          'pembukuan_toko_${chooseTokoID}_${listDate[0]}_${listDate[listDate.length - 1]}.pdf')
      ..click();
  }
}
