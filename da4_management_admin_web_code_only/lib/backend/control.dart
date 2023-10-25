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
      'role': 'admin',
      'name': 'admin'
    },
    {'username': 'andyaf2504@gmail.com', 'role': 'admin', 'name': 'admin'},
    {
      'username': 'ilhamassidik2017@gmail.com',
      'role': 'admin',
      'name': 'admin'
    },
    {'username': 'maulidamilda57@gmail.com', 'role': 'admin', 'name': 'admin'},
    {'username': 'ihsanprakoso25@gmail.com', 'role': 'admin', 'name': 'admin'}
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
  static List<Map<String, String>> tokoID = [
    {'MX0001': 'Mixue Sukataris'},
    {'MX1001': 'Mixue Point 1'},
    {'MX1002': 'Mixue Point 2'}
  ];
  static bool isTokoIDExists(String id) {
    for (var i = 0; i < tokoID.length; i++) {
      if (tokoID[i].containsKey(id)) {
        return true;
      }
    }
    return false;
  }

  static String findTokoIDName(String id) {
    for (var i = 0; i < tokoID.length; i++) {
      if (tokoID[i].containsKey(id)) {
        return tokoID[i][id].toString();
      }
    }
    return '';
  }
}
