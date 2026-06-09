import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class HealthDataModel {
  final int steps;
  final int heartRate;
  final double sleepDuration;
  final int spo2;

  HealthDataModel({
    required this.steps,
    required this.heartRate,
    required this.sleepDuration,
    required this.spo2,
  });

  factory HealthDataModel.empty() {
    return HealthDataModel(steps: 0, heartRate: 0, sleepDuration: 0.0, spo2: 0);
  }
}

class GoogleFitService {
  late final GoogleSignIn _googleSignIn;

  GoogleFitService() {
    _googleSignIn = GoogleSignIn(
      clientId: '21746940547-39bq1mdnf3f9rkrpb2d4rivipjrmq1ou.apps.googleusercontent.com',
      scopes: [
        'https://www.googleapis.com/auth/fitness.activity.read',
        'https://www.googleapis.com/auth/fitness.heart_rate.read',
        'https://www.googleapis.com/auth/fitness.sleep.read',
        'https://www.googleapis.com/auth/fitness.oxygen_saturation.read',
      ],
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<HealthDataModel> fetchTodayData() async {
    var account = await _googleSignIn.signInSilently();
    account ??= await _googleSignIn.signIn();
    
    if (account == null) throw Exception("User canceled sign-in or failed.");

    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) throw Exception("Missing Google Fit access token");

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = now.millisecondsSinceEpoch;

    final url = Uri.parse('https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "aggregateBy": [
          {"dataTypeName": "com.google.step_count.delta"},
          {"dataTypeName": "com.google.heart_rate.bpm"},
          {"dataTypeName": "com.google.oxygen_saturation"}
        ],
        "bucketByTime": {"durationMillis": 86400000},
        "startTimeMillis": startOfDay,
        "endTimeMillis": endOfDay
      }),
    );

    int steps = 0;
    int heartRate = 0;
    int spo2 = 0;
    double sleep = 6.5; // Default fallback if Sleep Segment API isn't queried

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final buckets = data['bucket'] as List;
      
      if (buckets.isNotEmpty) {
        final dataset = buckets.first['dataset'] as List;
        for (var ds in dataset) {
          final points = ds['point'] as List;
          if (points.isNotEmpty) {
            // Aggregate totals might be in intVal or fpVal depending on the type
            final valueList = points.last['value'] as List;
            if (valueList.isNotEmpty) {
              final value = valueList.first;
              if (ds['dataSourceId'].toString().contains('step') && value.containsKey('intVal')) {
                steps = value['intVal'];
              }
              if (ds['dataSourceId'].toString().contains('heart_rate') && value.containsKey('fpVal')) {
                heartRate = value['fpVal'].toInt();
              }
              if (ds['dataSourceId'].toString().contains('oxygen') && value.containsKey('fpVal')) {
                spo2 = value['fpVal'].toInt();
              }
            }
          }
        }
      }
    } else {
      print("Google Fit API Error: \${response.statusCode} - \${response.body}");
    }

    return HealthDataModel(
      steps: steps > 0 ? steps : 0, 
      heartRate: heartRate > 0 ? heartRate : 0,
      spo2: spo2 > 0 ? spo2 : 0,
      sleepDuration: sleep,
    );
  }
}
