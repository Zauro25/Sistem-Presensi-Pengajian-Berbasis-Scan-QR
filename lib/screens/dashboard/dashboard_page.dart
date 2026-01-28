import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/attendance_record.dart';
import '../../models/study_session.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_page.dart';
import '../pengurus/session_detail_page.dart';
import '../pengurus/session_form_page.dart';
import '../peserta/scan_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.profile, super.key});
  final UserProfile profile;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.profile.role == UserRole.pengurus ? 3 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPengurus = widget.profile.role == UserRole.pengurus;
    final tabs = isPengurus
        ? const [
            Tab(text: 'Sesi'),
            Tab(text: 'Peserta'),
            Tab(text: 'Rekap'),
          ]
        : const [
            Tab(text: 'Absensi'),
            Tab(text: 'Riwayat'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${widget.profile.name}'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isPengurus
            ? [
                _SessionsTab(profile: widget.profile),
                _ParticipantsTab(),
                _ReportsTab(profile: widget.profile),
              ]
            : [
                _PesertaScanTab(profile: widget.profile),
                _HistoryTab(profile: widget.profile),
              ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<StudySession>>(
      stream: firestore.watchSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Belum ada jadwal kajian'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionFormPage(profile: profile),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Buat sesi pertama'),
                ),
              ],
            ),
          );
        }
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionCard(session: session, profile: profile);
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionFormPage(profile: profile),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Sesi baru'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.profile});
  final StudySession session;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, dd MMM yyyy HH:mm', 'id_ID').format(session.scheduledAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showQr(context),
                  tooltip: 'Tampilkan QR',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Pemateri: ${session.teacherName}'),
            Text('Lokasi: ${session.location}'),
            Text('Waktu: $dateText'),
            if (session.description != null && session.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(session.description!),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionDetailPage(session: session, profile: profile),
                  ),
                ),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Lihat presensi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQr(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('QR Absensi'),
          content: SizedBox(
            height: 240,
            width: 240,
            child: QrImageView(
              data: session.qrCode ?? session.id,
              version: QrVersions.auto,
              size: 220,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<UserProfile>>(
      stream: firestore.watchParticipants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final participants = snapshot.data ?? [];
        if (participants.isEmpty) {
          return const Center(child: Text('Belum ada peserta.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final user = participants[index];
            return ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: Text(user.displayRole),
            );
          },
        );
      },
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({required this.profile});
  final UserProfile profile;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  StudySession? _selected;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rekap Presensi'),
          const SizedBox(height: 12),
          StreamBuilder<List<StudySession>>(
            stream: firestore.watchSessions(),
            builder: (context, snapshot) {
              final sessions = snapshot.data ?? [];
              if (_selected != null && sessions.isNotEmpty) {
                final match = sessions.where((s) => s.id == _selected!.id);
                if (match.isNotEmpty) {
                  _selected = match.first;
                }
              }
              return DropdownButtonFormField<StudySession>(
                value: _selected,
                items: sessions
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selected = value),
                decoration: const InputDecoration(
                  labelText: 'Pilih sesi',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _selected == null || _exporting
                    ? null
                    : () async {
                        setState(() => _exporting = true);
                        final csv = await firestore.generateCsvForSession(_selected!.id);
                        if (!mounted) return;
                        await _showCsvDialog(context, csv);
                        setState(() => _exporting = false);
                      },
                icon: const Icon(Icons.download),
                label: Text(_exporting ? 'Memproses...' : 'Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selected != null)
            Expanded(
              child: SessionDetailPage(session: _selected!, profile: widget.profile, embedded: true),
            ),
        ],
      ),
    );
  }

  Future<void> _showCsvDialog(BuildContext context, String csv) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV dihasilkan'),
        content: SingleChildScrollView(
          child: Text(csv),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _PesertaScanTab extends StatelessWidget {
  const _PesertaScanTab({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Absen dengan QR',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tekan tombol di bawah untuk memindai QR Code sesi kajian.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanPage(profile: profile),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Pindai QR'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Riwayat terakhir',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(child: _HistoryList(profile: profile)),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _HistoryList(profile: profile),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<List<StudySession>>(
      stream: firestore.watchSessions(),
      builder: (context, sessionSnap) {
        if (sessionSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = sessionSnap.data ?? [];
        final sessionMap = {for (final s in sessions) s.id: s.title};
        return StreamBuilder<List<AttendanceRecord>>(
          stream: firestore.watchAttendanceForUser(profile.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final records = snapshot.data ?? [];
            if (records.isEmpty) {
              return const Center(child: Text('Belum ada riwayat.'));
            }
            return ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rec = records[index];
                final date = DateFormat('dd MMM yyyy HH:mm').format(rec.timestamp);
                final title = sessionMap[rec.sessionId] ?? rec.sessionId;
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('Sesi: $title'),
                  subtitle: Text('Waktu: $date'),
                );
              },
            );
          },
        );
      },
    );
  }
}
