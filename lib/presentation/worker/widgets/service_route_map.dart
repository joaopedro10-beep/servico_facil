import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mapa da rota prestador → cliente (estilo 99).
///
/// Usa OpenStreetMap via flutter_map — sem necessidade de chave de API.
/// DEPENDÊNCIAS (adicionar no pubspec.yaml):
///   flutter_map: ^7.0.2
///   latlong2: ^0.9.1
///
/// Se o pedido não tiver coordenadas (lat/lng == 0), exiba um fallback na
/// tela chamadora em vez deste widget.
class ServiceRouteMap extends StatefulWidget {
  final double workerLat;
  final double workerLng;
  final double clientLat;
  final double clientLng;
  final bool hasWorkerPosition;
  final Color accentColor;

  const ServiceRouteMap({
    super.key,
    required this.workerLat,
    required this.workerLng,
    required this.clientLat,
    required this.clientLng,
    required this.hasWorkerPosition,
    this.accentColor = const Color(0xFF1D9E75),
  });

  @override
  State<ServiceRouteMap> createState() => _ServiceRouteMapState();
}

class _ServiceRouteMapState extends State<ServiceRouteMap> {
  final _mapController = MapController();
  bool _fittedOnce = false;

  LatLng get _client => LatLng(widget.clientLat, widget.clientLng);
  LatLng get _worker => LatLng(widget.workerLat, widget.workerLng);

  void _fitBounds() {
    if (!widget.hasWorkerPosition) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(_worker, _client),
          padding: const EdgeInsets.fromLTRB(48, 120, 48, 300),
        ),
      );
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant ServiceRouteMap old) {
    super.didUpdateWidget(old);
    if (!_fittedOnce && widget.hasWorkerPosition) {
      _fittedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _client,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.servicoFacil',
        ),

        // Rota (linha reta prestador → cliente; para rota real por ruas,
        // integrar OSRM/Google Directions futuramente)
        if (widget.hasWorkerPosition)
          PolylineLayer(polylines: [
            Polyline(
              points: [_worker, _client],
              strokeWidth: 5,
              color: widget.accentColor.withOpacity(0.85),
            ),
          ]),

        MarkerLayer(markers: [
          // Cliente (destino)
          Marker(
            point: _client,
            width: 46,
            height: 46,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.home_rounded,
                    color: Colors.white, size: 18),
              ),
            ]),
          ),

          // Prestador (posição atual)
          if (widget.hasWorkerPosition)
            Marker(
              point: _worker,
              width: 42,
              height: 42,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
        ]),
      ],
    );
  }
}
