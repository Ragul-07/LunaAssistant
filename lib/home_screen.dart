import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isDarkMode = true;
  bool _isSidebarOpen = false;
  bool _isListening = false;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _speech = stt.SpeechToText();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Future<void> _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool('isDarkMode', _isDarkMode);
    });
  }

  Future<void> sendCommand(String command) async {
    if (command.isEmpty) return;

    setState(() {
      _chatHistory.insert(0, {"user": command, "bot": "Luna is thinking..."});
    });

    final response = await http.post(
      Uri.parse("http://127.0.0.1:5000/command"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"command": command}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setState(() {
        _chatHistory[0]["bot"] = result["response"];
      });
    } else {
      setState(() {
        _chatHistory[0]["bot"] = "Failed to connect to server.";
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      print("Selected file: ${file.path}");
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      sendCommand(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Luna Assistant',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: _isDarkMode ? Colors.black87 : Colors.blueAccent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
            color: Colors.white,
          ),
          onPressed: _toggleTheme,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.message, color: Colors.white),
            onPressed: _toggleSidebar,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Sidebar
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: _isSidebarOpen ? 0 : -250,
            top: 0,
            bottom: 0,
            child: Container(
              width: 250,
              color: _isDarkMode ? Colors.black54 : Colors.white,
              child: ListView(
                padding: EdgeInsets.all(10),
                children:
                    _chatHistory.map((entry) {
                      return ListTile(
                        title: Text(
                          entry["user"]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          entry["bot"]!,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.grey : Colors.black54,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Main Body
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(10),
                        reverse: true,
                        itemCount: _chatHistory.length,
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment:
                                _chatHistory[index]["user"] != null
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              if (_chatHistory[index]["user"] != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ChatBubble(
                                    text: _chatHistory[index]["user"]!,
                                    isUser: true,
                                  ),
                                ),
                              if (_chatHistory[index]["bot"] != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ChatBubble(
                                    text: _chatHistory[index]["bot"]!,
                                    isUser: false,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: _isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          FloatingActionButton(
                            backgroundColor: Colors.blue,
                            onPressed: _toggleListening,
                            child: Icon(Icons.mic, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText:
                                    _isListening
                                        ? "Listening..."
                                        : "Ask Luna...",
                                filled: true,
                                fillColor:
                                    _isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (value) {
                                sendCommand(value);
                                _controller.clear();
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () {
                              sendCommand(_controller.text);
                              _controller.clear();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: isUser ? Colors.blueAccent : Colors.grey[700],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
