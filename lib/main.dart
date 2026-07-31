import 'package:flutter/material.dart';
import 'package:replicaz/app/app.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.init();
  runApp(const ReplicazApp());
}
