// Synthetic visual fixture only. Production entry point remains lib/main.dart.
import 'package:flutter/material.dart';
import 'package:solar_ops_mobile/main.dart';
import 'package:solar_ops_mobile/app_ui.dart';
import 'package:solar_ops_mobile/app_controller.dart';
import 'package:solar_ops_mobile/models.dart';
import 'package:solar_ops_mobile/session_store.dart';
import 'fixtures.dart';

class PreviewStore extends SessionStore {
  @override
  Future<void> saveCompany(String? id) async {}
}

void main() {
  final c = AppController(store: PreviewStore())
    ..data = BootstrapData.fromJson(sampleData());
  for(final company in c.data!.stock.companies) {
    c.companyProfiles[company.id]={'id':company.id,'name':company.name,'label':company.name,'gstin':company.gstin,'photo':null};
  }
  runApp(SolarOpsApp(home: AppShell(controller: c)));
}
