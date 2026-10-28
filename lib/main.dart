import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_background_remover/image_background_remover.dart';
import 'package:gal/gal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: "Font"),
      debugShowCheckedModeBanner: false,

      home: LocalRemoveBgScreen(),
    );
  }
}

class LocalRemoveBgScreen extends StatefulWidget {
  const LocalRemoveBgScreen({super.key});

  @override
  State<LocalRemoveBgScreen> createState() => _LocalRemoveBgScreenState();
}

class _LocalRemoveBgScreenState extends State<LocalRemoveBgScreen> {
  File? _selectedImage; // الصورة الأصلية
  Uint8List? _processedImageBytes; // الصورة بعد إزالة الخلفية
  bool _isLoading = false; // مؤشر التحميل

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 1. تهيئة نموذج الذكاء الاصطناعي عند بدء الشاشة
    BackgroundRemover.instance.initializeOrt();
  }

  @override
  void dispose() {
    // تنظيف الموارد عند الخروج من الشاشة
    BackgroundRemover.instance.dispose();
    super.dispose();
  }

  // 2. اختيار الصورة من المعرض
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _processedImageBytes = null; // إعادة تعيين النتيجة القديمة
      });
    }
  }

  Future<void> _removeBgLocally() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List imageBytes = await _selectedImage!.readAsBytes();

      // الناتج هنا نوعه dynamic أو ui.Image حسب المكتبة
      var resultImage = await BackgroundRemover.instance.removeBg(
        imageBytes,
        threshold: 0.3,
        smoothMask: true,
      );

      if (resultImage != null) {
        // بما أن الناتجة ui.Image، نحتاج لتحويلها إلى Uint8List (PNG bytes)
        // أو إذا كانت المكتبة تعيد ui.Image مباشرة:

        // إذا أردت تحويل ui.Image إلى ByteData ثم Uint8List:
        final byteData = await resultImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final Uint8List pngBytes = byteData!.buffer.asUint8List();

        setState(() {
          _processedImageBytes = pngBytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("حدث خطأ أثناء المعالجة: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadphoto(dynamic imagebybytes) async {
    try {
      bool hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImageBytes(imagebybytes);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(shape: StadiumBorder(),backgroundColor: ui.Color.fromARGB(255, 17, 73, 119),content: Text("Downloaded...")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(shape: StadiumBorder(),backgroundColor: ui.Color.fromARGB(255, 17, 73, 119),content: Text("Sorry,Faild downloading")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("images/back.jpeg", fit: BoxFit.cover),
          ),

          Column(
            children: [
              Text("حره",textAlign: TextAlign.center,style: TextStyle(color: Colors.white,fontSize: 40,fontWeight: FontWeight.bold),),
              // منطقة عرض الصورة
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Lottie.asset("images/loading.json")],
                          ),
                        )
                      : _processedImageBytes != null
                      ? Container(

                          color: Colors.transparent,
                          child: Column(
                            children: [
                              const SizedBox(height: 20,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _downloadphoto(_processedImageBytes);
                                    },
                                    icon: Icon(
                                      Icons.download,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                             
                              Image.memory(
                                _processedImageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        )
                      : _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.contain)
                      : const Center(
                          child: Text(
                            "Choose photo to remove background...",
                            style: TextStyle(color: Colors.white,fontSize: 14),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // أزرار التحكم
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,

                      label: const Text(
                        "Upload",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const ui.Color.fromARGB(255, 63, 87, 114),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedImage != null && !_isLoading
                          ? _removeBgLocally
                          : null,

                      label: const Text(
                        "Generate",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const ui.Color.fromARGB(255, 63, 87, 114),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
