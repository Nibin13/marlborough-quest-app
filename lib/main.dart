import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/speech_service.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MarlboroughQuestApp());
}

class MarlboroughQuestApp extends StatelessWidget {
  const MarlboroughQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marlborough Quest | Voice Assistance Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE52535),
          secondary: Color(0xFF8A1528),
          surface: Colors.white,
          onSurface: Color(0xFF0F172A),
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const ProfessionalEloquentScreen(),
    );
  }
}

class ProfessionalEloquentScreen extends StatefulWidget {
  const ProfessionalEloquentScreen({super.key});

  @override
  State<ProfessionalEloquentScreen> createState() => _ProfessionalEloquentScreenState();
}

class _ProfessionalEloquentScreenState extends State<ProfessionalEloquentScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _rawTextController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isListening = false;
  bool _isProcessing = false;
  bool _isPlayingAudio = false;
  String _selectedMode = 'sentences';
  String _selectedTone = 'professional';
  final String _selectedLength = 'standard';
  String _interimTranscript = '';

  PurifyResult? _lastResult;
  List<PresetSample> _presets = [];
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _modes = [
    {'id': 'sentences', 'label': 'Sentences', 'icon': Icons.short_text_rounded},
    {'id': 'bullets', 'label': 'Bullet Points', 'icon': Icons.format_list_bulleted_rounded},
    {'id': 'meeting', 'label': 'Meeting Notes', 'icon': Icons.checklist_rounded},
    {'id': 'email', 'label': 'Draft Email', 'icon': Icons.mail_outline_rounded},
    {'id': 'social', 'label': 'Social Post', 'icon': Icons.share_rounded},
    {'id': 'brief', 'label': 'TL;DR Brief', 'icon': Icons.bolt_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadPresets();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rawTextController.dispose();
    _apiKeyController.dispose();
    SpeechService.stopListening();
    SpeechService.stopSpeaking();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    final list = await ApiService.fetchPresets();
    if (mounted) {
      setState(() {
        _presets = list;
      });
    }
  }

  void _toggleListening() {
    if (_isListening) {
      SpeechService.stopListening();
      setState(() {
        _isListening = false;
      });
      if (_rawTextController.text.trim().isNotEmpty) {
        _purifyText();
      }
    } else {
      setState(() {
        _isListening = true;
        _interimTranscript = '';
      });

      final ok = SpeechService.startListening(
        onResult: (result) {
          if (mounted) {
            setState(() {
              if (result.finalTranscript.isNotEmpty) {
                final current = _rawTextController.text;
                _rawTextController.text = current.isEmpty
                    ? result.finalTranscript
                    : '$current ${result.finalTranscript}';
              }
              _interimTranscript = result.interimTranscript;
            });
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        onStatusChange: (listening) {
          if (mounted) {
            setState(() {
              _isListening = listening;
            });
          }
        },
      );

      if (!ok) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  Future<void> _purifyText() async {
    final text = _rawTextController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final res = await ApiService.purifySpeech(
      rawText: text,
      mode: _selectedMode,
      tone: _selectedTone,
      length: _selectedLength,
      apiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _lastResult = res;
        _isProcessing = false;
      });
    }
  }

  void _loadPreset(PresetSample p) {
    setState(() {
      _rawTextController.text = p.rawText;
      _selectedMode = p.recommendedMode;
      _selectedTone = p.tone;
    });
    _purifyText();
  }

  void _togglePlayAudio() {
    if (_lastResult == null) return;
    if (_isPlayingAudio) {
      SpeechService.stopSpeaking();
      setState(() {
        _isPlayingAudio = false;
      });
    } else {
      SpeechService.speakText(_lastResult!.purifiedText);
      setState(() {
        _isPlayingAudio = true;
      });
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _isPlayingAudio = false;
          });
        }
      });
    }
  }

  void _copyToClipboard() {
    if (_lastResult == null) return;
    Clipboard.setData(ClipboardData(text: _lastResult!.purifiedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isMobile),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: isMobile ? _buildMobileView() : _buildDesktopDashboard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 54,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: isMobile ? 32 : 38,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Row(
                children: [
                  Text(
                    'marlborough ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE52535),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'quest',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A1528),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              isMobile ? 'Voice Demo' : 'Voice Assistance Demo',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE52535),
              ),
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFE52535)),
                  SizedBox(width: 4),
                  Text(
                    'Powered by Google Gemma',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 20),
            tooltip: 'Settings',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MOBILE VIEW: Natural vertical flow without nested unbounded layout issues
  // =========================================================================
  Widget _buildMobileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sample Presets Bar
          _buildPresetsBar(),
          const SizedBox(height: 12),

          // Dictation Card
          _buildMobileDictationCard(),
          const SizedBox(height: 14),

          // Output Format Pills & Tone
          _buildFormatSelector(isMobile: true),
          const SizedBox(height: 12),

          // Result Card
          _buildMobileResultCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMobileDictationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening ? const Color(0xFFE52535) : const Color(0xFFE2E8F0),
          width: _isListening ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 16,
                color: _isListening ? const Color(0xFFE52535) : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
              Text(
                _isListening ? 'RECORDING IN PROGRESS...' : 'SPOKEN DICTATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _isListening ? const Color(0xFFE52535) : const Color(0xFF475569),
                ),
              ),
              const Spacer(),
              if (_rawTextController.text.isNotEmpty)
                InkWell(
                  onTap: () {
                    setState(() {
                      _rawTextController.clear();
                      _interimTranscript = '';
                      _lastResult = null;
                    });
                  },
                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Input area with fixed minimum height
          Container(
            constraints: const BoxConstraints(minHeight: 90, maxHeight: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _rawTextController,
              maxLines: null,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening... Speak naturally (fillers will be polished).'
                    : 'Tap the mic to dictate, or tap a sample above...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_interimTranscript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$_interimTranscript...',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFE52535)),
              ),
            ),
          const SizedBox(height: 10),

          // Action row
          Row(
            children: [
              _buildMicrophoneButton(size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: _isListening
                    ? _buildSoundWaves()
                    : const Text(
                        'Tap mic to record voice',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
              ),
              if (_rawTextController.text.isNotEmpty && !_isListening)
                ElevatedButton(
                  onPressed: _purifyText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE52535),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  ),
                  child: const Text('Polish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileResultCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFE52535)),
              const SizedBox(width: 6),
              const Text(
                'POLISHED RESULT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              if (_lastResult != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    '+${_lastResult!.clarityBoostPercent}% Clarity',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Output text container
          Container(
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _buildOutputBody(),
          ),
          const SizedBox(height: 10),

          // Bottom Action Row
          if (_lastResult != null)
            Row(
              children: [
                if (_lastResult!.fillerCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      '${_lastResult!.fillerCount} Fillers Removed',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE52535)),
                    ),
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _togglePlayAudio,
                  icon: Icon(_isPlayingAudio ? Icons.stop_rounded : Icons.volume_up_rounded, size: 13),
                  label: Text(_isPlayingAudio ? 'Stop' : 'Listen', style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 13),
                  label: const Text('Copy', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE52535),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // DESKTOP DASHBOARD (Fits on PC screens without page scrolling)
  // =========================================================================
  Widget _buildDesktopDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _buildDesktopLeftCard(),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: _buildDesktopRightCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLeftCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_none_rounded, size: 16, color: Color(0xFFE52535)),
              const SizedBox(width: 6),
              const Text(
                'SPOKEN DICTATION',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              if (_rawTextController.text.isNotEmpty)
                InkWell(
                  onTap: () {
                    setState(() {
                      _rawTextController.clear();
                      _interimTranscript = '';
                      _lastResult = null;
                    });
                  },
                  child: const Text('Clear', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPresetsBar(),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isListening ? const Color(0xFFE52535) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rawTextController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? 'Listening... Speak naturally (fillers will be polished).'
                            : 'Click the red microphone to dictate, or select a sample above...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_interimTranscript.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$_interimTranscript...',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFFE52535)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildMicrophoneButton(size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isListening ? 'Recording in progress...' : 'One-Tap Voice Dictation',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isListening ? const Color(0xFFE52535) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _isListening
                          ? _buildSoundWaves()
                          : const Text(
                              'Converts raw speech into clean executive text',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                    ],
                  ),
                ),
                if (_rawTextController.text.isNotEmpty && !_isListening)
                  ElevatedButton(
                    onPressed: _purifyText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE52535),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    child: const Text('Polish Text', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFE52535)),
                  SizedBox(width: 6),
                  Text(
                    'POLISHED RESULT',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              _buildToneDropdown(),
            ],
          ),
          const SizedBox(height: 10),
          _buildFormatSelector(isMobile: false),
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _buildOutputBody(),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              if (_lastResult != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    '+${_lastResult!.clarityBoostPercent}% Clarity',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ),
                const SizedBox(width: 6),
                if (_lastResult!.fillerCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      '${_lastResult!.fillerCount} Fillers Removed',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFE52535)),
                    ),
                  ),
              ],
              const Spacer(),
              if (_lastResult != null) ...[
                OutlinedButton.icon(
                  onPressed: _togglePlayAudio,
                  icon: Icon(_isPlayingAudio ? Icons.stop_rounded : Icons.volume_up_rounded, size: 14),
                  label: Text(_isPlayingAudio ? 'Stop' : 'Listen', style: const TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 13),
                  label: const Text('Copy', style: TextStyle(fontSize: 11.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE52535),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Shared Presets Bar
  Widget _buildPresetsBar() {
    if (_presets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final p = _presets[index];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _loadPreset(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE52535),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Shared Output Format Selector
  Widget _buildFormatSelector({required bool isMobile}) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _modes.map((m) {
                final isSelected = _selectedMode == m['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedMode = m['id'] as String;
                      });
                      if (_rawTextController.text.trim().isNotEmpty) {
                        _purifyText();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE52535) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            m['icon'] as IconData,
                            size: 13,
                            color: isSelected ? const Color(0xFFE52535) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            m['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFFE52535) : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildToneDropdown(),
      ],
    );
  }

  Widget _buildOutputBody() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFE52535)),
            SizedBox(height: 10),
            Text(
              'Polishing speech with Google Gemma...',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (_lastResult == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 36, color: const Color(0xFF94A3B8).withValues(alpha: 0.6)),
            const SizedBox(height: 6),
            const Text(
              'No transcript polished yet',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 2),
            const Text(
              'Speak into the microphone or tap a sample preset.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return SelectableText(
      _lastResult!.purifiedText,
      style: const TextStyle(
        fontSize: 14,
        height: 1.55,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildToneDropdown() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTone,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 16),
          style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
          items: const [
            DropdownMenuItem(value: 'professional', child: Text('Professional')),
            DropdownMenuItem(value: 'casual', child: Text('Casual')),
            DropdownMenuItem(value: 'executive', child: Text('Executive')),
            DropdownMenuItem(value: 'direct', child: Text('Direct')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedTone = val;
              });
              if (_rawTextController.text.trim().isNotEmpty) {
                _purifyText();
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton({double size = 38}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleListening,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE52535),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE52535).withValues(
                    alpha: _isListening ? 0.35 + (_pulseController.value * 0.3) : 0.2,
                  ),
                  blurRadius: _isListening ? 14 + (_pulseController.value * 6) : 8,
                  spreadRadius: _isListening ? _pulseController.value * 3 : 0,
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: size * 0.52,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoundWaves() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Row(
          children: List.generate(8, (index) {
            final wave = (index % 3 == 0)
                ? _pulseController.value * 12
                : ((index % 2 == 0)
                    ? (1.0 - _pulseController.value) * 9
                    : _pulseController.value * 6);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2.5,
              height: 4 + wave,
              decoration: BoxDecoration(
                color: const Color(0xFFE52535),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Configuration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Google AI Studio Key (Optional):',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter API Key (optional)',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Leave empty to use the built-in local Gemma speech engine.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFE52535))),
            ),
          ],
        );
      },
    );
  }
}
