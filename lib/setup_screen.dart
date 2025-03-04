import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  String? userName;
  String? petName;
  String selectedVoice = "Female"; // Default voice
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
    });
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  Future<void> saveUserData() async {
    if (_nameController.text.isEmpty || _petNameController.text.isEmpty) {
      _showAlert("Please fill in all details!");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    await prefs.setString('userName', userName!);
    await prefs.setString('petName', petName!);
    await prefs.setString('voicePreference', selectedVoice);
    await sendVoiceSelectionToServer(selectedVoice); // Send to Flask
    saveToExcel(userName!, petName!, selectedVoice);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  Future<void> sendVoiceSelectionToServer(String voice) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/api/set-voice'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"voice": voice}),
    );

    if (response.statusCode == 200) {
      print("Voice updated to $voice successfully");
    } else {
      print("Failed to update voice: ${response.body}");
    }
  }

  Future<void> saveToExcel(String name, String pet, String voice) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/UserDetails.xlsx';
    var file = File(path);
    var excel = Excel.createExcel();
    Sheet sheet = excel['User Data'];
    sheet.appendRow(['Name', 'Pet Name', 'Voice Preference']);
    sheet.appendRow([name, pet, voice]);
    List<int>? encodedExcel = excel.encode();
    if (encodedExcel != null) {
      await file.writeAsBytes(encodedExcel);
    }
    _showUserDetails(name, pet, voice);
  }

  void _showUserDetails(String name, String pet, String voice) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              "User Details",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text("Name: $name\nPet Name: $pet\nVoice: $voice"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text("Alert", style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  Widget buildPage(
    String title,
    String subtitle,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // ✅ Corrected
                iconColor: Colors.white, // ✅ Ensure iconColor is valid
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildNamePage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Enter your details",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Your Name",
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          MouseRegion(
            onEnter: (_) => setState(() {}),
            onExit: (_) => setState(() {}),
            child: TextField(
              controller: _petNameController,
              decoration: InputDecoration(
                labelText: "Your Pet's Name",
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          buildNavButtons(),
        ],
      ),
    );
  }

  Widget buildVoiceSelectionPage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Choose your preferred voice",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text("Female Voice"),
            leading: Radio(
              value: "Female",
              groupValue: selectedVoice,
              onChanged:
                  (value) => setState(() => selectedVoice = value.toString()),
            ),
          ),
          ListTile(
            title: Text("Male Voice"),
            leading: Radio(
              value: "Male",
              groupValue: selectedVoice,
              onChanged:
                  (value) => setState(() => selectedVoice = value.toString()),
            ),
          ),
          buildNavButtons(),
        ],
      ),
    );
  }

  Widget buildNavButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed:
              () => _pageController.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
          child: Text("Back"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pageController.page == 1) {
              userName = _nameController.text;
              petName = _petNameController.text;
              if (userName!.isEmpty || petName!.isEmpty) {
                _showAlert("Please fill in all details!");
                return;
              }
            }
            if (_pageController.page == 2) {
              saveUserData();
            } else {
              _pageController.nextPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Text(
            _pageController.hasClients && _pageController.page == 2
                ? "Complete Setup"
                : "Next",
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            "Setup Luna Assistant",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => _toggleTheme(!isDarkMode),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            buildPage(
              "Welcome to Luna Assistant",
              "Let's get started",
              "Next",
              () => _pageController.nextPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
            ),
            buildNamePage(),
            buildVoiceSelectionPage(),
          ],
        ),
      ),
    );
  }
}
