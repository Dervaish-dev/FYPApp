import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/caregiver_service.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'package:neurocompanion_flutter/models/caregiver_models.dart';

class CaregiverAppointmentsScreen extends StatefulWidget {
  const CaregiverAppointmentsScreen({super.key});

  @override
  State<CaregiverAppointmentsScreen> createState() => _CaregiverAppointmentsScreenState();
}

class _CaregiverAppointmentsScreenState extends State<CaregiverAppointmentsScreen> {
  late CaregiverService _caregiverService;
  List<CaregiverAppointment> _appointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _caregiverService = CaregiverService(apiClient: context.read<ApiClient>());
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appointmentsData = await _caregiverService.getAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointmentsData
              .map((a) => CaregiverAppointment.fromJson(a))
              .toList()
            ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load appointments';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.card,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Appointments',
              style: TextStyle(color: theme.text),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(_error!, style: TextStyle(color: theme.text)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAppointments,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _appointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 64,
                                color: theme.text.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No appointments',
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAppointments,
                          color: theme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _appointments.length,
                            itemBuilder: (context, index) {
                              return _buildAppointmentCard(theme, _appointments[index]);
                            },
                          ),
                        ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppTheme theme, CaregiverAppointment appointment) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(appointment.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  appointment.status,
                  style: TextStyle(
                    color: _getStatusColor(appointment.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                appointment.type,
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (appointment.title != null)
            Text(
              appointment.title!,
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: theme.text.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                appointment.patientName ?? 'Patient',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: theme.text.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(appointment.scheduledDate),
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: theme.text.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                timeFormat.format(appointment.scheduledDate),
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: theme.text.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                '${appointment.duration} minutes',
                style: TextStyle(
                  color: theme.text.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (appointment.notes != null) ...[
            const SizedBox(height: 12),
            Text(
              appointment.notes!,
              style: TextStyle(
                color: theme.text.withOpacity(0.8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
