import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class printState {
  static bool statePrinter = false;
  static BluetoothDevice printer = BluetoothDevice('', '');

  static void resetPrinter() {
    printer = BluetoothDevice('', '');
    print(printer.name);
  }

  static void printerDefault(BluetoothDevice selectedPrinter) {
    printer = selectedPrinter;
    print(printer.name);
  }

  static void resetState() {
    statePrinter = false;
    print(statePrinter);
  }

  static void printingDone() {
    statePrinter = true;
    print(statePrinter);
  }
}
