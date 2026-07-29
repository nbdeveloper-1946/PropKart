import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';

/// Breadcrumb navigation item
class LibraryBreadcrumb extends StatelessWidget {
  final String currentPageName;
  final VoidCallback? onBack;

  const LibraryBreadcrumb({
    super.key,
    required this.currentPageName,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CRMSpacing.m),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Text(
                'CRM',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: CRMColors.textMutedOf(context),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/library'),
              child: Text(
                'Library',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: CRMColors.textMutedOf(context),
          ),
          Text(
            currentPageName,
            style: CRMTypography.captionBold.copyWith(
              color: CRMColors.primaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simulated Drag and Drop File Upload Zone
class DragDropUploadZone extends StatefulWidget {
  final Function(String fileName, String extension, String size) onFileSelected;
  final String? initialFileName;
  final String? initialFileSize;

  const DragDropUploadZone({
    super.key,
    required this.onFileSelected,
    this.initialFileName,
    this.initialFileSize,
  });

  @override
  State<DragDropUploadZone> createState() => _DragDropUploadZoneState();
}

class _DragDropUploadZoneState extends State<DragDropUploadZone> {
  bool _isHovering = false;
  bool _isSimulatingUpload = false;
  double _uploadProgress = 0.0;
  String? _fileName;
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
    _fileSize = widget.initialFileSize;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final name = file.name;
        final ext = file.extension ?? name.split('.').last;
        final sizeBytes = file.size;
        final double sizeMB = sizeBytes / (1024 * 1024);
        final sizeStr = sizeMB > 0.1 ? '${sizeMB.toStringAsFixed(1)} MB' : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';

        setState(() {
          _isSimulatingUpload = true;
          _uploadProgress = 0.0;
          _fileName = name;
          _fileSize = sizeStr;
        });

        // Simulate a smooth modern upload progression
        for (int i = 0; i <= 10; i++) {
          await Future.delayed(const Duration(milliseconds: 120));
          if (!mounted) return;
          setState(() {
            _uploadProgress = i / 10.0;
          });
        }

        setState(() {
          _isSimulatingUpload = false;
        });

        widget.onFileSelected(name, ext, sizeStr);
      }
    } catch (e) {
      debugPrint("File picking failed: $e");
    }
  }

  void _removeFile() {
    setState(() {
      _fileName = null;
      _fileSize = null;
      _uploadProgress = 0.0;
    });
    widget.onFileSelected('', '', '');
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _fileName != null && _fileName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document File *',
          style: CRMTypography.label.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _isSimulatingUpload ? null : (hasFile ? null : _pickFile),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(CRMSpacing.xl),
              decoration: BoxDecoration(
                color: _isHovering
                    ? CRMColors.primaryOf(context).withOpacity(0.04)
                    : CRMColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                border: Border.all(
                  color: hasFile
                      ? CRMColors.primaryOf(context).withOpacity(0.5)
                      : (_isHovering ? CRMColors.primaryOf(context) : CRMColors.borderOf(context)),
                  width: _isHovering || hasFile ? 1.5 : 1.0,
                  style: hasFile ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSimulatingUpload) ...[
                    Icon(Icons.cloud_upload_rounded, color: CRMColors.primaryOf(context), size: 40),
                    const SizedBox(height: CRMSpacing.m),
                    Text(
                      'Uploading $_fileName...',
                      style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: CRMColors.borderOf(context),
                        valueColor: AlwaysStoppedAnimation<Color>(CRMColors.primaryOf(context)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ] else if (hasFile) ...[
                    Row(
                      children: [
                        FileIconHelper.getIconForExtension(_fileName!.split('.').last, size: 36),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fileName!,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.textOf(context),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _fileSize ?? 'Unknown size',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: CRMColors.danger),
                          onPressed: _removeFile,
                          tooltip: 'Remove document',
                        ),
                      ],
                    ),
                  ] else ...[
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: _isHovering ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context),
                      size: 44,
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    Text(
                      'Drag & drop document here or click to browse',
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CRMSpacing.xxs),
                    Text(
                      'Supports PDF, Word, Excel, Images, and Videos (Max 10MB)',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper to render beautiful standard file extension icons
class FileIconHelper {
  static Widget getIconForExtension(String extension, {double size = 20}) {
    final ext = extension.toLowerCase().trim();
    IconData icon;
    Color color;

    if (ext == 'pdf') {
      icon = Icons.picture_as_pdf_rounded;
      color = const Color(0xFFEF4444); // red
    } else if (ext == 'doc' || ext == 'docx') {
      icon = Icons.description_rounded;
      color = const Color(0xFF3B82F6); // blue
    } else if (ext == 'xls' || ext == 'xlsx' || ext == 'csv') {
      icon = Icons.table_chart_rounded;
      color = const Color(0xFF10B981); // green
    } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif' || ext == 'webp') {
      icon = Icons.image_rounded;
      color = const Color(0xFFF59E0B); // amber/orange
    } else if (ext == 'mp4' || ext == 'avi' || ext == 'mov' || ext == 'mkv') {
      icon = Icons.video_library_rounded;
      color = const Color(0xFF8B5CF6); // purple
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = const Color(0xFF6B7280); // gray
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}

/// Simulated document exporter loader
class DocumentExportHelper {
  static Future<void> triggerExport(BuildContext context, String exportFormat) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            decoration: BoxDecoration(
              color: CRMColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.l),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: CRMColors.primaryOf(context)),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  'Generating $exportFormat Report...',
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context)),
                ),
                const SizedBox(height: CRMSpacing.xxs),
                Text(
                  'Preparing metadata columns...',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate file generation
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('Successfully exported document index as $exportFormat!'),
            ],
          ),
          backgroundColor: CRMColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
