import 'dart:math' as m;

import 'package:copilot_proxy/config.dart';
import 'package:uuid/uuid.dart';

late final Config config;
final random = m.Random();
final uuid = Uuid();
const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';