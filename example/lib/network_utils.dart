import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiHeaders {
  static Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  /// Set default headers globally
  static void setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = headers;
  }

  /// Retrieves headers with an option to disable default headers
  static Future<Map<String, String>> getHeaders({
    Map<String, String>? extraHeaders,
    bool useDefaultHeaders = true,
  }) async {
    Map<String, String> headers = useDefaultHeaders
        ? Map<String, String>.from(_defaultHeaders)
        : {}; // If false, use an empty map.

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }
}

/// Callback interface to handle task completion and errors.
abstract class NetworkResponse {
  void onTaskComplete(String result, String caller);
  void onTaskError(String error, String caller);
}

/// Utility class for making network requests.
class NetworkUtils {
  final String url;
  final String caller;
  final NetworkResponse callback;
  final bool useDefaultHeaders; // NEW PARAMETER

  NetworkUtils(this.url, this.caller, this.callback,
      {this.useDefaultHeaders = true});

  Future<void> _makeRequest({
    required String method,
    data,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      var headers = await ApiHeaders.getHeaders(
        extraHeaders: extraHeaders,
        useDefaultHeaders: useDefaultHeaders, // Pass flag
      );
      var uri = Uri.parse(url);
      var body = data != null ? jsonEncode(data) : null;
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: body);
          break;
      }

      _handleResponse(response, method, headers, body);
    } catch (ex) {
      callback.onTaskError(ex.toString(), caller);
    }
  }

  /// Public API calls
  Future<void> get({Map<String, String>? header, Map<String, dynamic>? data}) =>
      _makeRequest(method: 'GET', data: data, extraHeaders: header);

  Future<void> post({data, Map<String, String>? header}) =>
      _makeRequest(method: 'POST', data: data, extraHeaders: header);

  Future<void> put({Map<String, dynamic>? data, Map<String, String>? header}) =>
      _makeRequest(method: 'PUT', data: data, extraHeaders: header);

  Future<void> delete(
          {Map<String, dynamic>? data, Map<String, String>? header}) =>
      _makeRequest(method: 'DELETE', data: data, extraHeaders: header);

  /// ✅ **Multipart Upload Method (FILE UPLOAD)**
  Future<void> multipartPost({
    required String filePath,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      var finalHeaders = await ApiHeaders.getHeaders(
        extraHeaders: headers,
        useDefaultHeaders: useDefaultHeaders, // Respect header setting
      );
      var uri = Uri.parse(url);
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(finalHeaders);
      data?.forEach((key, value) => request.fields[key] = value.toString());
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      _handleResponse(response, 'MULTIPART', finalHeaders, jsonEncode(data));
    } catch (ex) {
      callback.onTaskError(ex.toString(), caller);
    }
  }

  /// Handles API response logging and callback
  void _handleResponse(http.Response response, String method,
      Map<String, String> headers, String? body) {
    log("====> REQUEST LOG");
    log("==>> Method: $method");
    log("==>> URL: $url");
    log("==>> Headers: $headers");
    log("==>> Request Body: ${body ?? '{}'}");

    log("====> RESPONSE LOG");
    log("==>> Status: ${response.statusCode}");
    log("==>> Response Body: ${response.body}");

    if (response.statusCode == 200) {
      callback.onTaskComplete(response.body, caller);
    } else {
      callback.onTaskError(
          "Error ${response.statusCode}: ${response.body}", caller);
    }
  }
}
