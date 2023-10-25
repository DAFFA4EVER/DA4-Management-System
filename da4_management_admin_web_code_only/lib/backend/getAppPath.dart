import 'package:path_provider/path_provider.dart';

class GetAppPath {
  String _applicationPath = '';

  String get applicationPath => _applicationPath;

  Future<void> initializeApplicationPath() async {
    if (_applicationPath.isEmpty) {
      _applicationPath = await _getApplicationPath();
    }
  }

  Future<String> _getApplicationPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      print(directory.path + '/data/');
      return directory.path + '/data/';
    } catch (e) {
      // Handle error
      print('Error getting application path: $e');
      return '';
    }
  }
}