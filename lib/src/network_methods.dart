// ignore_for_file: avoid_log

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

/// Manages global API headers
class ApiHeaders {
  static Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  /// Sets default headers globally
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
        : {}; // Use an empty map if default headers are disabled.

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }
}

/// A callback interface to handle API responses.
abstract class NetworkResponse {
  /// Called when an API request completes successfully.
  ///
  /// - [result]: The response body as a String.
  /// - [caller]: The identifier for the request.
  void onTaskComplete(String result, String caller);

  /// Called when an API request fails.
  ///
  /// - [error]: The error message.
  /// - [caller]: The identifier for the request.
  void onTaskError(String error, String caller);
}

/// A utility class for handling network requests in a structured way.
class NetworkUtils {
  final String url;
  final String caller;
  final NetworkResponse callback;
  final bool useDefaultHeaders;

  /// Creates an instance of NetworkUtils for API handling.
  ///
  /// - [url]: The API endpoint.
  /// - [caller]: The identifier for the request.
  /// - [callback]: The response handler.
  /// - [useDefaultHeaders]: Whether to use default headers.
  NetworkUtils(this.url, this.caller, this.callback,
      {this.useDefaultHeaders = true});

  /// Internal method for making HTTP requests.
  ///
  /// - [method]: The HTTP method (GET, POST, PUT, DELETE).
  /// - [data]: Optional body data.
  /// - [extraHeaders]: Additional headers.
  Future<void> _makeRequest({
    required String method,
    data,
    Map<String, String>? extraHeaders,
  }) async {
    try {
      var headers = await ApiHeaders.getHeaders(
        extraHeaders: extraHeaders,
        useDefaultHeaders: useDefaultHeaders,
      );
      var uri = Uri.parse(url);
      var body = data != null ? jsonEncode(data) : null;
      late http.Response response;

      // Select HTTP method
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
        default:
          throw UnsupportedError("HTTP method not supported: $method");
      }

      _handleResponse(response, method, headers, body);
    } catch (ex) {
      callback.onTaskError(ex.toString(), caller);
    }
  }

  /// Sends a GET request.
  Future<void> get({Map<String, String>? header, Map<String, dynamic>? data}) =>
      _makeRequest(method: 'GET', data: data, extraHeaders: header);

  /// Sends a POST request.
  Future<void> post({data, Map<String, String>? header}) =>
      _makeRequest(method: 'POST', data: data, extraHeaders: header);

  /// Sends a PUT request.
  Future<void> put({Map<String, dynamic>? data, Map<String, String>? header}) =>
      _makeRequest(method: 'PUT', data: data, extraHeaders: header);

  /// Sends a DELETE request.
  Future<void> delete(
          {Map<String, dynamic>? data, Map<String, String>? header}) =>
      _makeRequest(method: 'DELETE', data: data, extraHeaders: header);

  /// Sends a multipart POST request (File Upload).
  ///
  /// - [filePath]: The local file path to upload.
  /// - [data]: Optional form fields.
  /// - [headers]: Optional headers.
  Future<void> multipartPost({
    required String filePath,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      var finalHeaders = await ApiHeaders.getHeaders(
        extraHeaders: headers,
        useDefaultHeaders: useDefaultHeaders,
      );
      var uri = Uri.parse(url);
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(finalHeaders);

      // Add form fields
      data?.forEach((key, value) => request.fields[key] = value.toString());

      // Attach file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response, 'MULTIPART', finalHeaders, jsonEncode(data));
    } catch (ex) {
      callback.onTaskError(ex.toString(), caller);
    }
  }

  /// Handles API response logging and callback execution.
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      callback.onTaskComplete(response.body, caller);
    } else {
      callback.onTaskError(
          "Error ${response.statusCode}: ${response.body}", caller);
    }
  }
}
