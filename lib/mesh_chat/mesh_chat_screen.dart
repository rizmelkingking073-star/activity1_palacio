import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'mesh_models.dart';
import 'mesh_service.dart';

/// Entry point: push this route from your dashboard.
/// It owns its own MeshService so nothing leaks when you leave the screen.
class MeshChatScreen extends StatelessWidget {
  const MeshChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeshService(),
      child: const _MeshChatView(),
    );
  }
}

/// Pure function of MeshService state: UI = f(state).
class _MeshChatView extends StatefulWidget {
  const _MeshChatView();

  @override
  State<_MeshChatView> createState() => _MeshChatViewState();
}

class _MeshChatViewState extends State<_MeshChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(MeshService s) {
    s.sendText(_input.text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<MeshService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Mesh Chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(Icons.hub, size: 16, color: s.connected.isEmpty ? Colors.grey : Colors.green),
              label: Text('${s.connected.length} linked'),
            ),
          ),
        ],
      ),
      body: switch (s.status) {
        MeshStatus.idle || MeshStatus.error => _StartPanel(service: s),
        MeshStatus.starting => const Center(child: CircularProgressIndicator()),
        MeshStatus.running => Column(
            children: [
              _PeersPanel(service: s),
              const Divider(height: 1),
              Expanded(child: _MessageList(service: s, controller: _scroll)),
              _Composer(controller: _input, enabled: s.connected.isNotEmpty, onSend: () => _send(s)),
            ],
          ),
      },
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({required this.service});
  final MeshService service;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering, size: 72),
            const SizedBox(height: 12),
            const Text('Chat with nearby devices — no internet, no server.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: service.userName,
              decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder()),
              onChanged: (v) => service.userName = v.trim().isEmpty ? service.userName : v.trim(),
            ),
            if (service.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(service.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: service.start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start broadcasting & scanning'),
            ),
            TextButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open app permission settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeersPanel extends StatelessWidget {
  const _PeersPanel({required this.service});
  final MeshService service;

  @override
  Widget build(BuildContext context) {
    final pending = service.pending;
    final nearby = service.discovered;
    final linked = service.connected;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.34),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        children: [
          // Handshake: both users compare the code, then approve.
          for (final p in pending)
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text('${p.name} wants to pair'),
                subtitle: Text('Verify this code matches on both phones:\n${p.authCode ?? '----'}'),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => service.reject(p)),
                  IconButton(icon: const Icon(Icons.check), onPressed: () => service.approve(p)),
                ]),
              ),
            ),
          for (final p in nearby)
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone_android),
              title: Text(p.name),
              subtitle: Text(switch (p.state) {
                PeerState.connecting => 'Connecting…',
                PeerState.failed => 'Failed / rejected — tap to retry',
                _ => 'In range',
              }),
              trailing: p.state == PeerState.connecting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: () => service.connectTo(p), child: const Text('Connect')),
            ),
          for (final p in linked)
            ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(p.name),
              subtitle: const Text('Connected (encrypted)'),
              trailing: IconButton(icon: const Icon(Icons.link_off), onPressed: () => service.disconnect(p)),
            ),
          if (pending.isEmpty && nearby.isEmpty && linked.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Scanning for nearby devices…'),
              ]),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: service.stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop mesh'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.service, required this.controller});
  final MeshService service;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final msgs = service.messages;
    if (msgs.isEmpty) return const Center(child: Text('No messages yet'));
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(12),
      itemCount: msgs.length,
      itemBuilder: (_, i) => _Bubble(msg: msgs[i]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final MeshMessage msg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(child: Text(msg.text, style: Theme.of(context).textTheme.bodySmall)),
      );
    }

    final time = TimeOfDay.fromDateTime(msg.timestamp).format(context);
    final hopInfo = msg.hops > 0 ? ' · ${msg.hops} hop${msg.hops > 1 ? 's' : ''}' : '';

    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: msg.isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMine)
              Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(msg.text),
            Text('$time$hopInfo', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.enabled, required this.onSend});
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: enabled ? 'Message the mesh…' : 'Connect to a device to chat',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton(onPressed: enabled ? onSend : null, icon: const Icon(Icons.send)),
        ]),
      ),
    );
  }
}