class tempSelection {
  static List<Map<String, dynamic>> stokSelectedItem = [];

  static void updateData(dynamic data) {
    stokSelectedItem = data;
  }


  static List<Map<String, dynamic>> getData() {
    return stokSelectedItem;
  }

 
}
