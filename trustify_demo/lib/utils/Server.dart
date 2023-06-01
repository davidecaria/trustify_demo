/// This utility file provides a set of methods used to communicate with server and call endpoints to trigger specific functionalities server-side

import 'package:http/http.dart' as http;
import 'dart:convert';

//must change this
const apiBaseUrl = "http://MustChangeThis:3001/api";

const authenticateUrl = "/authenticate";
const registerUrl = "/registerpasskey";
const newUserUrl = "/newuser";
const synchronizeUrl = "/synchronizepasskey";

/// This method allows to call the [synchronizeUrl] endpoint and communicate with the Authentication Server in order to retrieve and locally store
/// a server-side stored [Passkey] by providing the related [Passkey] information information through [queryParameters] object
///
/// Returns a [JSON] object representing the [Passkey] object stored server-side
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

/// This method allows to call the [newUserUrl] endpoint and communicate with the Authentication Server in order to register a new User server-side by providing
/// the corresponding information through [requestBody] object
///
/// Returns a [bool] value expressing success/failure of the operation
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

/// This method allows to call the [registerUrl] endpoint and communicate with the Authentication Server in order to register a new [Passkey] server-side by providing
/// the corresponding information through [requestBody] object
///
/// Returns a [bool] value expressing success/failure of the operation
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

/// This method allows to call the [authenticateUrl] endpoint and communicate with the Authentication Server in order to request the initiation of
/// a new asymmetric challenge in order to authenticate the calling User to a specific Relying Party by providing necessary information through [queryParameters] object
///
/// Returns [responseBody] challenge parameter which is a random nonce to be signed in order to prove authentication
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

/// This method allows to call the [authenticateUrl] endpoint and communicate with the Authentication Server in order to validate User provided response to the
/// previously received asymmetric authentication challenge by sending to the server the [requestBody] object containing in particular the signature computed over the
/// challenge itself
///
/// Returns a [bool] value expressing success/failure of the operation
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
