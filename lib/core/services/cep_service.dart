import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Resultado da busca de CEP — já no formato usado pelos formulários do app.
class CepResult {
  final String cep;
  final String street;       // logradouro
  final String neighborhood; // bairro
  final String city;         // localidade
  final String state;        // uf
  final double lat;
  final double lng;

  const CepResult({
    required this.cep,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.lat = 0.0,
    this.lng = 0.0,
  });

  factory CepResult.fromViaCep(Map<String, dynamic> json, {double lat = 0, double lng = 0}) {
    return CepResult(
      cep: json['cep'] ?? '',
      street: json['logradouro'] ?? '',
      neighborhood: json['bairro'] ?? '',
      city: json['localidade'] ?? '',
      state: json['uf'] ?? '',
      lat: lat,
      lng: lng,
    );
  }
}

/// Exceção específica para erros de busca de CEP.
class CepException implements Exception {
  final String message;
  const CepException(this.message);
  @override
  String toString() => message;
}

/// CepService — busca endereço a partir do CEP usando a API gratuita ViaCEP,
/// e opcionalmente geocodifica o endereço para lat/lng usando Nominatim
/// (OpenStreetMap), também gratuito e sem necessidade de chave de API.
///
/// Nenhum dos dois serviços requer cadastro, cartão de crédito ou chave paga.
class CepService {
  static const _viaCepBase = 'https://viacep.com.br/ws';
  static const _nominatimBase = 'https://nominatim.openstreetmap.org/search';

  /// Busca o endereço pelo CEP. Lança [CepException] em caso de erro
  /// ou CEP não encontrado.
  Future<CepResult> fetchAddressByCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');

    if (cleanCep.length != 8) {
      throw const CepException('CEP deve conter 8 números.');
    }

    try {
      final response = await http
          .get(Uri.parse('$_viaCepBase/$cleanCep/json/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw const CepException('Erro ao buscar o CEP. Tente novamente.');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['erro'] == true) {
        throw const CepException('CEP não encontrado.');
      }

      var result = CepResult.fromViaCep(data);

      // Tenta obter lat/lng para exibir no mapa e calcular distância depois.
      // Falha silenciosa: se a geocodificação não funcionar, o endereço
      // ainda é preenchido, só sem coordenadas.
      try {
        final coords = await _geocode(result);
        if (coords != null) {
          result = CepResult(
            cep: result.cep,
            street: result.street,
            neighborhood: result.neighborhood,
            city: result.city,
            state: result.state,
            lat: coords.$1,
            lng: coords.$2,
          );
        }
      } catch (e) {
        debugPrint('[CepService] Geocodificação falhou: $e');
      }

      return result;
    } on CepException {
      rethrow;
    } catch (e) {
      throw const CepException('Sem conexão. Verifique sua internet.');
    }
  }

  /// Geocodifica o endereço usando Nominatim (OpenStreetMap) — gratuito.
  /// Retorna (lat, lng) ou null se não encontrar.
  Future<(double, double)?> _geocode(CepResult address) async {
    final query = '${address.street}, ${address.neighborhood}, '
        '${address.city}, ${address.state}, Brasil';

    final uri = Uri.parse(_nominatimBase).replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'br',
    });

    final response = await http.get(
      uri,
      // Nominatim exige um User-Agent identificável (política de uso gratuito)
      headers: {'User-Agent': 'ServicoFacilApp/1.0'},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;

    final results = json.decode(response.body) as List;
    if (results.isEmpty) return null;

    final lat = double.tryParse(results[0]['lat'] ?? '');
    final lng = double.tryParse(results[0]['lon'] ?? '');
    if (lat == null || lng == null) return null;

    return (lat, lng);
  }
}
