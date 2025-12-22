import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const Duration _timeout = Duration(seconds: 10);
  
  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$baseCurrency'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Support both old and new response shapes:
        // New: { base_code, conversion_rates, time_last_update_utc }
        // Old: { base, rates, date }
        Map<String, dynamic> ratesMap = {};
        String base = baseCurrency;
        String? date;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('conversion_rates')) {
            ratesMap = Map<String, dynamic>.from(data['conversion_rates']);
            base = data['base_code'] ?? baseCurrency;
            date = data['time_last_update_utc'] ?? data['time_last_update_unix']?.toString();
          } else if (data.containsKey('rates')) {
            ratesMap = Map<String, dynamic>.from(data['rates']);
            base = data['base'] ?? baseCurrency;
            date = data['date'] ?? data['time_last_update_utc'];
          }
        }

        return {
          'success': true,
          'base': base,
          'rates': ratesMap,
          'date': date,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch exchange rates: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  Future<double> convertCurrency(double amount, String from, String to) async {
    try {
      final rates = await getExchangeRates(from);
      if (rates['success'] == true) {
        final rateMap = rates['rates'] as Map<String, dynamic>;
        final dynamic rawRate = rateMap[to];
        double rate;
        if (rawRate == null) {
          rate = 1.0;
        } else if (rawRate is int) {
          rate = rawRate.toDouble();
        } else if (rawRate is double) {
          rate = rawRate;
        } else if (rawRate is String) {
          rate = double.tryParse(rawRate) ?? 1.0;
        } else {
          rate = 1.0;
        }

        return amount * rate;
      }
      return amount;
    } catch (e) {
      return amount;
    }
  }
  
  Future<Map<String, dynamic>> getCurrencyList() async {
    // Return static list of popular currencies
    return {
      'success': true,
      'currencies': {
        'IDR': 'Indonesian Rupiah',
        'USD': 'US Dollar',
        'EUR': 'Euro',
        'GBP': 'British Pound',
        'JPY': 'Japanese Yen',
        'SGD': 'Singapore Dollar',
        'MYR': 'Malaysian Ringgit',
        'AUD': 'Australian Dollar',
        'CNY': 'Chinese Yuan',
      },
    };
  }
}