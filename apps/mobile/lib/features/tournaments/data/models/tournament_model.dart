import '../../domain/entities/tournament.dart';

/// Tournament data model
class TournamentModel {
  final String id;
  final String name;
  final String tier;
  final DateTime startDate;
  final DateTime? endDate;
  final double? prizePool;
  final String? format;
  final String? liquipediaUrl;
  final String? logoUrl;
  final String status;
  final String? region;

  TournamentModel({
    required this.id,
    required this.name,
    required this.tier,
    required this.startDate,
    this.endDate,
    this.prizePool,
    this.format,
    this.liquipediaUrl,
    this.logoUrl,
    required this.status,
    this.region,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: json['tier'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      prizePool: json['prize_pool'] != null
          ? (json['prize_pool'] as num).toDouble()
          : null,
      format: json['format'] as String?,
      liquipediaUrl: json['liquipedia_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      status: json['status'] as String,
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'prize_pool': prizePool,
      'format': format,
      'liquipedia_url': liquipediaUrl,
      'logo_url': logoUrl,
      'status': status,
      'region': region,
    };
  }

  Tournament toEntity() {
    return Tournament(
      id: id,
      name: name,
      tier: tier,
      startDate: startDate,
      endDate: endDate,
      prizePool: prizePool,
      format: format,
      liquipediaUrl: liquipediaUrl,
      logoUrl: logoUrl,
      status: status,
      region: region,
    );
  }
}
