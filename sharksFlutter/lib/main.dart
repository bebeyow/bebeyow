import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';

import 'package:adante_endangeredrareshark/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class _PredictionScore {
  const _PredictionScore({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence; // percentage 0-100
}

class _PredictionResult {
  const _PredictionResult({
    required this.label,
    required this.confidence,
    required this.topScores,
  });

  final String label;
  final double confidence; // percentage 0-100
  final List<_PredictionScore> topScores;

  String toDisplayString() => '$label (${confidence.toStringAsFixed(1)}%)';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endangered Shark Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: (() {
          const bodyColor = Color(0xFF6A1B4D);
          final base = Theme.of(context).textTheme;
          final dmSans = GoogleFonts.dmSansTextTheme(base);
          final inter = GoogleFonts.interTextTheme(base);

          return TextTheme(
            displayLarge: dmSans.displayLarge?.copyWith(color: bodyColor),
            displayMedium: dmSans.displayMedium?.copyWith(color: bodyColor),
            displaySmall: dmSans.displaySmall?.copyWith(color: bodyColor),
            headlineLarge: dmSans.headlineLarge?.copyWith(color: bodyColor),
            headlineMedium: dmSans.headlineMedium?.copyWith(color: bodyColor),
            headlineSmall: dmSans.headlineSmall?.copyWith(color: bodyColor),
            titleLarge: dmSans.titleLarge?.copyWith(color: bodyColor),
            titleMedium: dmSans.titleMedium?.copyWith(color: bodyColor),
            titleSmall: dmSans.titleSmall?.copyWith(color: bodyColor),
            bodyLarge: inter.bodyLarge?.copyWith(color: bodyColor),
            bodyMedium: inter.bodyMedium?.copyWith(color: bodyColor),
            bodySmall: inter.bodySmall?.copyWith(color: bodyColor),
            labelLarge: inter.labelLarge?.copyWith(color: bodyColor),
            labelMedium: inter.labelMedium?.copyWith(color: bodyColor),
            labelSmall: inter.labelSmall?.copyWith(color: bodyColor),
          );
        })(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 4,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const _SplashScreen(),
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const _ShimmerSkeleton({
    required this.height,
    this.width,
    this.borderRadius = 12,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration
        (
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen({super.key});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const _MainShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 300,
          height: 300,
        ),
      ),
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: const Text(
          'Information',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(height: 8),
                    Image(
                      image: AssetImage('assets/logo.png'),
                      height: 200,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Endangered Rare Shark Species',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'About this app',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app helps you identify rare and endangered shark species using your camera or gallery images. '
                'You can scan a shark photo, view top predictions, and explore more information about each species.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Purpose and Goal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This application provides a structured platform for identifying endangered and rare shark species while supporting education and marine conservation efforts.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tips for best results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Use clear, well-lit photos.\n'
                '• Make sure the shark is centered in the frame.\n'
                '• Avoid photos where the shark is very far away or heavily occluded.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraphNavIcon extends StatelessWidget {
  const _GraphNavIcon();

  @override
  Widget build(BuildContext context) {
    final Color? color = IconTheme.of(context).color;

    return SvgPicture.asset(
      'assets/graph.svg',
      width: 24.0,
      height: 24.0,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
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
  final ImagePicker _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = [];

  File? _imageFile;
  String? _prediction;
  bool _isLoading = false;
  bool _isModelLoaded = false;

  int _rotationTurns = 0; // 0,1,2,3 quarter turns
  bool _centerCrop = true;

  String? _primaryLabel;
  double? _primaryConfidence; // percentage 0-100
  List<_PredictionScore> _topPredictions = const [];

  static const int _inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      final interpreter =
          await Interpreter.fromAsset('assets/model_unquant.tflite');
      final labelsData = await DefaultAssetBundle.of(context)
          .loadString('assets/labels.txt');
      final labels = labelsData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) {
        final parts = line.trim().split(' ');
        if (parts.length > 1) {
          return parts.sublist(1).join(' ');
        }
        return line.trim();
      }).toList();

      setState(() {
        _interpreter = interpreter;
        _labels = labels;
        _isModelLoaded = true;
      });
    } catch (e) {
      setState(() {
        _prediction = 'Failed to load model: $e';
      });
    }
  }

  Future<void> _captureAndClassify() async {
    if (!_isModelLoaded || _interpreter == null) {
      setState(() {
        _prediction = 'Model is not loaded yet.';
      });
      return;
    }

    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) {
        return;
      }

      final file = File(picked.path);

      setState(() {
        _imageFile = file;
        _isLoading = true;
        _prediction = null;
        _rotationTurns = 0;
        _centerCrop = true;
      });

      await _analyzeCurrentImage();
    } catch (e) {
      setState(() {
        _prediction = 'Error capturing or classifying image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_isModelLoaded || _interpreter == null) {
      setState(() {
        _prediction = 'Model is not loaded yet.';
      });
      return;
    }

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final file = File(picked.path);

      setState(() {
        _imageFile = file;
        _isLoading = true;
        _prediction = null;
        _rotationTurns = 0;
        _centerCrop = true;
      });

      await _analyzeCurrentImage();
    } catch (e) {
      setState(() {
        _prediction = 'Error picking image from gallery: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeCurrentImage() async {
    if (!_isModelLoaded || _interpreter == null) {
      setState(() {
        _prediction = 'Model is not loaded yet.';
      });
      return;
    }

    if (_imageFile == null) {
      setState(() {
        _prediction = 'Please capture or select an image first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _prediction = null;
    });

    try {
      final result = await _runInference(
        _imageFile!,
        rotationTurns: _rotationTurns,
        centerCrop: _centerCrop,
      );

      setState(() {
        _prediction = result.toDisplayString();
        _primaryLabel = result.label;
        _primaryConfidence = result.confidence;
        _topPredictions = result.topScores;
        _isLoading = false;
      });

      await _logPrediction(_prediction!, _imageFile!.path);
    } catch (e) {
      setState(() {
        _prediction = 'Error during analysis: $e';
        _isLoading = false;
      });
    }
  }

  Future<_PredictionResult> _runInference(
    File imageFile, {
    int rotationTurns = 0,
    bool centerCrop = true,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      return const _PredictionResult(
        label: 'Could not decode image',
        confidence: 0,
        topScores: [],
      );
    }

    img.Image workingImage = originalImage;

    if (rotationTurns % 4 != 0) {
      workingImage = img.copyRotate(
        workingImage,
        angle: rotationTurns * 90,
      );
    }

    if (centerCrop) {
      final int width = workingImage.width;
      final int height = workingImage.height;
      final int size = math.min(width, height);
      final int offsetX = (width - size) ~/ 2;
      final int offsetY = (height - size) ~/ 2;
      workingImage = img.copyCrop(
        workingImage,
        x: offsetX,
        y: offsetY,
        width: size,
        height: size,
      );
    }

    final resizedImage = img.copyResize(
      workingImage,
      width: _inputSize,
      height: _inputSize,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(_inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        input[0][y][x][0] = r;
        input[0][y][x][1] = g;
        input[0][y][x][2] = b;
      }
    }

    final output = List.generate(
      1,
      (_) => List<double>.filled(_labels.length, 0.0),
    );

    _interpreter!.run(input, output);

    final scores = output[0];

    if (_labels.isEmpty || scores.length != _labels.length) {
      return const _PredictionResult(
        label: 'Unknown',
        confidence: 0,
        topScores: [],
      );
    }

    final List<_PredictionScore> allScores = [];
    for (int i = 0; i < scores.length; i++) {
      final label = _labels[i];
      final confidence = scores[i] * 100.0;
      allScores.add(_PredictionScore(label: label, confidence: confidence));
    }

    allScores.sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = allScores.take(5).toList();

    final best = top.isNotEmpty
        ? top.first
        : const _PredictionScore(label: 'Unknown', confidence: 0);

    return _PredictionResult(
      label: best.label,
      confidence: best.confidence,
      topScores: top,
    );
  }

  Future<void> _logPrediction(String prediction, String imagePath) async {
    final parts = prediction.split('(');
    final label = parts.isNotEmpty ? parts[0].trim() : prediction;
    double? confidence;
    if (parts.length > 1) {
      final percentPart = parts[1].replaceAll('%)', '').replaceAll('%', '').trim();
      confidence = double.tryParse(percentPart);
    }

    try {
      await FirebaseFirestore.instance
          .collection('Adante_EndangeredRareShark')
          .add({
        'Accuracy_Rate': confidence,
        'ClassType': label,
        'Time': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15), // adjust radius here
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bg.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.white.withOpacity(0.30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        if (_imageFile == null) ...[
                          const Center(
                            child: Text(
                              'Capture or select a shark photo, analyze and learn information about them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                          ),
                          child: Image.asset(
                            'assets/scanner.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 80,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _captureAndClassify,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text(
                                    'Take Photo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 80,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _pickFromGallery,
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text(
                                    'Upload from Gallery',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.pinkAccent),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_imageFile != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Transform.rotate(
                              angle: _rotationTurns * 3.1415926535 / 2,
                              child: Image.file(
                                _imageFile!,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_isLoading)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              _ShimmerSkeleton(height: 18, width: 160),
                              SizedBox(height: 8),
                              _ShimmerSkeleton(height: 18, width: 220),
                              SizedBox(height: 16),
                              _ShimmerSkeleton(height: 56),
                            ],
                          )
                        else if (!_isModelLoaded)
                          const Text(
                            'Loading model...',
                            textAlign: TextAlign.center,
                          )
                        else if (_primaryLabel != null && _primaryConfidence != null)
                          _ClassificationResultsSection(
                            primaryLabel: _primaryLabel!,
                            primaryConfidence: _primaryConfidence!,
                            topPredictions: _topPredictions,
                            onAnalyzeAgain: _analyzeCurrentImage,
                            onReset: () {
                              setState(() {
                                _imageFile = null;
                                _prediction = null;
                                _primaryLabel = null;
                                _primaryConfidence = null;
                                _topPredictions = const [];
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({
    super.key,
    required this.speciesLabel,
  });

  final String speciesLabel;

  Color _iucnColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('critically endangered')) {
      return Colors.red.shade700;
    }
    if (s.contains('endangered')) {
      return Colors.redAccent;
    }
    if (s.contains('vulnerable')) {
      return Colors.orangeAccent;
    }
    if (s.contains('near threatened')) {
      return Colors.amber.shade700;
    }
    if (s.contains('least concern')) {
      return Colors.green.shade600;
    }
    if (s.contains('data deficient')) {
      return Colors.blueGrey;
    }

    return Colors.pinkAccent;
  }

  String _imageAssetForSpecies(_SpeciesInfo info) {
    final name = info.commonName.toLowerCase();

    if (name.contains('angelshark')) {
      return 'assets/angelshark.jpg';
    }
    if (name.contains('basking')) {
      return 'assets/baskingshark.webp';
    }
    if (name.contains('broadnose') || name.contains('sevengill')) {
      return 'assets/broadnose.jpg';
    }
    if (name.contains('frilled')) {
      return 'assets/frilled.jpg';
    }
    if (name.contains('goblin')) {
      return 'assets/goblin.jpg';
    }
    if (name.contains('great hammerhead')) {
      return 'assets/greathammerhead.webp';
    }
    if (name.contains('shortfin mako')) {
      return 'assets/shortfin.webp';
    }
    if (name.contains('short-tail')) {
      return 'assets/shorttail.jpg';
    }
    if (name.contains('spotted wobbegong')) {
      return 'assets/spotted.jpg';
    }
    if (name.contains('zebra shark')) {
      return 'assets/zebra.jpeg';
    }

    return 'assets/default.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final info = _SpeciesInfo.fromLabel(speciesLabel);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: Text(
          info.commonName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    _imageAssetForSpecies(info),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                info.scientificName,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _iucnColor(info.iucnStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'IUCN: ${info.iucnStatus}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _iucnColor(info.iucnStatus),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    info.taxonomy,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Key Identification Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...info.keyFeatures.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(f)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Distribution & Habitat Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      info.distribution,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoSection(title: 'Diet', body: info.diet),
              _InfoSection(title: 'Size', body: info.size),
              _InfoSection(title: 'Habitat', body: info.habitat),
              _InfoSection(title: 'Behavior', body: info.behavior),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}

class _SpeciesInfo {
  const _SpeciesInfo({
    required this.commonName,
    required this.scientificName,
    required this.iucnStatus,
    required this.taxonomy,
    required this.keyFeatures,
    required this.distribution,
    required this.diet,
    required this.size,
    required this.habitat,
    required this.behavior,
  });

  final String commonName;
  final String scientificName;
  final String iucnStatus;
  final String taxonomy;
  final List<String> keyFeatures;
  final String distribution;
  final String diet;
  final String size;
  final String habitat;
  final String behavior;

  static _SpeciesInfo fromLabel(String label) {
    final normalized = label.toLowerCase().trim();

    if (normalized.startsWith('angelshark')) {
      return _SpeciesInfo(
        commonName: 'Angelshark',
        scientificName: 'Squatina squatina',
        iucnStatus: 'Critically Endangered',
        taxonomy: 'Family: Squatinidae',
        keyFeatures: const [
          'Strongly flattened body with large pectoral fins giving a ray-like appearance.',
          'Broad head with eyes and spiracles on top of the body',
          'Cryptic coloration that blends into sandy and muddy seafloor habitats.'
        ],
        distribution:
            'Formerly widespread in the Northeast Atlantic and Mediterranean Sea; now highly fragmented, mainly around the Canary Islands and limited coastal areas.',
        diet:
            'Ambush predator feeding on demersal fishes, cephalopods, and crustaceans, striking rapidly from the substrate.',
        size:
            'Commonly 1.2–1.8 m in length, with robust, flattened body.',
        habitat:
            'Coastal continental shelf, preferring soft-bottom habitats from shallow waters to about 150 m depth.',
        behavior:
            'Lies buried in sediment with only eyes exposed; lunges upward to capture passing prey. Highly vulnerable to bottom trawling and gillnet fisheries.',
      );
    }

    if (normalized.startsWith('basking shark')) {
      return _SpeciesInfo(
        commonName: 'Basking Shark',
        scientificName: 'Cetorhinus maximus',
        iucnStatus: 'Endangered',
        taxonomy: 'Family: Cetorhinidae',
        keyFeatures: const [
          'Very large, conical snout with enormous, gaping mouth when feeding.',
          'Gill slits that nearly encircle the head, with visible gill rakers.',
          'Tall, triangular dorsal fin and mottled grey-brown coloration.',
        ],
        distribution:
            'Temperate and boreal shelf seas of the North Atlantic and North Pacific, with seasonal movements linked to plankton blooms.',
        diet:
            'Obligate filter feeder consuming zooplankton, especially copepods, by swimming slowly with mouth open.',
        size:
            'Typically 6–8 m in length, second only to the whale shark in size among fish.',
        habitat:
            'Surface and midwater over continental shelves, often observed near fronts and areas of high plankton concentration.',
        behavior:
            'Slow-swimming and often seen at the surface; undertakes long-distance migrations and may form small feeding groups.',
      );
    }

    if (normalized.contains('broadnose') && normalized.contains('seveng')) {
      return _SpeciesInfo(
        commonName: 'Broadnose Sevengill Shark',
        scientificName: 'Notorynchus cepedianus',
        iucnStatus: 'Vulnerable',
        taxonomy: 'Family: Hexanchidae',
        keyFeatures: const [
          'Seven pairs of gill slits, unlike most sharks which have five.',
          'Broad, rounded snout with small eyes and a single dorsal fin far back on the body.',
          'Brownish to grey body often with small black spots.',
        ],
        distribution:
            'Temperate coastal waters of the Southern Hemisphere and parts of the North Pacific, including kelp forests and bays.',
        diet:
            'Opportunistic predator feeding on fishes, rays, other sharks, and marine mammals, sometimes scavenging.',
        size:
            'Adults typically 2–3 m long, with large, heavy-set bodies.',
        habitat:
            'Shallow coastal habitats, estuaries, and continental shelves down to at least 400 m depth.',
        behavior:
            'Often forms loose aggregations; can be bold near bait sources and may hunt cooperatively on large prey.',
      );
    }

    if (normalized.startsWith('frilled shark')) {
      return _SpeciesInfo(
        commonName: 'Frilled Shark',
        scientificName: 'Chlamydoselachus anguineus',
        iucnStatus: 'Near Threatened',
        taxonomy: 'Family: Chlamydoselachidae',
        keyFeatures: const [
          'Eel-like body with reduced, frilly-edged gill slits.',
          'Long jaws armed with many trident-shaped, needle-like teeth.',
          'Dark brown coloration and single small dorsal fin far back on the body.',
        ],
        distribution:
            'Patchy distribution in deep waters along continental and island slopes worldwide, mostly 200–1500 m.',
        diet:
            'Feeds primarily on cephalopods, including squids and cuttlefish, as well as bony fishes and smaller sharks.',
        size:
            'Generally 1–2 m in length with slender, elongated body.',
        habitat:
            'Bathypelagic and benthopelagic zones near the seafloor and occasionally in midwater.',
        behavior:
            'Thought to be a slow, stealthy ambush predator; rarely seen alive and often known from deep-sea bycatch.',
      );
    }

    if (normalized.startsWith('goblin shark')) {
      return _SpeciesInfo(
        commonName: 'Goblin Shark',
        scientificName: 'Mitsukurina owstoni',
        iucnStatus: 'Least Concern',
        taxonomy: 'Family: Mitsukurinidae',
        keyFeatures: const [
          'Distinctive long, flattened snout with protrusible jaws.',
          'Pinkish body coloration with semi-translucent skin.',
          'Long, slender teeth adapted for grasping deep-sea prey.',
        ],
        distribution:
            'Deep continental slopes of the western Pacific, Atlantic, and Indian Oceans, usually 200–1300 m deep.',
        diet:
            'Feeds on deep-sea fishes, cephalopods, and crustaceans, using rapid jaw protrusion to snatch prey.',
        size:
            'Commonly 2–3 m in length, with some individuals exceeding 3.5 m.',
        habitat:
            'Bathyal depths near continental slopes and seamounts, rarely observed at the surface.',
        behavior:
            'Solitary deep-sea species; most knowledge comes from occasional captures and submersible observations.',
      );
    }

    if (normalized.startsWith('great hammerhead')) {
      return _SpeciesInfo(
        commonName: 'Great Hammerhead Shark',
        scientificName: 'Sphyrna mokarran',
        iucnStatus: 'Critically Endangered',
        taxonomy: 'Family: Sphyrnidae',
        keyFeatures: const [
          'Prominent T-shaped head (cephalofoil) with eyes on the tips.',
          'Tall, sickle-shaped first dorsal fin towering above the body.',
          'Broad, curved mouth with large, serrated teeth.',
        ],
        distribution:
            'Circumtropical in coastal warm-temperate to tropical waters of the Atlantic, Pacific, and Indian Oceans.',
        diet:
            'Feeds on bony fishes, rays, other sharks, and cephalopods, often targeting stingrays on the seafloor.',
        size:
            'Typically 3–4 m long, with exceptional individuals over 6 m.',
        habitat:
            'Coastal and offshore waters, from shallow reefs and lagoons to outer continental shelves.',
        behavior:
            'Generally solitary apex predator with strong sensory capabilities; highly vulnerable to overfishing.',
      );
    }

    if (normalized.startsWith('shortfin mako')) {
      return _SpeciesInfo(
        commonName: 'Shortfin Mako Shark',
        scientificName: 'Isurus oxyrinchus',
        iucnStatus: 'Endangered',
        taxonomy: 'Family: Lamnidae',
        keyFeatures: const [
          'Streamlined, torpedo-shaped body built for speed.',
          'Pointed snout with large, black eyes and long, slender teeth.',
          'Metallic blue coloration on the back with white underside.',
        ],
        distribution:
            'Wide-ranging in tropical and temperate offshore waters worldwide, including high seas and coastal margins.',
        diet:
            'Active predator of fast-swimming fishes such as tunas, mackerels, and other pelagic species, as well as squids.',
        size:
            'Adults commonly 2.5–3.5 m, with powerful, muscular bodies.',
        habitat:
            'Epipelagic and upper mesopelagic zones, typically from the surface to around 500 m depth.',
        behavior:
            'One of the fastest sharks, capable of spectacular leaps; highly migratory and targeted by pelagic fisheries.',
      );
    }

    if (normalized.startsWith('short-tail nurse') || normalized.startsWith('short tail nurse')) {
      return _SpeciesInfo(
        commonName: 'Short-tail Nurse Shark',
        scientificName: 'Pseudoginglymostoma brevicaudatum',
        iucnStatus: 'Critically Endangered',
        taxonomy: 'Family: Ginglymostomatidae',
        keyFeatures: const [
          'Short, rounded tail relative to body length.',
          'Barbels near the mouth typical of nurse sharks.',
          'Small, stout body adapted to reef and rocky habitats.',
        ],
        distribution:
            'Western Indian Ocean, primarily along the coasts and offshore islands of East Africa and the Arabian Sea.',
        diet:
            'Feeds on benthic invertebrates and small fishes, using suction to extract prey from crevices.',
        size:
            'Usually less than 1 m in length, making it one of the smaller nurse sharks.',
        habitat:
            'Shallow coastal reefs, lagoons, and rocky areas often close to shore.',
        behavior:
            'Nocturnal and secretive, hiding in crevices during the day and foraging at night; extremely vulnerable due to limited range.',
      );
    }

    if (normalized.startsWith('spotted wobbegong')) {
      return _SpeciesInfo(
        commonName: 'Spotted Wobbegong',
        scientificName: 'Orectolobus maculatus',
        iucnStatus: 'Least Concern',
        taxonomy: 'Family: Orectolobidae',
        keyFeatures: const [
          'Flattened body with elaborate dermal lobes (frills) around the head.',
          'Complex pattern of spots and saddles providing excellent camouflage.',
          'Broad, rounded pectoral fins and relatively short tail.',
        ],
        distribution:
            'Coastal waters of eastern and southern Australia, often associated with rocky reefs and kelp beds.',
        diet:
            'Ambush predator feeding on fishes, cephalopods, and crustaceans that venture too close.',
        size:
            'Typically 1–2.5 m in length, with stout, flattened bodies.',
        habitat:
            'Shallow reefs, caves, and ledges, often resting on the seafloor during the day.',
        behavior:
            'Relies on camouflage and sudden strikes; generally sedentary but can be defensive if disturbed.',
      );
    }

    if (normalized.startsWith('zebra shark')) {
      return _SpeciesInfo(
        commonName: 'Zebra Shark',
        scientificName: 'Stegostoma tigrinum',
        iucnStatus: 'Endangered',
        taxonomy: 'Family: Stegostomatidae',
        keyFeatures: const [
          'Juveniles have zebra-like stripes; adults develop leopard-like spots.',
          'Long, flexible tail nearly as long as the body.',
          'Small mouth positioned at the front underside of the snout.',
        ],
        distribution:
            'Indo-West Pacific coral reef systems, from the Red Sea and East Africa to northern Australia and the western Pacific.',
        diet:
            'Feeds on mollusks, crustaceans, and small fishes, often foraging over sandy patches near reefs.',
        size:
            'Adults commonly reach 2–2.5 m in length.',
        habitat:
            'Shallow coral and rocky reefs, seagrass beds, and sandy flats, usually less than 60 m deep.',
        behavior:
            'Nocturnal and generally slow-moving; rests on the seafloor during the day and forages at night.',
      );
    }

    return const _SpeciesInfo(
      commonName: 'Unknown Shark Species',
      scientificName: 'Selachimorpha sp.',
      iucnStatus: 'Data Deficient',
      taxonomy: 'Class: Chondrichthyes  •  Superorder: Selachimorpha',
      keyFeatures: [
        'Lacks detailed identification data in this version of the app.',
        'Use overall body shape, fin positions, and color pattern to narrow down candidates.',
      ],
      distribution:
          'Distribution information for this species is not yet available. Future updates will include more detailed range maps.',
      diet:
          'Diet details are not yet available, but most sharks feed on a combination of fishes, invertebrates, and occasionally marine mammals.',
      size:
          'Size information is not yet available. Sharks range widely in length, from under 1 m to over 12 m in the case of large filter feeders.',
      habitat:
          'Habitat details are not yet available. Sharks inhabit nearly all marine environments, from shallow reefs to the deep sea.',
      behavior:
          'Behavioral information is not yet available. Future updates will add species-specific notes on movement, social behavior, and reproductive strategies.',
    );
  }
}

class _ClassificationResultsSection extends StatelessWidget {
  const _ClassificationResultsSection({
    required this.primaryLabel,
    required this.primaryConfidence,
    required this.topPredictions,
    required this.onAnalyzeAgain,
    required this.onReset,
  });

  final String primaryLabel;
  final double primaryConfidence;
  final List<_PredictionScore> topPredictions;
  final VoidCallback onAnalyzeAgain;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (topPredictions.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxConfidence =
        topPredictions.map((e) => e.confidence).fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryLabel,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${primaryConfidence.toStringAsFixed(1)}% match',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Top predictions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxBarWidth = constraints.maxWidth - 80;
                return Column(
                  children: topPredictions.map((p) {
                    final barWidth = maxConfidence > 0
                        ? maxBarWidth * (p.confidence / maxConfidence).clamp(0.0, 1.0)
                        : 0.0;
                    final isPrimary = p.label == primaryLabel;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              Container(
                                width: maxBarWidth,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Container(
                                width: barWidth,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isPrimary
                                      ? Colors.pinkAccent
                                      : Colors.pinkAccent.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${p.confidence.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SpeciesDetailScreen(
                        speciesLabel: primaryLabel,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Learn More'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({super.key});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _SharkFeedHome(
        onIdentifyTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyHomePage(
                title: 'Endangered Shark Scanner',
              ),
            ),
          );
        },
      ),
      const _ConfidenceGraphScreen(),
      const _MyActivityScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _GraphNavIcon(),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Activity',
          ),
        ],
      ),
    );
  }
}
class _SharkFeedHome extends StatelessWidget {
  const _SharkFeedHome({
    required this.onIdentifyTap,
  });

  final VoidCallback onIdentifyTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5F8), Color(0xFFFFE0F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: Colors.pinkAccent,
                  pinned: true,
                  expandedHeight: 450,
                  elevation: 4,
                  centerTitle: true,
                  title: Text(
                    'Rare Endangered Shark Species',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF5F8), Color(0xFFFFE0F0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 72.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(height: 8),
                                  Text(
                                    'Identify endangered sharks in seconds.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6A1B4D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0.0, 0.5),
                            child: SizedBox(
                              width: 260,
                              height: 260,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 240,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.0),
                                          Colors.black.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 310,
                                    height: 310,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.pinkAccent.withOpacity(0.1),
                                        width: 2,
                                      ),
                                
                                    ),
                                  ),
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.pinkAccent.withOpacity(0.1),
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 155,
                                    height: 155,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.pinkAccent.withOpacity(0.9),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pinkAccent.withOpacity(0.6),
                                          blurRadius: 22,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: ElevatedButton(
                                      onPressed: onIdentifyTap,
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: EdgeInsets.zero,
                                        elevation: 8
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          SizedBox(height: 6),
                                          Text(
                                            'START SCANNING',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
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
                    ),
                  ),
                ),
              ];
            },
            body: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Container(
                color: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Species Library',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SpeciesLibraryList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeciesLibraryList extends StatelessWidget {
  _SpeciesLibraryList();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_SpeciesInfo>>(
      future: _loadSpeciesFromLabels(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load species library: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final species = snapshot.data ?? const [];
        if (species.isEmpty) {
          return const Center(
            child: Text(
              'No species found in labels.txt yet. Add labels to populate this library.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: species.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final info = species[index];

            return Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                  child: SvgPicture.asset(
                    'assets/shark_icon.svg',
                    width: 24.0,
                    height: 24.0,
                    colorFilter: ColorFilter.mode(
                      Colors.pinkAccent,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(
                  info.commonName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      info.scientificName,
                      style:
                          const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'IUCN: ${info.iucnStatus}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpeciesDetailScreen(
                        speciesLabel: info.commonName,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_SpeciesInfo>> _loadSpeciesFromLabels(BuildContext context) async {
    final labelsData = await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
    final labels = labelsData
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
      final parts = line.trim().split(' ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
      return line.trim();
    }).toList();

    final uniqueLabels = labels.toSet().toList()..sort();
    return uniqueLabels.map(_SpeciesInfo.fromLabel).toList();
  }
}

class _RecentDetectionsList extends StatelessWidget {
  const _RecentDetectionsList({
    this.limit,
  });

  final int? limit;

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('Adante_EndangeredRareShark')
        .orderBy('Time', descending: true);

    if (limit != null) {
      query = query.limit(limit!);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _ShimmerSkeleton(height: 20, width: 200),
              SizedBox(height: 16),
              _ShimmerSkeleton(height: 120, borderRadius: 16),
            ],
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No detections yet. Start by scanning your first shark!',
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final classType = (data['ClassType'] ?? 'Unknown') as String;
            final accuracy = (data['Accuracy_Rate'] as num?)?.toDouble();
            final timestamp = data['Time'] as Timestamp?;
            final dateText = timestamp != null
                ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} '
                    '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                : 'Unknown time';

            return Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE0F0),
                  child: SvgPicture.asset(
                    'assets/shark_icon.svg',
                    width: 24.0,
                    height: 24.0,
                    colorFilter: ColorFilter.mode(
                      Colors.pink[300]!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(
                  classType,
                  style: GoogleFonts.jetBrainsMono(),
                ),
                subtitle: Text(
                  accuracy != null
                      ? 'Confidence: ${accuracy.toStringAsFixed(1)}%\n$dateText'
                      : dateText,
                  style: accuracy != null
                      ? GoogleFonts.jetBrainsMono()
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConfidenceGraphScreen extends StatelessWidget {
  const _ConfidenceGraphScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          'Confidence Graph',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Model confidence across recent detections',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _ConfidenceGraphBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfidenceGraphBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('Adante_EndangeredRareShark')
        .orderBy('Time', descending: true)
        .limit(200);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No detections yet. Scan a shark to see confidence graphs.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final Map<String, _ClassAggregate> aggregates = {};

        for (final doc in docs) {
          final data = doc.data();
          final label = (data['ClassType'] ?? 'Unknown') as String;
          final conf = (data['Accuracy_Rate'] as num?)?.toDouble();
          if (conf == null) continue;

          final agg = aggregates.putIfAbsent(label, () => _ClassAggregate());
          agg.total += conf;
          agg.count += 1;
        }

        if (aggregates.isEmpty) {
          return const Center(
            child: Text(
              'No confidence data available yet.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final items = aggregates.entries
            .map((e) => MapEntry(e.key, e.value.average))
            .toList();
        items.sort((a, b) => b.value.compareTo(a.value));
        final topItems = items;

        final maxConfidence =
            topItems.fold<double>(0, (max, e) => e.value > max ? e.value : max);

        // Overall average confidence across all classes
        final double overallConfidence = items.isEmpty
            ? 0
            : items.map((e) => e.value).fold<double>(0, (a, b) => a + b) /
                items.length;

        // Bucket detections into High / Medium / Low based on individual
        // Accuracy_Rate values so that we always have all 3 categories
        // represented, even if some buckets have 0 detections.
        int highCount = 0;
        int mediumCount = 0;
        int lowCount = 0;
        for (final doc in docs) {
          final data = doc.data();
          final conf = (data['Accuracy_Rate'] as num?)?.toDouble();
          if (conf == null) continue;

          if (conf >= 80) {
            highCount++;
          } else if (conf >= 50) {
            mediumCount++;
          } else {
            lowCount++;
          }
        }

        String confidenceLabel;
        Color confidenceColor;
        if (overallConfidence >= 80) {
          confidenceLabel = 'High';
          confidenceColor = Colors.green.shade600;
        } else if (overallConfidence >= 50) {
          confidenceLabel = 'Medium';
          confidenceColor = Colors.orange.shade600;
        } else {
          confidenceLabel = 'Low';
          confidenceColor = Colors.red.shade600;
        }

        // Build weekly scan buckets for bar graph (grouped by shark + week)
        final Map<String, _WeeklyScanBucket> weeklyBuckets = {};
        for (final doc in docs) {
          final data = doc.data();
          final label = (data['ClassType'] ?? 'Unknown') as String;
          final timestamp = data['Time'] as Timestamp?;
          if (timestamp == null) continue;

          final dt = timestamp.toDate();
          final int year = dt.year;
          final int week = _weekNumber(dt);
          final String key = '$label-$year-$week';

          final bucket = weeklyBuckets.putIfAbsent(
            key,
            () => _WeeklyScanBucket(
              sharkLabel: label,
              year: year,
              week: week,
            ),
          );
          bucket.count += 1;
        }

        final List<_WeeklyScanBucket> weeklyItems = weeklyBuckets.values.toList();
        weeklyItems.sort((a, b) {
          if (a.year != b.year) return b.year.compareTo(a.year);
          if (a.week != b.week) return b.week.compareTo(a.week);
          return b.count.compareTo(a.count);
        });

        final List<_WeeklyScanBucket> topWeekly = weeklyItems.take(12).toList();
        final int maxWeeklyCount =
            topWeekly.fold<int>(0, (max, e) => e.count > max ? e.count : max);

        return ListView.separated(
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              // Line graph: confidence by class
              return SizedBox(
                height: 220,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Average confidence per shark class',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CustomPaint(
                            painter: _ConfidenceLineChartPainter(
                              items: topItems,
                              maxConfidence: maxConfidence,
                            ),
                            child: Container(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (index == 1) {
              // Bar graph: weekly scans
              return SizedBox(
                height: 260,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Weekly shark scan counts',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: topWeekly.isEmpty || maxWeeklyCount == 0
                              ? const Center(
                                  child: Text(
                                    'No weekly scan data available yet.',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : CustomPaint(
                                  painter: _WeeklyBarChartPainter(
                                    items: topWeekly,
                                    maxCount: maxWeeklyCount,
                                  ),
                                  child: Container(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Overall confidence level card
            return Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Model Confidence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'High: $highCount',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.info,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Medium: $mediumCount',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Low: $lowCount',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConfidenceLineChartPainter extends CustomPainter {
  _ConfidenceLineChartPainter({
    required this.items,
    required this.maxConfidence,
  });

  final List<MapEntry<String, double>> items;
  final double maxConfidence;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) {
      return;
    }

    final double leftPadding = 32;
    final double bottomPadding = 24;
    final double topPadding = 8;
    final double rightPadding = 8;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final Paint axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final Offset origin = Offset(leftPadding, size.height - bottomPadding);
    final Offset xAxisEnd = Offset(size.width - rightPadding, origin.dy);
    final Offset yAxisEnd = Offset(origin.dx, topPadding);

    canvas.drawLine(origin, xAxisEnd, axisPaint);
    canvas.drawLine(origin, yAxisEnd, axisPaint);

    // Draw Y-axis labels (left side numbers)
    const int ySteps = 4; // e.g. 0%, 25%, 50%, 75%, 100% (relative to max)
    for (int i = 0; i <= ySteps; i++) {
      final double t = i / ySteps;
      final double value = maxConfidence * t;
      final double y = origin.dy - chartHeight * t;

      final textSpan = TextSpan(
        text: value.toStringAsFixed(0),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 4, y - tp.height / 2));
    }

    final Paint linePaint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint pointPaint = Paint()
      ..color = Colors.pinkAccent
      ..style = PaintingStyle.fill;

    final Path linePath = Path();

    final int n = items.length;
    final double stepX = n > 1 ? chartWidth / (n - 1) : 0;
    final double effectiveMax = maxConfidence <= 0 ? 1.0 : maxConfidence;

    for (int i = 0; i < n; i++) {
      final double value = items[i].value;
      final double normalized = (value / effectiveMax).clamp(0.0, 1.0);
      final double x = origin.dx + stepX * i;
      final double y = origin.dy - normalized * chartHeight;

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3, pointPaint);

      // Draw X-axis labels: shark name (shortened) and percent below
      final String rawLabel = items[i].key;
      final String nameLabel = rawLabel.length > 8
          ? rawLabel.substring(0, 8) + '…'
          : rawLabel;
      final String percentLabel = '${value.toStringAsFixed(0)}%';

      final TextSpan spanName = TextSpan(
        text: nameLabel,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.grey,
        ),
      );
      final TextSpan spanPercent = TextSpan(
        text: percentLabel,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.pinkAccent,
        ),
      );

      final TextPainter tpName = TextPainter(
        text: spanName,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final TextPainter tpPercent = TextPainter(
        text: spanPercent,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      tpName.layout();
      tpPercent.layout();

      final double labelY = origin.dy + 4; // slightly below X-axis
      tpName.paint(
        canvas,
        Offset(x - tpName.width / 2, labelY),
      );
      tpPercent.paint(
        canvas,
        Offset(x - tpPercent.width / 2, labelY + tpName.height),
      );
    }

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _ConfidenceLineChartPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.maxConfidence != maxConfidence;
  }
}

class _WeeklyScanBucket {
  _WeeklyScanBucket({
    required this.sharkLabel,
    required this.year,
    required this.week,
  });

  final String sharkLabel;
  final int year;
  final int week;
  int count = 0;

  String get label => '$sharkLabel\nW$week';
}

/// Simple ISO-like week number calculation (not exact ISO but good enough
/// for grouping recent scans by week).
int _weekNumber(DateTime date) {
  // Normalize to start of day
  final d = DateTime(date.year, date.month, date.day);
  // Week starts on Monday: DateTime.monday == 1
  final int dayOfWeek = d.weekday;
  // Find Thursday in current week to avoid edge issues
  final DateTime thursday = d.add(Duration(days: 4 - dayOfWeek));
  final DateTime firstJan = DateTime(thursday.year, 1, 1);
  final int diff = thursday.difference(firstJan).inDays;
  return (diff / 7).floor() + 1;
}

class _WeeklyBarChartPainter extends CustomPainter {
  _WeeklyBarChartPainter({
    required this.items,
    required this.maxCount,
  });

  final List<_WeeklyScanBucket> items;
  final int maxCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty || maxCount <= 0) {
      return;
    }

    const double leftPadding = 32;
    const double bottomPadding = 40;
    const double topPadding = 8;
    const double rightPadding = 8;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final Paint axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final Offset origin = Offset(leftPadding, size.height - bottomPadding);
    final Offset xAxisEnd = Offset(size.width - rightPadding, origin.dy);
    final Offset yAxisEnd = Offset(origin.dx, topPadding);

    canvas.drawLine(origin, xAxisEnd, axisPaint);
    canvas.drawLine(origin, yAxisEnd, axisPaint);

    // Y-axis labels: 0 .. maxCount
    const int ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final double t = i / ySteps;
      final double value = maxCount * t;
      final double y = origin.dy - chartHeight * t;

      final textSpan = TextSpan(
        text: value.toStringAsFixed(0),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 4, y - tp.height / 2));
    }

    final int n = items.length;
    final double barGroupWidth = chartWidth / n;
    final double barWidth = barGroupWidth * 0.5;

    final Paint barPaint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final _WeeklyScanBucket bucket = items[i];
      final double xCenter = origin.dx + barGroupWidth * (i + 0.5);
      final double t = bucket.count / maxCount;
      final double barHeight = chartHeight * t;

      final Rect barRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        origin.dy - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRect(barRect, barPaint);

      // Labels: shark name + week under each bar
      final String rawLabel = bucket.sharkLabel;
      final String sharkLabel = rawLabel.length > 8
          ? rawLabel.substring(0, 8) + '…'
          : rawLabel;
      final String weekLabel = 'W${bucket.week}';

      final TextSpan spanName = TextSpan(
        text: sharkLabel,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.grey,
        ),
      );
      final TextSpan spanWeek = TextSpan(
        text: weekLabel,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.pinkAccent,
        ),
      );

      final TextPainter tpName = TextPainter(
        text: spanName,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      final TextPainter tpWeek = TextPainter(
        text: spanWeek,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      tpName.layout();
      tpWeek.layout();

      final double labelY = origin.dy + 4;
      tpName.paint(
        canvas,
        Offset(xCenter - tpName.width / 2, labelY),
      );
      tpWeek.paint(
        canvas,
        Offset(xCenter - tpWeek.width / 2, labelY + tpName.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.maxCount != maxCount;
  }
}

class _ClassAggregate {
  double total = 0;
  int count = 0;

  double get average => count == 0 ? 0 : total / count;
}

class _MyActivityScreen extends StatelessWidget {
  const _MyActivityScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          'My Activity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Information',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InfoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, 
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: _RecentDetectionsList(),
        ),
      ),
    );
  }
}
