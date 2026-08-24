import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:superduper/src/platform/report_exporter.dart';

final class ReportActions extends StatefulWidget {
  const ReportActions({
    required this.createReport,
    this.shareLabel = 'Save or send report',
    this.copyLabel = 'Copy report',
    super.key,
  });

  final Future<ShareableReport> Function() createReport;
  final String shareLabel;
  final String copyLabel;

  @override
  State<ReportActions> createState() => _ReportActionsState();
}

final class _ReportActionsState extends State<ReportActions> {
  var _exporting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (buttonContext) => FilledButton.icon(
            onPressed: _exporting ? null : () => _shareReport(buttonContext),
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(_exporting ? 'Preparing report…' : widget.shareLabel),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _exporting ? null : _copyReport,
          icon: const Icon(Icons.copy_rounded),
          label: Text(widget.copyLabel),
        ),
      ],
    );
  }

  Future<void> _shareReport(BuildContext buttonContext) async {
    final renderBox = buttonContext.findRenderObject() as RenderBox?;
    final origin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    setState(() => _exporting = true);
    try {
      final report = await widget.createReport();
      final result = await ReportExporter.share(
        report,
        sharePositionOrigin: origin,
      );
      if (result.status == ShareResultStatus.unavailable) {
        await ReportExporter.copy(report);
        if (mounted) {
          _showMessage(
            'Sharing is unavailable here, so the report was copied instead.',
          );
        }
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Could not prepare the report: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _copyReport() async {
    setState(() => _exporting = true);
    try {
      final report = await widget.createReport();
      await ReportExporter.copy(report);
      if (mounted) {
        _showMessage('Report copied.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Could not copy the report: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
