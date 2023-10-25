import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'dart:typed_data';

class StockItem {
  final String id;
  final String nama;
  final int qty;
  final String unit;
  final int quantity;
  final int price;

  StockItem(this.id, this.nama, this.qty, this.unit, this.quantity, this.price);
}

class BayarItem {
  final String nama;
  final String photoLink;
  final String tanggal;
  final int jumlah;

  BayarItem(
    this.nama,
    this.photoLink,
    this.tanggal,
    this.jumlah,
  );
}

class PembukuanGudangPDFScreen {
  //List<dynamic> listStockGudangData = [];
  List<dynamic> listFirstStockGudangData = [];
  List<dynamic> listCurrentStockGudangData = [];
  List<dynamic> listMasukGudangData = [];
  List<dynamic> listKeluarGudangData = [];
  List<dynamic> listBayarGudangData = [];
  List<dynamic> listSOGudangData = [];
  final List<dynamic> listDate;
  //final List<dynamic> tempCashLaporanData;

  final String chooseTokoID;
  final String chooseTokoName;

  int totalBayarGudangData = 0;
  int totalSOGudangData = 0;

  PembukuanGudangPDFScreen({
    required this.chooseTokoID,
    required this.chooseTokoName,
    //required this.listStockGudangData,
    required this.listFirstStockGudangData,
    required this.listCurrentStockGudangData,
    required this.listMasukGudangData,
    required this.listKeluarGudangData,
    required this.listBayarGudangData,
    required this.listSOGudangData,
    required this.totalBayarGudangData,
    required this.totalSOGudangData,
    required this.listDate,
  });

  void createPdfAndPrint() {
    final soItem = listSOGudangData.map((item) {
      return BayarItem(
        item['nama'],
        item['firestorage'],
        item['tanggal'],
        item['jumlah'],
      );
    }).toList();
    final bayarItem = listBayarGudangData.map((item) {
      return BayarItem(
        item['nama'],
        item['firestorage'],
        item['tanggal'],
        item['jumlah'],
      );
    }).toList();

    final firstStockItems = listFirstStockGudangData.map((item) {
      return StockItem(
        item['id'],
        item['nama'],
        item['qty'],
        item['unit'],
        item['quantity'],
        item['price'],
      );
    }).toList();

    final currentStockItems = listCurrentStockGudangData.map((item) {
      return StockItem(
        item['id'],
        item['nama'],
        item['qty'],
        item['unit'],
        item['quantity'],
        item['price'],
      );
    }).toList();

    final masukStockItems = listMasukGudangData.map((item) {
      return StockItem(
        item['id'],
        item['nama'],
        item['qty'],
        item['unit'],
        item['quantity'],
        item['price'],
      );
    }).toList();

    final keluarStockItems = listKeluarGudangData.map((item) {
      return StockItem(
        item['id'],
        item['nama'],
        item['qty'],
        item['unit'],
        item['quantity'],
        item['price'],
      );
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => <pw.Widget>[
          pw.Header(
              level: 0,
              child: pw.Column(children: [
                pw.Text('Laporan Pembukuan Gudang ${chooseTokoName}',
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

          // First Stock
          pw.Header(level: 1, child: pw.Text('Stock Awal')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['ID', 'Nama', 'Price', 'Qty', 'Unit', 'Quantity'],
            ...firstStockItems.map((item) => [
                  item.id,
                  item.nama,
                  formatPrice(item.price),
                  item.qty.toString(),
                  item.unit,
                  item.quantity.toString()
                ]),
          ]),

          // Current Stock
          pw.Header(level: 1, child: pw.Text('Stock Terakhir')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['ID', 'Nama', 'Price', 'Qty', 'Unit', 'Quantity'],
            ...currentStockItems.map((item) => [
                  item.id,
                  item.nama,
                  formatPrice(item.price),
                  item.qty.toString(),
                  item.unit,
                  item.quantity.toString()
                ]),
          ]),

          // Masuk Stock
          pw.Header(level: 1, child: pw.Text('Total Stock Masuk Gudang')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['ID', 'Nama', 'Price', 'Qty', 'Unit', 'Quantity'],
            ...masukStockItems.map((item) => [
                  item.id,
                  item.nama,
                  formatPrice(item.price),
                  item.qty.toString(),
                  item.unit,
                  item.quantity.toString()
                ]),
          ]),

          // Keluar Stock
          pw.Header(level: 1, child: pw.Text('Total Stock Keluar Gudang')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['ID', 'Nama', 'Price', 'Qty', 'Unit', 'Quantity'],
            ...keluarStockItems.map((item) => [
                  item.id,
                  item.nama,
                  formatPrice(item.price),
                  item.qty.toString(),
                  item.unit,
                  item.quantity.toString()
                ]),
          ]),

          // Bukti SO
          pw.Header(level: 1, child: pw.Text('Bukti SO')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Tanggal', 'Nama', 'Jumlah'],
            ...soItem.map(
                (item) => [item.tanggal, item.nama, formatPrice(item.jumlah)]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text('Total Harga SO : ${formatPrice(totalSOGudangData)}'),
          ]),

          // Bayar SO
          pw.Header(level: 1, child: pw.Text('Pembayaran SO')),
          pw.Table.fromTextArray(context: context, data: <List<String>>[
            <String>['Tanggal', 'Nama', 'Jumlah'],
            ...bayarItem.map(
                (item) => [item.tanggal, item.nama, formatPrice(item.jumlah)]),
          ]),
          pw.Column(children: [
            pw.SizedBox(height: 8),
            pw.Text('Total Pembayaran : ${formatPrice(totalSOGudangData)}'),
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
          'pembukuan_gudang_${chooseTokoName}_${listDate[0]}_${listDate[listDate.length - 1]}.pdf')
      ..click();
  }
}
