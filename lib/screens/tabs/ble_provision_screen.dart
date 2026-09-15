import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const String _serviceUUID = "12345678-1234-1234-1234-123456789abc";
const String _ssidUUID    = "12345678-1234-1234-1234-123456789001";
const String _passUUID    = "12345678-1234-1234-1234-123456789002";
const String _statusUUID  = "12345678-1234-1234-1234-123456789003";

class BleProvisionScreen extends StatefulWidget {
  const BleProvisionScreen({super.key});
  @override
  State<BleProvisionScreen> createState() => _BleProvisionScreenState();
}

class _BleProvisionScreenState extends State<BleProvisionScreen> {
  final _ssidCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _passVisible = ValueNotifier(false);

  String  _status      = "Tap scan to find your AETHER device.";
  bool    _scanning    = false;
  bool    _connected   = false;
  bool    _sending     = false;

  BluetoothDevice?         _device;
  BluetoothCharacteristic? _ssidChar;
  BluetoothCharacteristic? _passChar;
  BluetoothCharacteristic? _statusChar;

  @override
  void dispose() {
    _device?.disconnect();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _passVisible.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _scan() async {
    await _requestPermissions();
    setState(() { _scanning = true; _status = "Scanning for AETHER_SETUP..."; });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));

    FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.device.platformName == "AETHER_SETUP") {
          await FlutterBluePlus.stopScan();
          setState(() { _scanning = false; _status = "Found device. Connecting..."; });
          await _connect(r.device);
          return;
        }
      }
    });

    // Timeout fallback
    Future.delayed(const Duration(seconds: 13), () {
      if (_scanning) {
        setState(() { _scanning = false; _status = "No device found. Is AETHER powered on?"; });
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect(timeout: const Duration(seconds: 10));
      final services = await device.discoverServices();

      for (final svc in services) {
        if (svc.uuid.toString() == _serviceUUID) {
          for (final c in svc.characteristics) {
            final u = c.uuid.toString();
            if (u == _ssidUUID)   _ssidChar   = c;
            if (u == _passUUID)   _passChar    = c;
            if (u == _statusUUID) _statusChar  = c;
          }
        }
      }

      // Listen for ESP32 status notifications
      if (_statusChar != null) {
        await _statusChar!.setNotifyValue(true);
        _statusChar!.onValueReceived.listen((val) {
          final s = utf8.decode(val);
          setState(() => _status = "Device: $s");
          if (s == "SUCCESS") {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("AETHER connected to WiFi successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }

      setState(() { _connected = true; _status = "Connected. Enter your WiFi details below."; });
    } catch (e) {
      setState(() => _status = "Connection error: $e");
    }
  }

  Future<void> _send() async {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text;

    if (ssid.isEmpty || pass.isEmpty) {
      setState(() => _status = "Please fill in both fields.");
      return;
    }
    if (_ssidChar == null || _passChar == null) {
      setState(() => _status = "Not connected to device.");
      return;
    }

    setState(() { _sending = true; _status = "Sending credentials..."; });

    try {
      await _ssidChar!.write(utf8.encode(ssid), withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 400));
      await _passChar!.write(utf8.encode(pass), withoutResponse: false);
      setState(() => _status = "Sent. Waiting for AETHER to connect...");
    } catch (e) {
      setState(() => _status = "Send failed: $e");
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup AETHER Device")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Status banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _connected ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _connected ? Colors.green : Colors.blue,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _connected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
                    color: _connected ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_status, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Scan button
            ElevatedButton.icon(
              onPressed: (_scanning || _connected) ? null : _scan,
              icon: _scanning
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_scanning
                  ? "Scanning..."
                  : _connected
                      ? "Connected to AETHER ✓"
                      : "Scan for AETHER Device"),
            ),

            const SizedBox(height: 28),

            if (_connected) ...[
              const Text(
                "Enter your WiFi network details:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 14),

              // SSID field
              TextField(
                controller: _ssidCtrl,
                decoration: const InputDecoration(
                  labelText: "WiFi Network Name (SSID)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                ),
              ),
              const SizedBox(height: 14),

              // Password field
              ValueListenableBuilder<bool>(
                valueListenable: _passVisible,
                builder: (_, visible, __) => TextField(
                  controller: _passCtrl,
                  obscureText: !visible,
                  decoration: InputDecoration(
                    labelText: "WiFi Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => _passVisible.value = !visible,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Send button
              ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_sending ? "Sending..." : "Send to AETHER"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}