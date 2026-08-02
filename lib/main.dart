import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const AndroidBikeApp());

class AndroidBikeApp extends StatelessWidget {
  const AndroidBikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AndroidBike',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF67E8A8),
          brightness: Brightness.dark,
        ),
      ),
      home: const BikeHome(),
    );
  }
}

class BikeHome extends StatefulWidget {
  const BikeHome({super.key});

  @override
  State<BikeHome> createState() => _BikeHomeState();
}

class _BikeHomeState extends State<BikeHome> {
  int _selectedIndex = 0;
  Position? _position;
  double _speedKmh = 0;
  String? _locationError;
  StreamSubscription<Position>? _positionStream;
  bool _keepScreenOn = true;

  @override
  void initState() {
    super.initState();
    _startLocation();
  }

  Future<void> _startLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _locationError = 'Ative o GPS para usar o velocímetro.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _locationError = 'Permissão de localização não concedida.');
      return;
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
        _speedKmh = (position.speed < 0 ? 0 : position.speed) * 3.6;
        _locationError = null;
      });
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _goTo(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(onSelect: _goTo, speedKmh: _speedKmh, error: _locationError),
      _MapPage(position: _position),
      const DeliveryPage(),
      const ShortcutsPage(),
      SettingsPage(
        keepScreenOn: _keepScreenOn,
        onKeepScreenOnChanged: (value) => setState(() => _keepScreenOn = value),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('AndroidBike'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: Text('${_speedKmh.toStringAsFixed(0)} km/h')),
          ),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Entregas'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Atalhos'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.onSelect, required this.speedKmh, this.error});
  final ValueChanged<int> onSelect;
  final double speedKmh;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary, width: 7)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(speedKmh.toStringAsFixed(0), style: const TextStyle(fontSize: 82, fontWeight: FontWeight.bold, height: 0.9)),
              const Text('km/h', style: TextStyle(fontSize: 22)),
            ]),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(error!, textAlign: TextAlign.center)),
        const SizedBox(height: 26),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _ActionCard(icon: Icons.map, label: 'Mapa', onTap: () => onSelect(1)),
            _ActionCard(icon: Icons.inventory_2, label: 'Entregas', onTap: () => onSelect(2)),
            _ActionCard(icon: Icons.music_note, label: 'Música', onTap: () => onSelect(3)),
            _ActionCard(icon: Icons.settings, label: 'Ajustes', onTap: () => onSelect(4)),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 34), const SizedBox(height: 7), Text(label)])),
  );
}

class _MapPage extends StatelessWidget {
  const _MapPage({this.position});
  final Position? position;
  @override
  Widget build(BuildContext context) {
    final center = position == null ? const LatLng(-23.5505, -46.6333) : LatLng(position!.latitude, position!.longitude);
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: position == null ? 11 : 16),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.roggia.androidbike'),
        if (position != null) MarkerLayer(markers: [Marker(point: center, width: 56, height: 56, child: const Icon(Icons.directions_bike, size: 40, color: Colors.lightGreenAccent))]),
      ],
    );
  }
}

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});
  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  late final WebViewController _controller;
  int _progress = 0;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onProgress: (value) => setState(() => _progress = value)))
      ..loadRequest(Uri.parse('https://entrega.roggia.com.br/entregador.php'));
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(color: Theme.of(context).colorScheme.secondaryContainer, padding: const EdgeInsets.all(10), child: const Row(children: [Icon(Icons.inventory_2), SizedBox(width: 8), Text('Painel de entregas')])),
    if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
    Expanded(child: WebViewWidget(controller: _controller)),
  ]);
}

class ShortcutsPage extends StatelessWidget {
  const ShortcutsPage({super.key});
  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  }
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Atalhos', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ListTile(leading: const Icon(Icons.music_note), title: const Text('Música'), subtitle: const Text('Abrir seu aplicativo de música'), onTap: () => _open(Uri.parse('https://open.spotify.com'))),
      ListTile(leading: const Icon(Icons.phone), title: const Text('Telefone'), subtitle: const Text('Abrir discador'), onTap: () => _open(Uri.parse('tel:'))),
      ListTile(leading: const Icon(Icons.chat), title: const Text('Mensagens'), subtitle: const Text('Abrir mensagens do celular'), onTap: () => _open(Uri.parse('sms:'))),
      ListTile(leading: const Icon(Icons.chat_bubble), title: const Text('WhatsApp'), subtitle: const Text('Abrir WhatsApp'), onTap: () => _open(Uri.parse('https://wa.me/'))),
    ],
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.keepScreenOn, required this.onKeepScreenOnChanged});
  final bool keepScreenOn;
  final ValueChanged<bool> onKeepScreenOnChanged;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Configurações', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    SwitchListTile(value: keepScreenOn, onChanged: onKeepScreenOnChanged, title: const Text('Manter tela ligada'), subtitle: const Text('Evita a tela apagar durante a pedalada')),
    const ListTile(leading: Icon(Icons.straighten), title: Text('Unidade'), subtitle: Text('Quilômetros por hora (km/h)')),
    const ListTile(leading: Icon(Icons.volume_up), title: Text('Avisos sonoros'), subtitle: Text('Em breve')),
  ]);
}
