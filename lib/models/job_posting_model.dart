import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ─────────────────────────────────────────────────────────────────────

enum EmploymentType { fullTime, partTime, contract, internship }

enum WorkSetup { onsite, hybrid }

enum SalaryType { fixed, range, negotiable, notDisclosed }

enum SalaryPeriod { hourly, daily, monthly }

enum JobStatus { draft, active, closed, filled, archived }

// ─── Enum helpers ──────────────────────────────────────────────────────────────

String employmentTypeToString(EmploymentType type) {
  switch (type) {
    case EmploymentType.fullTime:
      return 'full_time';
    case EmploymentType.partTime:
      return 'part_time';
    case EmploymentType.contract:
      return 'contract';
    case EmploymentType.internship:
      return 'internship';
  }
}

EmploymentType stringToEmploymentType(String? value) {
  switch (value) {
    case 'part_time':
      return EmploymentType.partTime;
    case 'contract':
      return EmploymentType.contract;
    case 'internship':
      return EmploymentType.internship;
    case 'full_time':
    default:
      return EmploymentType.fullTime;
  }
}

String employmentTypeLabel(EmploymentType type) {
  switch (type) {
    case EmploymentType.fullTime:
      return 'Full Time';
    case EmploymentType.partTime:
      return 'Part Time';
    case EmploymentType.contract:
      return 'Contract';
    case EmploymentType.internship:
      return 'Internship';
  }
}

String workSetupToString(WorkSetup setup) {
  switch (setup) {
    case WorkSetup.hybrid:
      return 'hybrid';
    case WorkSetup.onsite:
      return 'onsite';
  }
}

WorkSetup stringToWorkSetup(String? value) {
  if (value == 'hybrid') return WorkSetup.hybrid;
  return WorkSetup.onsite;
}

String workSetupLabel(WorkSetup setup) {
  switch (setup) {
    case WorkSetup.onsite:
      return 'Onsite';
    case WorkSetup.hybrid:
      return 'Hybrid';
  }
}

String salaryTypeToString(SalaryType type) {
  switch (type) {
    case SalaryType.fixed:
      return 'fixed';
    case SalaryType.range:
      return 'range';
    case SalaryType.negotiable:
      return 'negotiable';
    case SalaryType.notDisclosed:
      return 'not_disclosed';
  }
}

SalaryType stringToSalaryType(String? value) {
  switch (value) {
    case 'fixed':
      return SalaryType.fixed;
    case 'range':
      return SalaryType.range;
    case 'negotiable':
      return SalaryType.negotiable;
    case 'not_disclosed':
    default:
      return SalaryType.notDisclosed;
  }
}

String salaryPeriodToString(SalaryPeriod period) {
  switch (period) {
    case SalaryPeriod.hourly:
      return 'hourly';
    case SalaryPeriod.daily:
      return 'daily';
    case SalaryPeriod.monthly:
      return 'monthly';
  }
}

SalaryPeriod stringToSalaryPeriod(String? value) {
  switch (value) {
    case 'hourly':
      return SalaryPeriod.hourly;
    case 'daily':
      return SalaryPeriod.daily;
    case 'monthly':
    default:
      return SalaryPeriod.monthly;
  }
}

String salaryPeriodLabel(SalaryPeriod period) {
  switch (period) {
    case SalaryPeriod.hourly:
      return '/hr';
    case SalaryPeriod.daily:
      return '/day';
    case SalaryPeriod.monthly:
      return '/mo';
  }
}

String jobStatusToString(JobStatus status) {
  switch (status) {
    case JobStatus.draft:
      return 'draft';
    case JobStatus.active:
      return 'active';
    case JobStatus.closed:
      return 'closed';
    case JobStatus.filled:
      return 'filled';
    case JobStatus.archived:
      return 'archived';
  }
}

JobStatus stringToJobStatus(String? value) {
  switch (value) {
    case 'active':
      return JobStatus.active;
    case 'closed':
      return JobStatus.closed;
    case 'filled':
      return JobStatus.filled;
    case 'archived':
      return JobStatus.archived;
    case 'draft':
    default:
      return JobStatus.draft;
  }
}

String jobStatusLabel(JobStatus status) {
  switch (status) {
    case JobStatus.draft:
      return 'Draft';
    case JobStatus.active:
      return 'Active';
    case JobStatus.closed:
      return 'Closed';
    case JobStatus.filled:
      return 'Filled';
    case JobStatus.archived:
      return 'Archived';
  }
}

// ─── Job categories ────────────────────────────────────────────────────────────

const List<String> jobCategories = [
  'Fitness Trainer',
  'Personal Trainer',
  'Gym Instructor',
  'Group Class Instructor',
  'Receptionist',
  'Membership Staff',
  'Gym Assistant',
  'Maintenance Staff',
  'Social Media Assistant',
  'Nutrition Assistant',
  'Other',
];

// ─── Model ─────────────────────────────────────────────────────────────────────

class JobPostingModel {
  final String jobId;
  final String gymId;
  final String ownerId;
  final String gymName;
  final String gymLogoUrl;

  final String jobTitle;
  final String jobCategory;
  final EmploymentType employmentType;
  final WorkSetup workSetup;
  final String location;

  final String description;
  final List<String> responsibilities;
  final List<String> qualifications;
  final List<String> requiredSkills;

  final SalaryType salaryType;
  final double? minimumSalary;
  final double? maximumSalary;
  final SalaryPeriod? salaryPeriod;
  final List<String> benefits;

  final int numberOfOpenings;
  final DateTime? applicationDeadline;

  final JobStatus status;
  final int applicationCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;

  const JobPostingModel({
    required this.jobId,
    required this.gymId,
    required this.ownerId,
    required this.gymName,
    required this.gymLogoUrl,
    required this.jobTitle,
    required this.jobCategory,
    required this.employmentType,
    required this.workSetup,
    required this.location,
    required this.description,
    this.responsibilities = const [],
    this.qualifications = const [],
    this.requiredSkills = const [],
    required this.salaryType,
    this.minimumSalary,
    this.maximumSalary,
    this.salaryPeriod,
    this.benefits = const [],
    this.numberOfOpenings = 1,
    this.applicationDeadline,
    this.status = JobStatus.draft,
    this.applicationCount = 0,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  /// Whether this posting is past its application deadline.
  bool get isExpired =>
      applicationDeadline != null && applicationDeadline!.isBefore(DateTime.now());

  /// Human-readable salary string.
  String get salaryDisplay {
    switch (salaryType) {
      case SalaryType.negotiable:
        return 'Negotiable';
      case SalaryType.notDisclosed:
        return 'Not Disclosed';
      case SalaryType.fixed:
        final period = salaryPeriod != null ? salaryPeriodLabel(salaryPeriod!) : '';
        return '₱${minimumSalary?.toStringAsFixed(0) ?? '0'}$period';
      case SalaryType.range:
        final period = salaryPeriod != null ? salaryPeriodLabel(salaryPeriod!) : '';
        return '₱${minimumSalary?.toStringAsFixed(0) ?? '0'} – ₱${maximumSalary?.toStringAsFixed(0) ?? '0'}$period';
    }
  }

  JobPostingModel copyWith({
    String? jobId,
    String? gymId,
    String? ownerId,
    String? gymName,
    String? gymLogoUrl,
    String? jobTitle,
    String? jobCategory,
    EmploymentType? employmentType,
    WorkSetup? workSetup,
    String? location,
    String? description,
    List<String>? responsibilities,
    List<String>? qualifications,
    List<String>? requiredSkills,
    SalaryType? salaryType,
    double? minimumSalary,
    double? maximumSalary,
    SalaryPeriod? salaryPeriod,
    List<String>? benefits,
    int? numberOfOpenings,
    DateTime? applicationDeadline,
    JobStatus? status,
    int? applicationCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return JobPostingModel(
      jobId: jobId ?? this.jobId,
      gymId: gymId ?? this.gymId,
      ownerId: ownerId ?? this.ownerId,
      gymName: gymName ?? this.gymName,
      gymLogoUrl: gymLogoUrl ?? this.gymLogoUrl,
      jobTitle: jobTitle ?? this.jobTitle,
      jobCategory: jobCategory ?? this.jobCategory,
      employmentType: employmentType ?? this.employmentType,
      workSetup: workSetup ?? this.workSetup,
      location: location ?? this.location,
      description: description ?? this.description,
      responsibilities: responsibilities ?? this.responsibilities,
      qualifications: qualifications ?? this.qualifications,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      salaryType: salaryType ?? this.salaryType,
      minimumSalary: minimumSalary ?? this.minimumSalary,
      maximumSalary: maximumSalary ?? this.maximumSalary,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      benefits: benefits ?? this.benefits,
      numberOfOpenings: numberOfOpenings ?? this.numberOfOpenings,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      status: status ?? this.status,
      applicationCount: applicationCount ?? this.applicationCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'jobId': jobId,
      'gymId': gymId,
      'ownerId': ownerId,
      'gymName': gymName,
      'gymLogoUrl': gymLogoUrl,
      'jobTitle': jobTitle,
      'jobCategory': jobCategory,
      'employmentType': employmentTypeToString(employmentType),
      'workSetup': workSetupToString(workSetup),
      'location': location,
      'description': description,
      'responsibilities': responsibilities,
      'qualifications': qualifications,
      'requiredSkills': requiredSkills,
      'salaryType': salaryTypeToString(salaryType),
      'benefits': benefits,
      'numberOfOpenings': numberOfOpenings,
      'applicationDeadline':
          applicationDeadline != null ? Timestamp.fromDate(applicationDeadline!) : null,
      'status': jobStatusToString(status),
      'applicationCount': applicationCount,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
    };

    // Only include salary fields when relevant
    if (salaryType == SalaryType.fixed || salaryType == SalaryType.range) {
      data['minimumSalary'] = minimumSalary;
      if (salaryType == SalaryType.range) {
        data['maximumSalary'] = maximumSalary;
      }
      if (salaryPeriod != null) {
        data['salaryPeriod'] = salaryPeriodToString(salaryPeriod!);
      }
    }

    return data;
  }

  factory JobPostingModel.fromJson(Map<String, dynamic> json, String documentId) {
    return JobPostingModel(
      jobId: documentId,
      gymId: json['gymId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      gymName: json['gymName'] ?? '',
      gymLogoUrl: json['gymLogoUrl'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      jobCategory: json['jobCategory'] ?? '',
      employmentType: stringToEmploymentType(json['employmentType']),
      workSetup: stringToWorkSetup(json['workSetup']),
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      qualifications: List<String>.from(json['qualifications'] ?? []),
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      salaryType: stringToSalaryType(json['salaryType']),
      minimumSalary: (json['minimumSalary'] as num?)?.toDouble(),
      maximumSalary: (json['maximumSalary'] as num?)?.toDouble(),
      salaryPeriod:
          json['salaryPeriod'] != null ? stringToSalaryPeriod(json['salaryPeriod']) : null,
      benefits: List<String>.from(json['benefits'] ?? []),
      numberOfOpenings: json['numberOfOpenings'] ?? 1,
      applicationDeadline: _parseTimestamp(json['applicationDeadline']),
      status: stringToJobStatus(json['status']),
      applicationCount: json['applicationCount'] ?? 0,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      closedAt: _parseTimestamp(json['closedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
