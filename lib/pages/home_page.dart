import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import "../services/socket_service.dart";
import "../components/pump_control_card.dart";
import "../components/item_dashboard.dart";
import '../components/graph_card.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PumpService pumpSocket = PumpService();
  List<Map<String, dynamic>> farmData = [];
  String pumpStatus = 'OFF';
  Timer? timer;

  String? selectedCrop;
  String? selectedStage;
  List<String> cropOptions = ['Wheat', 'Rice', 'Corn', 'Barley', 'Soybean'];
  List<String> stageOptions = ['Seedling', 'Vegetative', 'Flowering'];

  @override
  void initState() {
    super.initState();
    if (mounted) fetchData(); // Fetch initial data
    pumpSocket.initializeConnection('FARM001');
    pumpSocket.startPump = () {
      if (mounted) {
        setState(() {
          pumpStatus = 'ON';
        });
      }
    };
    pumpSocket.stopPump = () {
      if (mounted) {
        setState(() {
          pumpStatus = 'OFF';
        });
      }
    };
    timer = Timer.periodic(const Duration(seconds: 10), (timer) => fetchData());
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }

  Future<void> fetchData() async {
    final url = Uri.parse(
        'http://192.168.1.35:5000/api/farm/FARM001/data'); // Replace with your API endpoint
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            farmData =
                List<Map<String, dynamic>>.from(decodedResponse['farmData']);
          });
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastData = farmData.isNotEmpty ? farmData.last : null;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 0),
        children: [
          Container(
            padding: const EdgeInsets.only(top: 10),
            color: const Color.fromARGB(255, 145, 164, 248),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          border: Border.all(
                              color: const Color.fromARGB(255, 141, 140, 140),
                              width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCrop,
                          hint: const Text('Select Crop'),
                          items: cropOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCrop = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 7.0),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          border: Border.all(
                              color: const Color.fromARGB(255, 141, 140, 140),
                              width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          value: selectedStage,
                          hint: const Text('Select Stage'),
                          items: stageOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedStage = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 7.0),
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10),
            color: const Color.fromARGB(255, 145, 164, 248),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedCrop != null && selectedStage != null) {
                        print('Crop: $selectedCrop, Stage: $selectedStage');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please select both crop and stage')),
                        );
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCrop = null;
                        selectedStage = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 35),
            color: const Color.fromARGB(255, 145, 164, 248),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 157, 239, 241),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(900)),
              ),
              child: GridView.count(
                padding: const EdgeInsets.only(bottom: 80),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 40,
                mainAxisSpacing: 30,
                children: [
                  itemDashboard(
                    'Temperature',
                    lastData != null ? '${lastData["temperature"]}°C' : '...',
                    CupertinoIcons.thermometer,
                    Colors.deepOrange,
                  ),
                  itemDashboard(
                    'Soil Moisture',
                    lastData != null ? '${lastData["moisture"]}%' : '...',
                    CupertinoIcons.drop,
                    Colors.blue,
                  ),
                  itemDashboard(
                    'Humidity',
                    lastData != null ? '${lastData["humidity"]}%' : '...',
                    CupertinoIcons.wind,
                    Colors.deepPurple,
                  ),
                  pumpControlCard(
                    pumpStatus,
                    () {
                      String event =
                          pumpStatus == 'ON' ? 'stopPump' : 'startPump';
                      pumpSocket.sendData(event, {"farmId": 'FARM001'});
                    },
                  ),
                ],
              ),
            ),
          ),
          GraphCard(
            farmData: farmData,
            title: "Temperature",
            field: "temperature",
            color: Colors.deepOrange,
          ),
          GraphCard(
            farmData: farmData,
            title: "Soil Moisture",
            field: "moisture",
            color: Colors.blue,
          ),
          GraphCard(
            farmData: farmData,
            title: "Humidity",
            field: "humidity",
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}
