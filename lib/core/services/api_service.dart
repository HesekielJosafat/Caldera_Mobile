import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrl = 'http://10.131.121.159:8000/api';
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String baseUrl = 'http://52.221.212.121/api';
  static const String baseUrl = 'http://caldera-resto-pool.duckdns.org/api';

  
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
  
  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({'email': email, 'password': password}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        
        // SKENARIO 1: Login sukses & Sudah OTP (Masuk ke Home)
        if (responseData['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['data']['token']);
          await prefs.setString('user', jsonEncode(responseData['data']['user']));
          
          return {'success': true, 'user': responseData['data']['user']};
        } 
        
        // SKENARIO 2: Login benar, tapi BELUM OTP (Lempar ke halaman OTP)
        else if (responseData['needs_verification'] == true) {
          final prefs = await SharedPreferences.getInstance();
          // Kita TETAP harus simpan tokennya, karena untuk "Kirim Ulang OTP" sistem butuh token
          await prefs.setString('token', responseData['data']['token']);
          await prefs.setString('user', jsonEncode(responseData['data']['user']));
          
          return {
            'success': false, 
            'needs_verification': true, 
            'message': responseData['message']
          };
        }
      } 
      
      // Jika password salah atau user tidak ditemukan
      return {
        'success': false, 
        'message': responseData['message'] ?? 'Login gagal'
      };
      
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // REGISTER
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: jsonEncode(data),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 422) {
      String errorMessage = responseData['message'] ?? 'Validasi gagal';
      if (responseData['errors'] != null) {
        errorMessage = responseData['errors'].values.first[0];
      }
      return {'success': false, 'message': errorMessage};
    }

    if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
      if (responseData['data'] != null && responseData['data']['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', responseData['data']['token']);
        await prefs.setString('user', jsonEncode(responseData['data']['user']));
      }
      return responseData;
    }
    
      return {'success': false, 'message': responseData['message'] ?? 'Gagal register'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==========================================
  // VERIFIKASI OTP (DENGAN UPDATE MEMORI LOKAL)
  // ==========================================
  Future<Map<String, dynamic>> verifyOtp(String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/verify'),
        headers: await _getHeaders(),
        body: jsonEncode({'otp': otp}),
      );
      
      final responseData = jsonDecode(response.body);

      // 👇 INI DIA OBAT PENAWARNYA 👇
      // Jika API membalas sukses, kita WAJIB update memori lokal HP (SharedPreferences)
      if (response.statusCode == 200 && responseData['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final userStr = prefs.getString('user');
        
        if (userStr != null) {
          Map<String, dynamic> userData = jsonDecode(userStr);
          // Ubah status lokal menjadi verified
          userData['otp_verified'] = true;
          userData['email_verified_at'] = DateTime.now().toIso8601String();
          
          // Simpan kembali ke memori HP
          await prefs.setString('user', jsonEncode(userData));
        }
      }

      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Kirim Ulang OTP
  Future<Map<String, dynamic>> resendOtp() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/send'),
        headers: await _getHeaders(), // Menggunakan JWT Token
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==========================================
  // FORGOT PASSWORD
  // ==========================================
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        body: jsonEncode({'email': email}),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json'
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password': newPassword,
          'password_confirmation': confirmPassword
        }),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json'
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
  
  // SISA FUNGSI LAINNYA TETAP UTUH DAN AMAN
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile'), headers: await _getHeaders());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
         final prefs = await SharedPreferences.getInstance();
         if (responseData['user'] != null) {
           await prefs.setString('user', jsonEncode(responseData['user']));
         }
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  Future<List<dynamic>> getMenus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menus'), headers: await _getHeaders());
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createReservation(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reservations'), 
        body: jsonEncode(data), 
        headers: await _getHeaders()
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
           return jsonDecode(response.body);
        } catch(e) {
           return {'success': true, 'message': 'Berhasil (No JSON)'}; 
        }
      } else {
        return {'success': false, 'message': 'Server Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadTablePayment(String bookingCode, Map<String, dynamic> data, File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reservations/$bookingCode/payment'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      data.forEach((key, value) => request.fields[key] = value.toString());
      request.files.add(await http.MultipartFile.fromPath('payment_proof', imageFile.path));
      
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 302) {
        final json = jsonDecode(responseBody);
        String waUrl = json['wa_url'] ?? "https://wa.me/6285272997806";
        return {'success': true, 'wa_url': waUrl};
      }
      
      try {
        final errorJson = jsonDecode(responseBody);
        return {'success': false, 'message': errorJson['message'] ?? 'Upload gagal'};
      } catch (_) {
        return {'success': false, 'message': 'Terjadi kesalahan pada server (Status: ${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  Future<bool> cancelReservation(String bookingCode, {String reason = "Dibatalkan oleh user"}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final response = await http.post(
        Uri.parse('$baseUrl/reservations/$bookingCode/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
         body: jsonEncode({'reason': reason}), 
      );
      
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getReservations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reservations'), headers: await _getHeaders());
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> uploadTicketPayment(String ticketCode, Map<String, dynamic> data, File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/tickets/$ticketCode/payment'));
      
      request.headers['Authorization'] = 'Bearer ${prefs.getString('token')}';
      request.headers['Accept'] = 'application/json';
      
      data.forEach((key, value) => request.fields[key] = value.toString());
      request.files.add(await http.MultipartFile.fromPath('payment_proof', imageFile.path));
      
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      }
      return {'success': false, 'message': 'Upload gagal: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  Future<Map<String, dynamic>> buyTicket(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final response = await http.post(
        Uri.parse('$baseUrl/tickets'), 
        body: jsonEncode(data), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        }
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? 'Gagal memesan tiket'};
        } catch (_) {
          return {'success': false, 'message': 'Server Error: ${response.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<List<dynamic>> getTickets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tickets'), headers: await _getHeaders());
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  Future<List<dynamic>> getPromos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/promos'), headers: await _getHeaders());
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  Future<List<dynamic>> getGallery() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/gallery'), headers: await _getHeaders());
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> submitTestimonial(Map<String, dynamic> data) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/testimonials'), body: jsonEncode(data), headers: await _getHeaders());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  Future<List<dynamic>> getTestimonials() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/testimonials'), headers: await _getHeaders());
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getPoolInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pool/info'), headers: await _getHeaders());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  
  Future<Map<String, dynamic>> checkTableAvailability({required String date, required String time, required int guests}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reservation/check-availability'),
        body: jsonEncode({'reservation_date': date, 'reservation_time': time, 'number_of_guests': guests}),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'notifications': []};
    } catch (e) {
      return {'notifications': []};
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'), 
        headers: await _getHeaders()
      );
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$id/mark-read'), 
        headers: await _getHeaders()
      );
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendFcmTokenToServer(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update-fcm-token'), 
        body: jsonEncode({'fcm_token': token}),
        headers: await _getHeaders(),
      );
    } catch (e) {
      print("Gagal mengirim FCM Token: $e");
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/dashboard'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body)['data'] ?? {});
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<bool> createMenu(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/menus'));
      request.headers['Authorization'] = 'Bearer ${prefs.getString('token')}';
      data.forEach((key, value) => request.fields[key] = value.toString());
      if (imageFile != null) request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) { return false; }
  }

  Future<bool> updateMenu(int id, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/menus/$id'));
      request.headers['Authorization'] = 'Bearer ${prefs.getString('token')}';
      request.fields['_method'] = 'PUT';
      data.forEach((key, value) => request.fields[key] = value.toString());
      if (imageFile != null) request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteMenu(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/menus/$id'), headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> createGallery(Map<String, dynamic> data, File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/gallery'));
      request.headers['Authorization'] = 'Bearer ${prefs.getString('token')}';
      
      data.forEach((key, value) => request.fields[key] = value.toString());
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      var response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) { 
      return false; 
    }
  }

  Future<bool> deleteGallery(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/gallery/$id'), headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<Uint8List?> downloadExportedFile(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${prefs.getString('token')}'},
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print("Error Download: $e");
    }
    return null;
  }
  
  String getExportReservationsUrl() {
    return '$baseUrl/admin/reservations/export';
  }

  Future<bool> deleteTestimonial(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/testimonials/$id'), headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getFacilities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pool/info'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}