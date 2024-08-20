import 'dart:io';
 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
 
void main() {
  runApp(MyApp());
}
 
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImagePickerDemo(),
    );
  }
}
 
class ImagePickerDemo extends StatefulWidget {
  @override
  _ImagePickerDemoState createState() => _ImagePickerDemoState();
}
 
class _ImagePickerDemoState extends State<ImagePickerDemo> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  File? file;
  var _recognitions;
  List<String> v = [];
  var total = 0;
  String _displayText = '';
  int _personCount = 0; // Variable to keep track of "person" count
 
  @override
  void initState() {
    super.initState();
    loadmodel().then((value) {
      setState(() {});
    });
  }
 
  loadmodel() async {
    await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
  }
 
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // Handle the case where no image is picked
 
      setState(() {
        _image = image;
        file = File(image.path);
        _displayText = ''; // Reset the display text
        v.clear(); // Clear the list storing recognition results
        _personCount = 0; // Reset the person count
      });
 
      await detectimage(file!);
    } catch (e) {
      print('Error picking image: $e');
    }
  }
 
  Future detectimage(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, // required
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        threshold: 0.4, // defaults to 0.1
        numResultsPerClass: 2, // defaults to 5
        asynch: true // defaults to true
        );
    setState(() {
      _recognitions = recognitions;
      String p;
      total = recognitions!.length;
      _personCount = 0; // Reset person count
      for (int i = 0; i < recognitions.length; i++) {
        p = recognitions[i].toString();
        var p2 = p.split(':');
        String p3 = p2[p2.length - 1];
        var p4 = p3.split('}');
        String p5 = p4[0];
        print('*****$i = $p5');
        v.add(p5);
        if (p5.contains("person")) {
          _personCount++;
        }
      }
      _displayText =
          'Detected objects: ${v.join(', ')}\nPerson count: $_personCount';
 
      // dataList = List<Map<String, dynamic>>.from(jsonDecode(v));
    });
    print("//////////////////////////////////////////////////");
    print(_recognitions);
    // print(dataList);
    print("//////////////////////////////////////////////////");
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter TFlite'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null)
              Image.file(
                File(_image!.path),
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
            else
              Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image from Gallery'),
            ),
            SizedBox(height: 20),
            Text(_displayText),
          ],
        ),
      ),
    );
  }
}