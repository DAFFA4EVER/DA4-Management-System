import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getMenuData() async {
  final DocumentReference menuDocument =
      FirebaseFirestore.instance.collection('menu').doc('menu_data');

  try {
    final DocumentSnapshot menuSnapshot = await menuDocument.get();

    if (menuSnapshot.exists) {
      final Map<String, dynamic> menuData =
          menuSnapshot.data() as Map<String, dynamic>;
      return menuData['data'].cast<Map<String, dynamic>>();
    } else {
      print('Menu document does not exist in Firestore.');
    }
  } catch (e) {
    print('Error retrieving menu data from Firestore: $e');
  }

  return [];
}

Future<List<Map<String, dynamic>>> getStockData() async {
  final DocumentReference stockDocument =
      FirebaseFirestore.instance.collection('stock').doc('stock_data');

  try {
    final DocumentSnapshot stockSnapshot = await stockDocument.get();

    if (stockSnapshot.exists) {
      final Map<String, dynamic> stockData =
          stockSnapshot.data() as Map<String, dynamic>;

      return stockData['data'].cast<Map<String, dynamic>>();
    } else {
      print('Stock document does not exist in Firestore.');
    }
  } catch (e) {
    print('Error retrieving stock data from Firestore: $e');
  }

  return [];
}
