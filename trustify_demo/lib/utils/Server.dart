import 'package:http/http.dart' as http;
import 'dart:convert';

//MUST CHANGE THIS
const apiBaseUrl = "http://192.168.1.6:3001/api";

const authenticateUrl = "/authenticate";
const registerUrl = "/registerpasskey";
const newUserUrl = "/newuser";
const synchronizeUrl = "/synchronizepasskey";

Future<Map<String, dynamic>?> synchronizePasskey(
    Map<String, String> queryParameters) async {
  try {
    final synchronize = Uri.parse(apiBaseUrl + synchronizeUrl)
        .replace(queryParameters: queryParameters);

    var response = await http.get(synchronize);
    if (response.statusCode == 200) {
      // Successful response
      final responseBody = jsonDecode(response.body);
      // Process the response data
      if (responseBody['flag']) {
        return responseBody['passkey'];
      }
    } else {
      // Error handling
      return null;
    }
  } catch (error) {
    // Exception handling
    return null;
  }
  return null;
}

Future<bool> newUser(Map<String, String> requestBody) async {
  try {
    final createUser = Uri.parse(apiBaseUrl + newUserUrl);
    var response = await http.post(createUser, body: requestBody);
    if (response.statusCode == 200) {
      // Successful response
      final responseBody = jsonDecode(response.body);
      // Process the response data
      if (responseBody['flag']) {
        return true;
      }
    } else {
      // Error handling
      return false;
    }
  } catch (error) {
    // Exception handling
    return false;
  }
  return false;
}

Future<bool> registerPasskey(Map<String, String> requestBody) async {
  try {
    final register = Uri.parse(apiBaseUrl + registerUrl);
    var response = await http.post(register, body: requestBody);
    if (response.statusCode == 200) {
      // Successful response
      final responseBody = jsonDecode(response.body);
      // Process the response data
      if (responseBody['flag']) {
        return true;
      }
    } else {
      // Error handling
      return false;
    }
  } catch (error) {
    // Exception handling
    return false;
  }
  return false;
}

Future<String?> getChallenge(Map<String, String> queryParameters) async {
  try {
    final getChallenge = Uri.parse(apiBaseUrl + authenticateUrl)
        .replace(queryParameters: queryParameters);

    var response = await http.get(getChallenge);
    if (response.statusCode == 200) {
      // Successful response
      final responseBody = jsonDecode(response.body);
      // Process the response data
      if (responseBody['flag']) {
        return responseBody['challenge'];
      }
    } else {
      // Error handling
      return null;
    }
  } catch (error) {
    // Exception handling
    return null;
  }
  return null;
}

Future<bool> authenticate(Map<String, String> requestBody) async {
  try {
    final authenticate = Uri.parse(apiBaseUrl + authenticateUrl);
    var response = await http.post(authenticate, body: requestBody);
    if (response.statusCode == 200) {
      // Successful response
      final responseBody = jsonDecode(response.body);
      // Process the response data
      if (responseBody['flag']) {
        return true;
      }
    } else {
      // Error handling
      return false;
    }
  } catch (error) {
    // Exception handling
    return false;
  }
  return false;
}
