import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

// เริ่มต้นแอปพลิเคชัน
void main() {
  runApp(const MyApp());
}

// สร้าง MaterialApp และกำหนด theme
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFED7D7), // สีชมพูอ่อนเป็นสีหลัก
          primary: const Color(0xFFFED7D7),
        ),
        fontFamily: 'Roboto',
      ),
      home: const ImageDetectorPage(),
    );
  }
}

// หน้าหลักสำหรับการตรวจจับวัตถุในภาพ
class ImageDetectorPage extends StatefulWidget {
  const ImageDetectorPage({Key? key}) : super(key: key);

  @override
  _ImageDetectorPageState createState() => _ImageDetectorPageState();
}

class _ImageDetectorPageState extends State<ImageDetectorPage> {
  // ประกาศตัวแปรที่จำเป็น
  final ImagePicker _picker = ImagePicker(); // สำหรับเลือกรูปภาพ
  XFile? _image; // เก็บไฟล์รูปภาพที่เลือก
  File? file; // ไฟล์รูปภาพสำหรับแสดงผล
  // ignore: unused_field
  var _recognitions; // ผลลัพธ์จากการตรวจจับ
  List<String> detectedObjects = []; // รายการวัตถุที่ตรวจพบ
  int personCount = 0; // จำนวนคนที่ตรวจพบ
  bool isLoading = false; // สถานะกำลังประมวลผล

  @override
  void initState() {
    super.initState();
    loadModel(); // โหลดโมเดล TensorFlow เมื่อเริ่มต้น
  }

  // โหลดโมเดล TensorFlow
  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/ssd_mobilenet.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  // ฟังก์ชันสำหรับเลือกรูปภาพจากแกลเลอรี่
  Future<void> pickImage() async {
    try {
      setState(() => isLoading = true); // แสดงสถานะกำลังโหลด
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        _image = image;
        file = File(image.path);
        detectedObjects.clear(); // ล้างผลการตรวจจับเก่า
        personCount = 0;
      });

      await detectObjects(file!); // เริ่มการตรวจจับวัตถุ
    } catch (e) {
      print('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ฟังก์ชันตรวจจับวัตถุในรูปภาพ
  Future<void> detectObjects(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      imageMean: 127.5,
      imageStd: 127.5,
      threshold: 0.4,
      numResultsPerClass: 2,
      asynch: true,
    );

    setState(() {
      _recognitions = recognitions;
      detectedObjects.clear();
      personCount = 0;

      // วนลูปเพื่อนับจำนวนคนและเก็บรายการวัตถุที่ตรวจพบ
      for (var recognition in recognitions!) {
        String label = recognition['detectedClass'].toString();
        detectedObjects.add(label);
        if (label.toLowerCase() == 'person') {
          personCount++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5), // พื้นหลังสีชมพูอ่อน
      body: Stack(
        children: [
          // ส่วนตกแต่งดอกไม้
          Positioned(
            top: -50,
            left: -30,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: FlowerPainter(),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: FlowerPainter(),
            ),
          ),
          
          // เนื้อหาหลัก
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // ข้อความต้อนรับ
                  const Text(
                    'welcome',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // กรอบแสดงรูปภาพ
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFED7D7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _image != null
                          ? Image.file(
                              File(_image!.path),
                              fit: BoxFit.cover,
                            )
                          : Column( // แสดงเมื่อยังไม่มีรูปภาพ
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // แสดงผลการตรวจจับ
                  if (_image != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFFED7D7),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // แสดงรายการวัตถุที่ตรวจพบ
                          Row(
                            children: [
                              const Icon(
                                Icons.search,
                                size: 20,
                                color: Color(0xFF991B1B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Detected: ${detectedObjects.join(", ")}',
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // แสดงจำนวนคนที่ตรวจพบ
                          Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 20,
                                color: Color(0xFF991B1B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'People found: $personCount',
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // ปุ่มเลือกรูปภาพ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFED7D7),
                        foregroundColor: const Color(0xFF991B1B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLoading ? Icons.hourglass_empty : Icons.photo_library,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLoading ? 'Processing...' : 'pick image from gallery',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// คลาสสำหรับวาดลายดอกไม้ประดับ
class FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFED7D7).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    const petalRadius = 30.0;

    // วาดกลีบดอกไม้
    for (var i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final petalCenter = Offset(
        center.dx + cos(angle) * petalRadius,
        center.dy + sin(angle) * petalRadius,
      );
      
      canvas.drawCircle(petalCenter, 15, paint);
    }

    // วาดจุดกลางดอกไม้
    canvas.drawCircle(center, 10, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}