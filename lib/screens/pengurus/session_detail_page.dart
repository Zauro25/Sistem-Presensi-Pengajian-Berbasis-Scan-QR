import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/attendance_record.dart';
import '../../models/study_session.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({required this.session, required this.profile, this.embedded = false, super.key});

  final StudySession session;
  final UserProfile profile;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = _SessionDetailContent(session: session, profile: profile);
    if (embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: content,
    );
  }
}

class _SessionDetailContent extends StatefulWidget {
  const _SessionDetailContent({required this.session, required this.profile});
  final StudySession session;
  final UserProfile profile;

  @override
  State<_SessionDetailContent> createState() => _SessionDetailContentState();
}

class _SessionDetailContentState extends State<_SessionDetailContent> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.session.title, style: Theme.of(context).textTheme.titleMedium),
                  Text('Pemateri: ${widget.session.teacherName}'),
                  Text('Lokasi: ${widget.session.location}'),
                  Text('Jadwal: ${DateFormat('dd MMM yyyy HH:mm').format(widget.session.scheduledAt)}'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () async {
                            setState(() => _exporting = true);
                            final csv = await firestore.generateCsvForSession(widget.session.id);
                            if (!mounted) return;
                            await Share.share(csv, subject: 'Rekap ${widget.session.title}');
                            setState(() => _exporting = false);
                          },
                    icon: const Icon(Icons.file_download),
                    label: Text(_exporting ? 'Memproses...' : 'Bagikan CSV'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: firestore.watchAttendanceForSession(widget.session.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snapshot.data ?? [];
              if (records.isEmpty) {
                return const Center(child: Text('Belum ada presensi.'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Metode')),
                    DataColumn(label: Text('Waktu')),
                  ],
                  rows: records
                      .map(
                        (rec) => DataRow(cells: [
                          DataCell(Text(rec.userName)),
                          DataCell(Text(rec.method)),
                          DataCell(Text(DateFormat('dd MMM yyyy HH:mm').format(rec.timestamp))),
                        ]),
                      )
                      .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
