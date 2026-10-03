import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/network_diagnostic_state.dart';

class NetworkHealthBadge extends StatelessWidget {
  const NetworkHealthBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final tier = context.watch<NetworkDiagnosticState>().tier;
    final label = tier.name.toUpperCase();
    return Chip(avatar: const Icon(Icons.network_check, size: 16), label: Text(label));
  }
}
