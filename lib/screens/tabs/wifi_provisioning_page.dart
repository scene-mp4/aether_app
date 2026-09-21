import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esp_provisioning_wifi/esp_provisioning_wifi.dart';

class WifiProvisioningPage extends StatelessWidget {
  final String deviceId;
  final String deviceName;

  const WifiProvisioningPage({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EspProvisioningBloc(),
      child: _WifiProvisioningView(
        deviceId:   deviceId,
        deviceName: deviceName,
      ),
    );
  }
}

class _WifiProvisioningView extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const _WifiProvisioningView({
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<_WifiProvisioningView> createState() => _WifiProvisioningViewState();
}

class _WifiProvisioningViewState extends State<_WifiProvisioningView> {
  // Must match `service_name` on the ESP32 (PROV_<deviceId>).
  late final String _expectedServiceName = 'PROV_${widget.deviceId}';
  // BLE scan prefix — must match how the ESP32 advertises its service name.
  static const String _blePrefix = 'PROV_';
  // Must match the `pop` constant on the ESP32 sketch.
  final TextEditingController _popCtrl =
      TextEditingController(text: 'abcd1234');

  String? _connectedBleDevice;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  void _startScan(BuildContext context) {
    setState(() {
      _statusMessage = 'Scanning for "${widget.deviceName}"…';
      _isError = false;
    });
    context.read<EspProvisioningBloc>().add(
          EspProvisioningEventStart(_blePrefix),
        );
  }

  void _connectToDevice(BuildContext context, String bleDeviceName) {
    setState(() {
      _connectedBleDevice = bleDeviceName;
      _statusMessage = 'Connecting to $bleDeviceName…';
      _isError = false;
    });
    context.read<EspProvisioningBloc>().add(
          EspProvisioningEventBleSelected(bleDeviceName, _popCtrl.text.trim()),
        );
  }

  Future<void> _promptPassphraseAndProvision(
      BuildContext context, String ssid) async {
    final passCtrl = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Connect to "$ssid"'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'WiFi password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, passCtrl.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    passCtrl.dispose();

    if (password == null || !context.mounted) return;

    setState(() {
      _statusMessage = 'Sending WiFi credentials for "$ssid"…';
      _isError = false;
    });

    context.read<EspProvisioningBloc>().add(
          EspProvisioningEventWifiSelected(
            _connectedBleDevice ?? '',
            _popCtrl.text.trim(),
            ssid,
            password,
          ),
        );
  }

  void _onStateChanged(BuildContext context, EspProvisioningState state) {
    switch (state.status) {
      case EspProvisioningStatus.bleScanned:
        setState(() {
          _statusMessage = state.bluetoothDevices.contains(_expectedServiceName)
              ? 'Found "${widget.deviceName}" — tap it to connect.'
              : 'Scan complete. "${widget.deviceName}" was not seen — '
                  'make sure it is powered on and in range.';
          _isError = false;
        });
        break;
      case EspProvisioningStatus.wifiScanned:
        setState(() {
          _statusMessage = 'Choose a WiFi network for "${widget.deviceName}".';
          _isError = false;
        });
        break;
      case EspProvisioningStatus.wifiProvisioned:
        setState(() {
          _isError = !state.wifiProvisioned;
          _statusMessage = state.wifiProvisioned
              ? '"${widget.deviceName}" is connected to WiFi!'
              : 'Provisioning failed. Double check the password and try again.';
        });
        if (state.wifiProvisioned) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
        break;
      case EspProvisioningStatus.error:
        setState(() {
          _isError = true;
          _statusMessage = state.errorMsg.isNotEmpty
              ? state.errorMsg
              : 'Something went wrong (${state.failure.name}).';
        });
        break;
      case EspProvisioningStatus.initial:
      case EspProvisioningStatus.deviceChosen:
      case EspProvisioningStatus.networkChosen:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0052FF),
        foregroundColor: Colors.white,
        title: Text('Connect "${widget.deviceName}"'),
      ),
      body: BlocConsumer<EspProvisioningBloc, EspProvisioningState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.failure != current.failure ||
            previous.errorMsg != current.errorMsg,
        listener: _onStateChanged,
        builder: (context, state) {
          final isBusy = state.status == EspProvisioningStatus.deviceChosen ||
              state.status == EspProvisioningStatus.networkChosen;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Status banner ──────────────────────────────────────────
                if (_statusMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isError
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isBusy) ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _isError
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Proof of possession ────────────────────────────────────
                const Text('Proof of Possession',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                TextField(
                  controller: _popCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Scan button ─────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: isBusy ? null : () => _startScan(context),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('Scan for Tracker'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── BLE devices found ───────────────────────────────────────
                if (state.bluetoothDevices.isNotEmpty) ...[
                  const Text('Nearby Trackers',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  ...state.bluetoothDevices.map((name) {
                    final isExpected = name == _expectedServiceName;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isExpected ? const Color(0xFFEFF6FF) : Colors.white,
                      child: ListTile(
                        leading: Icon(Icons.router,
                            color: isExpected
                                ? const Color(0xFF0052FF)
                                : const Color(0xFF94A3B8)),
                        title: Text(name),
                        subtitle: isExpected
                            ? const Text('This tracker',
                                style: TextStyle(
                                    color: Color(0xFF0052FF),
                                    fontWeight: FontWeight.bold))
                            : null,
                        onTap:
                            isBusy ? null : () => _connectToDevice(context, name),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // ── WiFi networks found ─────────────────────────────────────
                if (state.wifiNetworks.isNotEmpty) ...[
                  const Text('Available WiFi Networks',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  ...state.wifiNetworks.map((network) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.wifi,
                            color: Color(0xFF0052FF)),
                        title: Text(network.ssid),
                        trailing: network.rssi == null
                            ? null
                            : Text('${network.rssi} dBm',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF64748B))),
                        onTap: isBusy
                            ? null
                            : () => _promptPassphraseAndProvision(
                                context, network.ssid),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}