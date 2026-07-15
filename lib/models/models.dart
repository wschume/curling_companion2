import 'package:dart_mappable/dart_mappable.dart';

part 'models.mapper.dart';

@MappableClass()
class MarketplaceListing with MarketplaceListingMappable {
  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.ownerId,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String ownerId;
}

@MappableClass()
class Tournament with TournamentMappable {
  const Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.city,
    this.signupDeadline,
    this.club,
    this.country,
    this.entryFee,
    this.currency,
    this.maxNumberOfTeams,
    this.websiteUrl,
    this.contactInformation,
    required this.organizerId,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String city;
  final DateTime? signupDeadline;
  final String? club;
  final String? country;
  final double? entryFee;
  final String? currency;
  final int? maxNumberOfTeams;
  final String? websiteUrl;
  final String? contactInformation;
  final String organizerId;
}

@MappableClass()
class PlayerAvailability with PlayerAvailabilityMappable {
  const PlayerAvailability({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.displayName,
    required this.note,
  });

  final String id;
  final String eventId;
  final String userId;
  final String displayName;
  final String note;
}
