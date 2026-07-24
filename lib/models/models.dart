import 'package:dart_mappable/dart_mappable.dart';

part 'models.mapper.dart';

@MappableClass()
class MarketplaceListing with MarketplaceListingMappable {
  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'EUR',
    this.category = 'other',
    this.location = '',
    this.sellerName = '',
    this.sellerContact = '',
    this.listedAt,
    required this.ownerId,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String category;
  final String location;
  final String sellerName;
  final String sellerContact;
  final DateTime? listedAt;
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

@MappableClass()
class TeamPlayerSearch with TeamPlayerSearchMappable {
  const TeamPlayerSearch({
    required this.id,
    required this.tournamentId,
    required this.role,
    required this.contact,
    required this.ownerId,
  });

  final String id;
  final String tournamentId;
  final String role;
  final String contact;
  final String ownerId;
}

@MappableClass()
class PlayerTeamSearch with PlayerTeamSearchMappable {
  const PlayerTeamSearch({
    required this.id,
    required this.tournamentId,
    required this.role,
    required this.contact,
    required this.ownerId,
  });

  final String id;
  final String tournamentId;
  final String role;
  final String contact;
  final String ownerId;
}
