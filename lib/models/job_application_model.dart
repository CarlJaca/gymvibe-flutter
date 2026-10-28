import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Application status ────────────────────────────────────────────────────────

enum ApplicationStatus {
  submitted,
  underReview,
  shortlisted,
  interview,
  accepted,
  rejected,
  withdrawn,
}

String applicationStatusToString(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.submitted:
      return 'submitted';
    case ApplicationStatus.underReview:
      return 'under_review';
    case ApplicationStatus.shortlisted:
      return 'shortlisted';
    case ApplicationStatus.interview:
      return 'interview';
    case ApplicationStatus.accepted:
      return 'accepted';
    case ApplicationStatus.rejected:
      return 'rejected';
    case ApplicationStatus.withdrawn:
      return 'withdrawn';
  }
}

ApplicationStatus stringToApplicationStatus(String? value) {
  switch (value) {
    case 'under_review':
      return ApplicationStatus.underReview;
    case 'shortlisted':
      return ApplicationStatus.shortlisted;
    case 'interview':
      return ApplicationStatus.interview;
    case 'accepted':
      return ApplicationStatus.accepted;
    case 'rejected':
      return ApplicationStatus.rejected;
    case 'withdrawn':
      return ApplicationStatus.withdrawn;
    case 'submitted':
    default:
      return ApplicationStatus.submitted;
  }
}

String applicationStatusLabel(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.submitted:
      return 'Submitted';
    case ApplicationStatus.underReview:
      return 'Under Review';
    case ApplicationStatus.shortlisted:
      return 'Shortlisted';
    case ApplicationStatus.interview:
      return 'Interview';
    case ApplicationStatus.accepted:
      return 'Accepted';
    case ApplicationStatus.rejected:
      return 'Rejected';
    case ApplicationStatus.withdrawn:
      return 'Withdrawn';
  }
}

// ─── Status transition validation ──────────────────────────────────────────────

/// Map of allowed status transitions.
/// Key = current status, Value = list of allowed next statuses.
const Map<ApplicationStatus, List<ApplicationStatus>> _allowedTransitions = {
  ApplicationStatus.submitted: [
    ApplicationStatus.underReview,
    ApplicationStatus.rejected,
    ApplicationStatus.withdrawn,
  ],
  ApplicationStatus.underReview: [
    ApplicationStatus.shortlisted,
    ApplicationStatus.rejected,
    ApplicationStatus.withdrawn,
  ],
  ApplicationStatus.shortlisted: [
    ApplicationStatus.interview,
    ApplicationStatus.rejected,
  ],
  ApplicationStatus.interview: [
    ApplicationStatus.accepted,
    ApplicationStatus.rejected,
  ],
  ApplicationStatus.accepted: [],
  ApplicationStatus.rejected: [],
  ApplicationStatus.withdrawn: [],
};

/// Returns true if [from] → [to] is a valid status transition.
bool isValidStatusTransition(ApplicationStatus from, ApplicationStatus to) {
  return _allowedTransitions[from]?.contains(to) ?? false;
}

/// Statuses from which the applicant is allowed to withdraw.
bool canWithdraw(ApplicationStatus current) {
  return current == ApplicationStatus.submitted ||
      current == ApplicationStatus.underReview;
}

// ─── Model ─────────────────────────────────────────────────────────────────────

class JobApplicationModel {
  final String applicationId;
  final String jobId;
  final String jobTitle;

  final String gymId;
  final String gymName;
  final String ownerId;

  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String applicantProfileImageUrl;

  final String coverMessage;
  final String experience;
  final String education;
  final List<String> skills;
  final String availability;
  final double? expectedSalary;

  final String? resumeUrl;
  final String? resumeFileName;
  final String? supportingDocumentUrl;

  final ApplicationStatus status;

  /// Private note visible to the Gym Owner only – never shown to the applicant.
  final String? ownerNote;

  /// Rejection reason – visible to both parties.
  final String? rejectionReason;

  /// Message from the owner that the applicant can see (e.g. interview info).
  final String? applicantMessage;

  final DateTime? interviewDate;
  final String? interviewLocation;
  final String? interviewInstructions;

  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const JobApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.gymId,
    required this.gymName,
    required this.ownerId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    this.applicantProfileImageUrl = '',
    required this.coverMessage,
    this.experience = '',
    this.education = '',
    this.skills = const [],
    this.availability = '',
    this.expectedSalary,
    this.resumeUrl,
    this.resumeFileName,
    this.supportingDocumentUrl,
    this.status = ApplicationStatus.submitted,
    this.ownerNote,
    this.rejectionReason,
    this.applicantMessage,
    this.interviewDate,
    this.interviewLocation,
    this.interviewInstructions,
    this.submittedAt,
    this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  JobApplicationModel copyWith({
    String? applicationId,
    String? jobId,
    String? jobTitle,
    String? gymId,
    String? gymName,
    String? ownerId,
    String? applicantId,
    String? applicantName,
    String? applicantEmail,
    String? applicantPhone,
    String? applicantProfileImageUrl,
    String? coverMessage,
    String? experience,
    String? education,
    List<String>? skills,
    String? availability,
    double? expectedSalary,
    String? resumeUrl,
    String? resumeFileName,
    String? supportingDocumentUrl,
    ApplicationStatus? status,
    String? ownerNote,
    String? rejectionReason,
    String? applicantMessage,
    DateTime? interviewDate,
    String? interviewLocation,
    String? interviewInstructions,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return JobApplicationModel(
      applicationId: applicationId ?? this.applicationId,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      gymId: gymId ?? this.gymId,
      gymName: gymName ?? this.gymName,
      ownerId: ownerId ?? this.ownerId,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      applicantProfileImageUrl: applicantProfileImageUrl ?? this.applicantProfileImageUrl,
      coverMessage: coverMessage ?? this.coverMessage,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      supportingDocumentUrl: supportingDocumentUrl ?? this.supportingDocumentUrl,
      status: status ?? this.status,
      ownerNote: ownerNote ?? this.ownerNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      applicantMessage: applicantMessage ?? this.applicantMessage,
      interviewDate: interviewDate ?? this.interviewDate,
      interviewLocation: interviewLocation ?? this.interviewLocation,
      interviewInstructions: interviewInstructions ?? this.interviewInstructions,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'gymId': gymId,
      'gymName': gymName,
      'ownerId': ownerId,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'applicantProfileImageUrl': applicantProfileImageUrl,
      'coverMessage': coverMessage,
      'experience': experience,
      'education': education,
      'skills': skills,
      'availability': availability,
      'expectedSalary': expectedSalary,
      'resumeUrl': resumeUrl,
      'resumeFileName': resumeFileName,
      'supportingDocumentUrl': supportingDocumentUrl,
      'status': applicationStatusToString(status),
      'ownerNote': ownerNote,
      'rejectionReason': rejectionReason,
      'applicantMessage': applicantMessage,
      'interviewDate':
          interviewDate != null ? Timestamp.fromDate(interviewDate!) : null,
      'interviewLocation': interviewLocation,
      'interviewInstructions': interviewInstructions,
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  factory JobApplicationModel.fromJson(
      Map<String, dynamic> json, String documentId) {
    return JobApplicationModel(
      applicationId: documentId,
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      gymId: json['gymId'] ?? '',
      gymName: json['gymName'] ?? '',
      ownerId: json['ownerId'] ?? '',
      applicantId: json['applicantId'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantEmail: json['applicantEmail'] ?? '',
      applicantPhone: json['applicantPhone'] ?? '',
      applicantProfileImageUrl: json['applicantProfileImageUrl'] ?? '',
      coverMessage: json['coverMessage'] ?? '',
      experience: json['experience'] ?? '',
      education: json['education'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      availability: json['availability'] ?? '',
      expectedSalary: (json['expectedSalary'] as num?)?.toDouble(),
      resumeUrl: json['resumeUrl'],
      resumeFileName: json['resumeFileName'],
      supportingDocumentUrl: json['supportingDocumentUrl'],
      status: stringToApplicationStatus(json['status']),
      ownerNote: json['ownerNote'],
      rejectionReason: json['rejectionReason'],
      applicantMessage: json['applicantMessage'],
      interviewDate: _parseTimestamp(json['interviewDate']),
      interviewLocation: json['interviewLocation'],
      interviewInstructions: json['interviewInstructions'],
      submittedAt: _parseTimestamp(json['submittedAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      reviewedAt: _parseTimestamp(json['reviewedAt']),
      reviewedBy: json['reviewedBy'],
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
