import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'result_screen.dart';

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final ImagePicker _picker = ImagePicker();
  ClassificationModel? _model;
  File? _image;
  bool _isModelReady = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _model = await PytorchLite.loadClassificationModel(
        'assets/models/burnaidmodel.pt',
        224,
        224,
        3,
        labelPath: null,
      );
      setState(() {
        _isModelReady = true;
      });
    } catch (e) {
      setState(() {
        _isModelReady = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null || _model == null) return;
    setState(() => _isLoading = true);
    final Uint8List imgBytes = await _image!.readAsBytes();
    final List<double>? rawOutput = await _model!.getImagePredictionList(
      imgBytes,
    );
    if (rawOutput == null || rawOutput.isEmpty) return;

    final List<String> labels = [
      "First Degree Burn",
      "Second Degree Burn",
      "Third Degree Burn",
    ];
    final probs = _softmax(rawOutput);
    debugPrint("Raw logits: $rawOutput");
    debugPrint("Softmax probs: $probs");
    final int idx = probs.indexOf(probs.reduce(max));
    final String result =
        "${labels[idx]} (${(probs[idx] * 100).toStringAsFixed(2)}%)";
    final String advice = _getFirstAid(labels[idx]);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ResultScreen(
              result: result,
              firstAid: advice,
              isThirdDegree: idx == 2,
              imageFile: _image,
            ),
      ),
    );
  }

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(max);
    List<double> expValues = logits.map((e) => exp(e - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }

  String _getFirstAid(String label) {
    switch (label) {
      case "First Degree Burn":
        return "Run cool water over the burn for 10–15 minutes to reduce pain and heat. Apply a clean, gentle burn cream or aloe vera to soothe the skin. Don’t use ice, butter, or toothpaste, as they can damage the skin.";
      case "Second Degree Burn":
        return "Gently cool the area under clean, running cool water for 10–15 minutes. Do not break any blisters. Cover the burn with a clean, non-stick bandage. You can apply an antibiotic cream if available. Avoid using ice, butter, or toothpaste, and seek medical help if the burn is large or on the face, hands, or joints..";
      case "Third Degree Burn":
        return "Do not apply water, ointments, or creams. Do not remove burned clothing stuck to the skin. Cover the burn with a clean, dry cloth or sterile bandage, and keep the person warm and calm. Call emergency medical services immediately, as this is a serious burn that needs hospital treatment.";
      default:
        return "No advice available.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyzer"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  )
                  : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _image != null && !_isLoading ? _analyzeImage : null,
                icon:
                    _isLoading
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : const Icon(Icons.search),
                label: const Text("Analyze"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
