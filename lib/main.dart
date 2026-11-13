import 'dart:convert';
import 'dart:typed_data';

import 'package:ecg_studio/core/csv_processor.dart';
import 'package:ecg_studio/core/ecg_processor.dart';
import 'package:ecg_studio/file_export/file_export.dart';
import 'package:ecg_studio/services/svg_to_png.dart';
import 'package:ecg_studio/widgets/app_header.dart';
import 'package:ecg_studio/widgets/control_panel.dart';
import 'package:ecg_studio/widgets/export_dialog.dart';
import 'package:ecg_studio/widgets/preview_workspace.dart';
import 'package:flutter/material.dart';

import 'file_selection/file_selection.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static const _background = Color(0xFF10131D);
  static const _surface = Color(0xFF191D2A);
  static const _accent = Color(0xFF8C7CFF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.dark,
          surface: _surface,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: _accent,
          thumbColor: Colors.white,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
          overlayColor: _accent.withValues(alpha: 0.15),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const EcgDrawerScreen(),
    );
  }
}

class EcgDrawerScreen extends StatefulWidget {
  const EcgDrawerScreen({super.key});

  @override
  State<EcgDrawerScreen> createState() => _EcgDrawerScreenState();
}

class _EcgDrawerScreenState extends State<EcgDrawerScreen> {
  static const _defaultStrokeColor = Color(0xFFE55261);

  String _svgSource = '';
  String _previewSvg = '';
  String _svgName = 'Nenhum SVG selecionado';
  List<String> _csvContents = [];
  List<String> _csvNames = [];
  List<EcgPoint> _ecgPoints = [];
  double _amplitude = 12;
  double _strokeWidth = 2.5;
  Color _strokeColor = _defaultStrokeColor;
  String? _error;

  Future<void> _pickSvg() async {
    try {
      final files = await selectFiles(
        extensions: ['svg'],
        allowMultiple: false,
      );
      if (files == null || files.isEmpty) return;
      final file = files.single;
      setState(() {
        _svgSource = utf8.decode(file.bytes);
        _svgName = file.name;
        _refreshPreview();
      });
    } catch (error) {
      _showError('Falha ao abrir o SVG: $error');
    }
  }

  Future<void> _pickCsv() async {
    try {
      final files = await selectFiles(extensions: ['csv'], allowMultiple: true);
      if (files == null || files.isEmpty) return;
      setState(() {
        _csvContents = files.map((file) => utf8.decode(file.bytes)).toList();
        _csvNames = files.map((file) => file.name).toList();
        _refreshPreview();
      });
    } catch (error) {
      _showError('Falha ao abrir os arquivos CSV: $error');
    }
  }

  void _refreshPreview() {
    if (_csvContents.isEmpty) {
      _ecgPoints = [];
      _previewSvg = '';
      _error = null;
      return;
    }
    try {
      _ecgPoints = CsvProcessor.concatenate(
        _csvContents,
        headers: List.filled(_csvContents.length, false),
        delimiters: List.filled(_csvContents.length, ';'),
      );
    } catch (error) {
      _ecgPoints = [];
      _previewSvg = '';
      _error = 'Não foi possível ler os arquivos CSV: $error';
      return;
    }

    if (_svgSource.isEmpty) {
      _previewSvg = '';
      _error = null;
      return;
    }

    try {
      final transformed = EcgProcessor.transform(
        svgXml: _svgSource,
        csvText: CsvProcessor.export(_ecgPoints),
        amplitude: _amplitude,
      );
      _previewSvg = EcgProcessor.styleSvg(
        svgXml: transformed,
        strokeColor:
            '#${_strokeColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        strokeWidth: _strokeWidth,
      );
      _error = null;
    } catch (error) {
      _previewSvg = '';
      _error = 'Não foi possível gerar a pré-visualização: $error';
    }
  }

  void _changeSettings(VoidCallback change) {
    setState(() {
      change();
      _refreshPreview();
    });
  }

  Future<void> _showExportDialog() async {
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => const ExportDialog(),
    );
    if (!mounted || format == null || _previewSvg.isEmpty) return;

    try {
      final extension = format.name;
      final bytes = format == ExportFormat.svg
          ? Uint8List.fromList(utf8.encode(_previewSvg))
          : await svgToPng(_previewSvg);
      final baseName = _svgName.replaceFirst(
        RegExp(r'\.svg$', caseSensitive: false),
        '',
      );
      final saved = await saveExport(
        fileName: '${baseName}_ecg.$extension',
        extension: extension,
        mimeType: format == ExportFormat.svg ? 'image/svg+xml' : 'image/png',
        bytes: bytes,
      );
      if (mounted && saved) {
        _showMessage('Imagem exportada como $extension.');
      }
    } catch (error) {
      _showError('Falha ao exportar a imagem: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB63F50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 940;
                  final isWidePreview = constraints.maxWidth >= 1200;
                  if (isDesktop) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 320,
                            child: SingleChildScrollView(
                              child: _buildControls(),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(child: _buildWorkspace(isWidePreview)),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      children: [
                        _buildControls(),
                        const SizedBox(height: 20),
                        _buildWorkspace(isWidePreview),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return ControlPanel(
      svgName: _svgName,
      csvNames: _csvNames,
      amplitude: _amplitude,
      strokeWidth: _strokeWidth,
      strokeColor: _strokeColor,
      error: _error,
      onPickSvg: _pickSvg,
      onPickCsv: _pickCsv,
      onAmplitudeChanged: (value) => _changeSettings(() => _amplitude = value),
      onStrokeWidthChanged: (value) =>
          _changeSettings(() => _strokeWidth = value),
      onStrokeColorChanged: (color) =>
          _changeSettings(() => _strokeColor = color),
    );
  }

  Widget _buildWorkspace(bool isWide) {
    return PreviewWorkspace(
      points: _ecgPoints,
      strokeColor: _strokeColor,
      strokeWidth: _strokeWidth,
      originalSvg: _svgSource,
      originalSvgName: _svgName,
      resultSvg: _previewSvg,
      amplitude: _amplitude,
      onExport: _showExportDialog,
      isWide: isWide,
    );
  }
}
