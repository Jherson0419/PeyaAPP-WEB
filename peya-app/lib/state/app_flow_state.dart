import 'package:flutter/widgets.dart';

class AppFlowState extends ChangeNotifier {
  double? _deliveryLat;
  double? _deliveryLng;

  double? get deliveryLat => _deliveryLat;
  double? get deliveryLng => _deliveryLng;
  bool get hasDeliveryLocation => _deliveryLat != null && _deliveryLng != null;

  void setDeliveryLocation({required double lat, required double lng}) {
    _deliveryLat = lat;
    _deliveryLng = lng;
    notifyListeners();
  }
}

class AppFlowScope extends InheritedNotifier<AppFlowState> {
  const AppFlowScope({
    required AppFlowState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static AppFlowState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppFlowScope>();
    assert(scope != null, 'AppFlowScope no encontrado en el arbol.');
    return scope!.notifier!;
  }
}
