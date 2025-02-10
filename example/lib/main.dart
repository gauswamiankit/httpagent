// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
// import 'package:httpagent/httpagent.dart';
import 'network_utils.dart';

void main() {
  // Set default headers globally (Runs before app starts)
  ApiHeaders.setDefaultHeaders({
    'Accept': 'application/json',
    'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
  });

  // runApp(const MyApp());
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> implements NetworkResponse {
  @override
  void onTaskComplete(String result, String caller) {
    print("✅ Success ($caller) :: $result");
  }

  @override
  void onTaskError(String error, String caller) {
    print("❌ Error ($caller) :: $error");
  }

  // 📌 GET Request with Default Headers
  Future<void> getData() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users",
      'getData',
      this,
      useDefaultHeaders: true, // Using global headers
    );

    await task.get();
  }

  // 📌 GET Request with Extra Headers (Overrides Defaults)
  Future<void> getDataWithHeaders() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users",
      'getDataWithHeaders',
      this,
      useDefaultHeaders: true, // Use default headers
    );

    await task.get(header: {
      'Custom-Header': 'MyCustomValue', // Extra header added
    });
  }

  // 📌 POST Request with Default Headers
  Future<void> postData() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users",
      'postData',
      this,
    );

    await task.post(data: {'name': 'John Doe', 'email': 'john@example.com'});
  }

  // 📌 POST Request with Extra Headers
  Future<void> postDataWithHeaders() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users",
      'postDataWithHeaders',
      this,
      useDefaultHeaders:
          false, // Ignore global headers and use only custom ones
    );

    await task.post(
      data: {'name': 'John Doe', 'email': 'john@example.com'},
      header: {
        'Custom-Header': 'PostRequestValue',
        'Authorization': 'Bearer CUSTOM_ACCESS_TOKEN',
      },
    );
  }

  // 📌 PUT Request Example (Using Default Headers)
  Future<void> putData() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users/1",
      'putData',
      this,
    );

    await task.put(data: {'name': 'Updated Name'});
  }

  // 📌 PUT Request with Extra Headers
  Future<void> putDataWithHeaders() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users/1",
      'putDataWithHeaders',
      this,
      useDefaultHeaders: true, // Use default headers and merge extra headers
    );

    await task.put(
      data: {'name': 'Updated Name'},
      header: {'Another-Custom-Header': 'UpdatedValue'},
    );
  }

  // 📌 DELETE Request Example (Using Default Headers)
  Future<void> deleteData() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users/1",
      'deleteData',
      this,
    );

    await task.delete();
  }

  // 📌 DELETE Request with Extra Headers
  Future<void> deleteDataWithHeaders() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/users/1",
      'deleteDataWithHeaders',
      this,
      useDefaultHeaders: false, // Ignore default headers
    );

    await task.delete(header: {
      'Authorization': 'Bearer CUSTOM_DELETE_TOKEN',
    });
  }

  // 📌 Multipart File Upload with Custom Headers
  Future<void> uploadFileWithHeaders() async {
    NetworkUtils task = NetworkUtils(
      "https://example.com/api/upload",
      'uploadFile',
      this,
      useDefaultHeaders: true,
    );

    await task.multipartPost(
      data: {'description': 'File Upload'},
      filePath: '/path/to/file.jpg',
      headers: {
        'File-Token': 'SecureUpload123',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("API Requests Example")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
                onPressed: getData,
                child: const Text("🔄 Fetch Data (Default Headers)")),
            ElevatedButton(
                onPressed: getDataWithHeaders,
                child: const Text("🆕 Fetch Data (Extra Headers)")),
            ElevatedButton(
                onPressed: postData,
                child: const Text("📤 Send Data (Default Headers)")),
            ElevatedButton(
                onPressed: postDataWithHeaders,
                child: const Text("📤 Send Data (Extra Headers)")),
            ElevatedButton(
                onPressed: putData,
                child: const Text("✏️ Update Data (Default Headers)")),
            ElevatedButton(
                onPressed: putDataWithHeaders,
                child: const Text("✏️ Update Data (Extra Headers)")),
            ElevatedButton(
                onPressed: deleteData,
                child: const Text("🗑️ Delete Data (Default Headers)")),
            ElevatedButton(
                onPressed: deleteDataWithHeaders,
                child: const Text("🗑️ Delete Data (Extra Headers)")),
            ElevatedButton(
                onPressed: uploadFileWithHeaders,
                child: const Text("📎 Upload File (Extra Headers)")),
          ],
        ),
      ),
    );
  }
}
