import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../utils/ar_support.dart';
import '../utils/emulator_check.dart';

class ARDemoScreen extends StatefulWidget {
  const ARDemoScreen({super.key});

  @override
  State<ARDemoScreen> createState() => _ARDemoScreenState();
}

class _ARDemoScreenState extends State<ARDemoScreen> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  final List<ARNode> _nodes = [];
  final List<ARPlaneAnchor> _anchors = [];

  String _status = 'Memulakan AR...';
  bool _planesDetected = false;
  int _objectCount = 0;
  bool _isReady = false;
  bool _isEmulator = false;
  ArSupport _arSupport = ArSupport.ready;
  bool _deviceChecked = false;

  @override
  void initState() {
    super.initState();
    _checkIfEmulator();
  }

  Future<void> _checkIfEmulator() async {
    final emulator = await isRunningOnEmulator();
    // The app installs on phones without ARCore, so this screen must not build
    // an ARView there either.
    final support = emulator ? ArSupport.unsupported : await checkArSupport();
    if (mounted) {
      setState(() {
        _isEmulator = emulator;
        _arSupport = support;
        _deviceChecked = true;
      });
    }
  }

  // Asset paths for bundled GLB models (loaded directly from flutter_assets/)
  static const _modelFiles = [
    'assets/models/duck.glb',
    'assets/models/box.glb',
    'assets/models/cesiumtruck.glb',
    'assets/models/lantern.glb',
  ];
  static const _modelNames = ['🦆 Duck', '📦 Box', '🚛 Truck', '🏮 Lantern'];
  int _modelIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (!_deviceChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isEmulator || !_arSupport.canScan) {
      return _buildEmulatorPlaceholder(context);
    }
    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          // Top instruction banner
          Positioned(
            top: 16,
            left: 60,
            right: 12,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isReady
                      ? 'TAP pada permukaan untuk letakkan objek 3D'
                      : 'Sila tunggu — AR sedang dimulakan...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          // Bottom status panel
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusRow('Status', _status, Colors.white),
                  const SizedBox(height: 4),
                  _statusRow('Objek diletak', '$_objectCount', Colors.greenAccent),
                  const SizedBox(height: 4),
                  _statusRow(
                    'Permukaan',
                    _planesDetected ? 'Dikesan ✓' : 'Sedang cari...',
                    _planesDetected ? Colors.greenAccent : Colors.yellowAccent,
                  ),
                  const SizedBox(height: 4),
                  _statusRow(
                    'Model',
                    _modelNames[_modelIndex % _modelNames.length],
                    Colors.cyanAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'cycle',
            onPressed: _cycleModel,
            tooltip: 'Tukar Model',
            backgroundColor: Colors.amber,
            child: const Icon(Icons.swap_horiz, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'clear',
            onPressed: _clearObjects,
            tooltip: 'Padam Semua',
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.delete),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'info',
            onPressed: _showCapabilities,
            tooltip: 'AR Info',
            backgroundColor: const Color(0xFF8B1A1A),
            child: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildEmulatorPlaceholder(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_in_ar, size: 80, color: Colors.white30),
                      const SizedBox(height: 24),
                      const Text(
                        'AR Tidak Disokong',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ciri AR memerlukan peranti fizikal dengan kamera.\n\nSila jalankan aplikasi pada telefon sebenar untuk mengalami AR.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          '🖥️ Emulator dikesan — ARCore tidak tersedia',
                          style: TextStyle(color: Colors.yellowAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    sessionManager.onInitialize(
      showAnimatedGuide: true,
      showPlanes: true,
      showFeaturePoints: false,
      handleTaps: true,
    );

    sessionManager.onPlaneOrPointTap = (List<ARHitTestResult> hits) async {
      if (hits.isNotEmpty) {
        await _placeObject(hits.first);
        if (mounted) setState(() => _planesDetected = true);
      }
    };

    if (mounted) {
      setState(() {
        _status = 'Sedia — gerakkan kamera untuk kesan permukaan';
        _isReady = true;
      });
    }
  }

  Future<void> _placeObject(ARHitTestResult hit) async {
    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await _anchorManager!.addAnchor(anchor);

    if (didAddAnchor ?? false) {
      _anchors.add(anchor);

      final node = ARNode(
        type: NodeType.localGLTF2,
        uri: _modelFiles[_modelIndex % _modelFiles.length],
        scale: vector.Vector3(0.15, 0.15, 0.15),
      );

      final didAddNode = await _objectManager!.addNode(node, planeAnchor: anchor);

      if (didAddNode ?? false) {
        _nodes.add(node);
        if (mounted) {
          setState(() {
            _objectCount++;
            _status = 'Objek berjaya diletakkan!';
          });
        }
      }
    }
  }

  Future<void> _clearObjects() async {
    for (final node in List<ARNode>.from(_nodes)) {
      await _objectManager?.removeNode(node);
    }
    for (final anchor in List<ARPlaneAnchor>.from(_anchors)) {
      await _anchorManager?.removeAnchor(anchor);
    }
    _nodes.clear();
    _anchors.clear();

    if (mounted) {
      setState(() {
        _objectCount = 0;
        _status = 'Semua objek dipadam!';
      });
    }
  }

  void _cycleModel() {
    setState(() {
      _modelIndex = (_modelIndex + 1) % _modelFiles.length;
      _status = 'Model: ${_modelNames[_modelIndex]} — tap untuk letak!';
    });
  }

  void _showCapabilities() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keupayaan AR Flutter'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CapItem('✅ Plane Detection', 'Kesan permukaan mendatar & menegak'),
              _CapItem('✅ 3D Object Placement', 'Letak model GLB/GLTF di ruang AR'),
              _CapItem('✅ Hit Testing', 'Tap permukaan untuk letak objek'),
              _CapItem('✅ Real-time Tracking', 'Jejak objek dalam ruang 3D'),
              _CapItem('✅ Multiple Objects', 'Letak berbilang objek serentak'),
              _CapItem('✅ Object Removal', 'Padam objek secara individu/semua'),
              _CapItem('✅ ARCore (Android)', 'Dikuasakan oleh Google ARCore'),
              _CapItem('✅ ARKit (iOS)', 'Dikuasakan oleh Apple ARKit'),
              SizedBox(height: 12),
              Text(
                'Engine: ar_flutter_plugin v0.7.3',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }
}

class _CapItem extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CapItem(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
