import 'package:equatable/equatable.dart';

// Patient Model for Caregiver View
class CaregiverPatient extends Equatable {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? neurotype;
  final DateTime? lastActive;
  final String? currentMood;
  final double? moodScore;

  const CaregiverPatient({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.neurotype,
    this.lastActive,
    this.currentMood,
    this.moodScore,
  });

  @override
  List<Object?> get props => [id, name, email, age, neurotype, lastActive, currentMood, moodScore];

  factory CaregiverPatient.fromJson(Map<String, dynamic> json) {
    return CaregiverPatient(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'],
      neurotype: json['neurotype'],
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
      currentMood: json['currentMood'],
      moodScore: json['moodScore']?.toDouble(),
    );
  }
}

// Message Model
class CaregiverMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderModel;
  final String recipientId;
  final String recipientModel;
  final String message;
  final String? subject;
  final String priority;
  final bool isRead;
  final DateTime createdAt;

  const CaregiverMessage({
    required this.id,
    required this.senderId,
    required this.senderModel,
    required this.recipientId,
    required this.recipientModel,
    required this.message,
    this.subject,
    required this.priority,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, senderId, recipientId, message, isRead, createdAt];

  factory CaregiverMessage.fromJson(Map<String, dynamic> json) {
    return CaregiverMessage(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['sender'] ?? '',
      senderModel: json['senderModel'] ?? 'User',
      recipientId: json['recipient'] ?? '',
      recipientModel: json['recipientModel'] ?? 'User',
      message: json['message'] ?? '',
      subject: json['subject'],
      priority: json['priority'] ?? 'normal',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

// Appointment Model
class CaregiverAppointment extends Equatable {
  final String id;
  final String caregiverId;
  final String patientId;
  final String? patientName;
  final DateTime scheduledDate;
  final int duration;
  final String type;
  final String? title;
  final String? notes;
  final String? meetingLink;
  final String status;
  final DateTime createdAt;

  const CaregiverAppointment({
    required this.id,
    required this.caregiverId,
    required this.patientId,
    this.patientName,
    required this.scheduledDate,
    required this.duration,
    required this.type,
    this.title,
    this.notes,
    this.meetingLink,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, caregiverId, patientId, scheduledDate, status];

  factory CaregiverAppointment.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    return CaregiverAppointment(
      id: json['_id'] ?? json['id'] ?? '',
      caregiverId: json['caregiver'] ?? '',
      patientId: patient is Map ? (patient['_id'] ?? patient['id'] ?? '') : patient ?? '',
      patientName: patient is Map ? patient['name'] : null,
      scheduledDate: json['scheduledDate'] != null 
          ? DateTime.parse(json['scheduledDate']) 
          : DateTime.now(),
      duration: json['duration'] ?? 60,
      type: json['type'] ?? 'check-in',
      title: json['title'],
      notes: json['notes'],
      meetingLink: json['meetingLink'],
      status: json['status'] ?? 'scheduled',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
