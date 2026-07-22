import 'dart:convert';

import 'package:http/http.dart' as http;

/// Geocodificação gratuita via Nominatim (OpenStreetMap) — sem chave.
///
/// MOTIVO: os endereços dos pedidos vêm do cadastro/CEP sem coordenadas
/// (lat/lng = 0), então o mapa caía no fallback "sem coordenadas".
/// Este serviço resolve o endereço em (lat, lng) sob demanda, com cache
/// em memória para não repetir consultas.
///
/// Política do Nominatim: máx. 1 req/seg e User-Agent identificado —
/// respeitados abaixo. Para produção em escala, considerar um provedor
/// dedicado (Google Geocoding, Mapbox, LocationIQ).
class GeocodingService {
  GeocodingService._();

  static final Map<String, (double, double)> _cache = {};
  static DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  /// Retorna (lat, lng) para o endereço, ou null se não encontrado.
  static Future<(double, double)?> geocode(String address) async {
    final key = address.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];

    // Rate-limit de cortesia (1 req/seg)
    final since = DateTime.now().difference(_lastRequest);
    if (since.inMilliseconds < 1100) {
      await Future.delayed(
          Duration(milliseconds: 1100 - since.inMilliseconds));
    }
    _lastRequest = DateTime.now();

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'br',
      });
      final resp = await http.get(uri, headers: {
        'User-Agent': 'ServicoFacilApp/1.0 (projeto educacional)',
      }).timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) return null;
      final list = jsonDecode(resp.body) as List<dynamic>;
      if (list.isEmpty) return null;

      final lat = double.tryParse(list.first['lat']?.toString() ?? '');
      final lng = double.tryParse(list.first['lon']?.toString() ?? '');
      if (lat == null || lng == null) return null;

      final result = (lat, lng);
      _cache[key] = result;
      return result;
    } catch (_) {
      return null;
    }
  }
}
