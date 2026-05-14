import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'main.dart'; // To access DrawingScreen

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final StorageService _storageService = StorageService();
  List<String> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Ensure we are in Portrait Mode on the Main Menu
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // Ensure immersive full screen mode is active
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await _storageService.listProjects();
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  void _openProject(String projectName) async {
    // Switch to Landscape before entering DrawingScreen
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrawingScreen(projectName: projectName),
      ),
    );
    
    // Switch back to Portrait when returning
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _loadProjects(); // Reload in case we deleted/modified
  }

  void _createNewProject() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Slate 800
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155), width: 1), // Slate 700
          ),
          title: const Text('New Project', style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600, fontSize: 20)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w500),
            cursorColor: const Color(0xFF818CF8), // Indigo 400
            decoration: InputDecoration(
              hintText: 'Enter project name',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal), // Slate 400
              filled: true,
              fillColor: const Color(0xFF0F172A), // Slate 900
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2), // Indigo 500
              ),
            ),
            autofocus: true,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Indigo 500
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _openProject(name);
                }
              },
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(String projectName) async {
    await _storageService.deleteProject(projectName);
    _loadProjects();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Slate 800
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF818CF8)),
              SizedBox(width: 10),
              Text('About', style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Developed and designed by Sami Ullah.\nAll copyrights reserved.",
                style: TextStyle(color: Color(0xFFCBD5E1), height: 1.6, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Slate 900
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  children: [
                    Text(
                      "Contact via email:",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "sami5510556@gmail.com",
                      style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "For customized apps and websites.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155), // Slate 700
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: AppBar(
        title: const Text('My Projects', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Color(0xFFF8FAFC))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFF8FAFC),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF94A3B8)),
            onPressed: _showInfoDialog,
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _projects.isEmpty
            ? _buildEmptyState()
            : _buildProjectGrid(),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: FloatingActionButton.extended(
          onPressed: _createNewProject,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          backgroundColor: const Color(0xFF6366F1), // Indigo 500
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate 800
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155), width: 1),
            ),
            child: const Icon(Icons.draw_outlined, size: 48, color: Color(0xFF64748B)), // Slate 500
          ),
          const SizedBox(height: 24),
          const Text(
            "Your canvas is empty",
            style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap + to start a new masterpiece.",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid() {
    return GridView.builder(
      padding: EdgeInsets.only(
        left: 20, 
        right: 20, 
        top: 20, 
        bottom: MediaQuery.of(context).padding.bottom + 100
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final projectName = _projects[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Slate 800
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openProject(projectName),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  highlightColor: const Color(0xFF6366F1).withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A), // Slate 900
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF334155), width: 1),
                            ),
                            child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF818CF8), size: 28), // Indigo 400
                          ),
                          const SizedBox(height: 20),
                          Text(
                            projectName,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC), fontSize: 15, letterSpacing: -0.2),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFF64748B), size: 20), // Slate 500
                    onPressed: () => _deleteProject(projectName),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

