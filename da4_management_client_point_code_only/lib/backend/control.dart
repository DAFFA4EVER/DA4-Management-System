import 'package:intl/intl.dart';

class UserList {
  List<Map<String, dynamic>> userList = [
    {
      'username': 'ihsbiasa@gmail.com',
      'role': 'superadmin',
      'name': 'superadmin'
    },
    {
      'username': 'seele.vollerei1234@gmail.com',
      'role': 'pegawai',
      'name': 'user'
    },
    {
      'username': 'dafamixuearwinda@gmail.com',
      'role': 'pegawai',
      'name': 'default'
    }
  ];
}

class loginState {
  static String username = '';
  static String role = '';
  static String dateTime =
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  static void reset() {
    username = '';
    role = '';
    dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }
}

class TokoID {
  static String tokoID = 'MX1002';
  static String tokoName = 'Mixue Point 2';
}
