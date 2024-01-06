import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tutor_matching_app/MongoDb.dart';
import 'package:http/http.dart' as http;
import '../const.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDatabase.connect();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController controller = TextEditingController();
  var state = 0;
  List output = [];

  void sendMessage() async {
    setState(() {
      state = 1;
    });
    var tutorsPrompt = await MongoDatabase.fetchAll();
    print(tutorsPrompt.toString());
    final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OPENAI_API_KEY'
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "user",
              "content":
                  "here are subjects and timetables of tutors: ${tutorsPrompt.toString()} which tutor best suits a client saying ${controller.text}. I want you to return top five matches as array of json objects where each object have field 'name' , a string field 'UID'  and numeric field 'score' which represents how much this tutor is suitable from 0 to 10. I want you the answer to be this array only without any explanations"
            }
          ]
        }));
    if (response.statusCode == 200) {
      var res = jsonDecode(response.body);
      print(res["choices"][0]["message"]["content"].toString().trimLeft());
      setState(() {
        state = 2;
        String temp =
            res["choices"][0]["message"]["content"].toString().trimLeft();
        output = jsonDecode(temp);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'What are you looking for?',
            ),
            TextField(controller: controller),
            if (state == 1)
              CircularProgressIndicator()
            else if (state == 2)
              Container(
                height: 300,
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return InkWell(
                      child: Card(child: Text(output[index]['name'])),
                      onTap: () {
                        MongoDatabase.addtoFavs(output[index]['UID']);
                        final snackBar = SnackBar(
                          content: const Text('Tutor Added!'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      },
                    );
                  },
                  itemCount: output.length,
                ),
              )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: sendMessage,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
