import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'state/drawing_state.dart';
import 'canvas/drawing_canvas.dart';
import 'services/storage_service.dart';
import 'services/server_service.dart';
import 'splash_screen.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const EasyDrawingApp());
}

class EasyDrawingApp extends StatelessWidget {
  const EasyDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Drawing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo 500
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A), // Slate 900
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming Inter-like default typography
      ),
      home: const SplashScreen(),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  final String projectName;
  const DrawingScreen({super.key, required this.projectName});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final DrawingState _drawingState;
  final GlobalKey _canvasKey = GlobalKey();
  
  bool _isCasting = false;
  String _ipAddress = "Loading...";
  
  bool _isIslandExpanded = true;
  Timer? _islandTimer;

  @override
  void initState() {
    super.initState();
    _drawingState = DrawingState(widget.projectName);
    _startIslandTimer();
  }

  void _startIslandTimer() {
    _islandTimer?.cancel();
    _islandTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isIslandExpanded) {
        setState(() => _isIslandExpanded = false);
      }
    });
  }

  void _expandIsland() {
    if (!_isIslandExpanded) {
      setState(() => _isIslandExpanded = true);
    }
    _startIslandTimer();
  }

  @override
  void dispose() {
    _islandTimer?.cancel();
    ServerService().stopServer();
    _drawingState.dispose();
    super.dispose();
  }

  Future<void> _toggleCasting() async {
    if (_isCasting) {
      ServerService().stopServer();
      setState(() {
        _isCasting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Screen casting stopped')));
    } else {
      await ServerService().startServer(_drawingState);
      String? ip = await ServerService().getWifiIP();
      setState(() {
        _isCasting = true;
        _ipAddress = ip ?? "127.0.0.1 (USB Tethering)";
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
            title: const Text("Tablet Mode Active", style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
            content: Text(
              "To view the drawing on your laptop, open a web browser and go to:\n\nhttp://$_ipAddress:8080\n\nNote: Both devices must be on the same WiFi, or connected via USB Tethering.",
              style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("OK", style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600)),
              )
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveProjectAction() async {
    _drawingState.saveProject();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 24), // Emerald
              SizedBox(width: 8),
              Text("Success", style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Text("Project saved successfully.", style: TextStyle(color: Color(0xFFCBD5E1))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("OK", style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600)),
            )
          ],
        ),
      );
    }
  }

  Future<void> _attemptToCloseProject() async {
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
          title: const Text("Save Changes?", style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
          content: const Text("Do you want to save your work before closing?", style: TextStyle(color: Color(0xFFCBD5E1))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null), // Cancel
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Discard
              child: const Text("Discard", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)), // Red 500
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Indigo 500
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true), // Save
              child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (shouldSave == null) return; // User cancelled

    if (shouldSave) {
      _drawingState.saveProject();
    }
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _attemptToCloseProject();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Deep Slate background behind canvas
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                color: const Color(0xFF94A3B8), // Canvas surrounding area
                child: ListenableBuilder(
                  listenable: _drawingState,
                  builder: (context, _) {
                    return InteractiveViewer(
                      panEnabled: _drawingState.selectedTool == DrawingTool.pan,
                      scaleEnabled: true,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(1000), // Allow ample panning
                      minScale: 0.1,
                      maxScale: 5.0,
                      child: Center(
                        child: RepaintBoundary(
                          key: _canvasKey,
                          child: Container(
                            width: 1920,
                            height: 1080,
                            color: Colors.white, // The actual drawing canvas
                            child: DrawingCanvas(state: _drawingState),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Top Left: Back / Exit Button
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9), // Slate 800
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: _attemptToCloseProject,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back_ios_new, color: Color(0xFF94A3B8), size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Gallery', 
                              style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Top Center: Dynamic Island Actions
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildDynamicIsland(),
                ),
              ),

              // Casting Status indicator (Moved below Dynamic Island if casting)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (_isCasting && _isIslandExpanded) ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !(_isCasting && _isIslandExpanded),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2), // Emerald tint
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cast_connected, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Casting to $_ipAddress:8080', 
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Right: Floating Menu
              Positioned(
                bottom: 24,
                right: 24,
                child: _buildFloatingMenu(),
              ),
            ],
          ),
        )
      )
    );
  }

  Widget _buildDynamicIsland() {
    return ListenableBuilder(
      listenable: _drawingState,
      builder: (context, _) {
        return GestureDetector(
          onTap: _expandIsland,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCirc,
                padding: EdgeInsets.symmetric(horizontal: _isIslandExpanded ? 8 : 4, vertical: _isIslandExpanded ? 6 : 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.85), // Glassmorphic Slate 800
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  crossFadeState: _isIslandExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: _buildExpandedIsland(),
                  secondChild: _buildCollapsedIsland(),
                  layoutBuilder: (topChild, topKey, bottomChild, bottomKey) {
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          key: bottomKey,
                          child: bottomChild,
                        ),
                        Positioned(
                          key: topKey,
                          child: topChild,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildExpandedIsland() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIslandButton(Icons.undo, 'Undo', () { _drawingState.undo(); _startIslandTimer(); }, const Color(0xFF94A3B8)),
          _buildIslandDivider(),
          _buildIslandButton(Icons.delete_outline, 'Clear', () { _drawingState.clearCanvas(); _startIslandTimer(); }, const Color(0xFFEF4444)),
          _buildIslandDivider(),
          _buildIslandButton(Icons.save_outlined, 'Save', () { _saveProjectAction(); _startIslandTimer(); }, const Color(0xFF94A3B8)),
          _buildIslandDivider(),
          _buildIslandButton(
            _isCasting ? Icons.cast_connected : Icons.cast, 
            'Cast', 
            () { _toggleCasting(); _startIslandTimer(); }, 
            _isCasting ? const Color(0xFF10B981) : const Color(0xFF94A3B8)
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedIsland() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCasting) ...[
            const Icon(Icons.cast_connected, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            const Text("Casting", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 11)),
          ] else ...[
            const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildIslandButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIslandDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFF334155),
    );
  }

  Widget _buildFloatingMenu() {
    return ListenableBuilder(
      listenable: _drawingState,
      builder: (context, _) {
        if (!_isMenuOpen) {
          return FloatingActionButton(
            backgroundColor: const Color(0xFF6366F1), // Indigo 500
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => setState(() => _isMenuOpen = true),
            child: const Icon(Icons.palette_outlined),
          );
        }

        return Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1E293B).withValues(alpha: 0.95), // Slate 800
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 340,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - 48, // Prevent overflowing screen
              ),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF334155), width: 1), // Slate 700
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tools", style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20), 
                        onPressed: () => setState(() => _isMenuOpen = false),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Drawing Tools
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(Icons.edit, DrawingTool.pen, 'Write'),
                        _buildToolButton(Icons.phonelink_erase, DrawingTool.eraser, 'Erase'),
                        _buildToolButton(Icons.pan_tool, DrawingTool.pan, 'Pan'),
                        _buildMenuButton(Icons.interests_outlined, 'Shapes', _showMathLibrary),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  const Text("Colors", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  
                  // Colors
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildColorButton(Colors.black),
                      _buildColorButton(const Color(0xFFEF4444)), // Red
                      _buildColorButton(const Color(0xFF10B981)), // Green
                      _buildColorButton(const Color(0xFF3B82F6)), // Blue
                      _buildColorButton(const Color(0xFF8B5CF6)), // Violet
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Stroke Size", style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600)),
                      Text("${_drawingState.strokeWidth.toInt()}px", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF6366F1),
                      inactiveTrackColor: const Color(0xFF334155),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _drawingState.strokeWidth,
                      min: 1.0,
                      max: 20.0,
                      onChanged: (val) => _drawingState.setStrokeWidth(val),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildToolButton(IconData icon, DrawingTool tool, String label) {
    final isSelected = _drawingState.selectedTool == tool;
    return InkWell(
      onTap: () => _drawingState.setTool(tool),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF818CF8).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8), size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _drawingState.selectedColor == color && _drawingState.selectedTool == DrawingTool.pen;
    return GestureDetector(
      onTap: () {
        _drawingState.setColor(color);
        _drawingState.setTool(DrawingTool.pen); 
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)
          ] : null,
        ),
      ),
    );
  }

  void _showMathLibrary() {
    setState(() => _isMenuOpen = false); // Close main menu
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF475569), // Slate 600
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Shapes & Objects", style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ),
              Flexible(
                child: _buildTemplateGrid([
                  Icons.calculate_outlined, Icons.functions, Icons.change_history, 
                  Icons.circle_outlined, Icons.square_foot, Icons.pie_chart_outline, Icons.bar_chart
                ]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateGrid(List<IconData> icons) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            _drawingState.addObject(icons[index]);
            _drawingState.setTool(DrawingTool.pan);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Slate 900
              border: Border.all(color: const Color(0xFF334155)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icons[index], size: 32, color: const Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }
}
