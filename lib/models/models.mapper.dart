// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'models.dart';

class TournamentStatusMapper extends EnumMapper<TournamentStatus> {
  TournamentStatusMapper._();

  static TournamentStatusMapper? _instance;
  static TournamentStatusMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TournamentStatusMapper._());
    }
    return _instance!;
  }

  static TournamentStatus fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  TournamentStatus decode(dynamic value) {
    switch (value) {
      case r'upcoming':
        return TournamentStatus.upcoming;
      case r'past':
        return TournamentStatus.past;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(TournamentStatus self) {
    switch (self) {
      case TournamentStatus.upcoming:
        return r'upcoming';
      case TournamentStatus.past:
        return r'past';
    }
  }
}

extension TournamentStatusMapperExtension on TournamentStatus {
  String toValue() {
    TournamentStatusMapper.ensureInitialized();
    return MapperContainer.globals.toValue<TournamentStatus>(this) as String;
  }
}

class MarketplaceListingMapper extends ClassMapperBase<MarketplaceListing> {
  MarketplaceListingMapper._();

  static MarketplaceListingMapper? _instance;
  static MarketplaceListingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MarketplaceListingMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MarketplaceListing';

  static String _$id(MarketplaceListing v) => v.id;
  static const Field<MarketplaceListing, String> _f$id = Field('id', _$id);
  static String _$title(MarketplaceListing v) => v.title;
  static const Field<MarketplaceListing, String> _f$title = Field(
    'title',
    _$title,
  );
  static String _$description(MarketplaceListing v) => v.description;
  static const Field<MarketplaceListing, String> _f$description = Field(
    'description',
    _$description,
  );
  static double _$price(MarketplaceListing v) => v.price;
  static const Field<MarketplaceListing, double> _f$price = Field(
    'price',
    _$price,
  );
  static String _$ownerId(MarketplaceListing v) => v.ownerId;
  static const Field<MarketplaceListing, String> _f$ownerId = Field(
    'ownerId',
    _$ownerId,
  );

  @override
  final MappableFields<MarketplaceListing> fields = const {
    #id: _f$id,
    #title: _f$title,
    #description: _f$description,
    #price: _f$price,
    #ownerId: _f$ownerId,
  };

  static MarketplaceListing _instantiate(DecodingData data) {
    return MarketplaceListing(
      id: data.dec(_f$id),
      title: data.dec(_f$title),
      description: data.dec(_f$description),
      price: data.dec(_f$price),
      ownerId: data.dec(_f$ownerId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MarketplaceListing fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MarketplaceListing>(map);
  }

  static MarketplaceListing fromJson(String json) {
    return ensureInitialized().decodeJson<MarketplaceListing>(json);
  }
}

mixin MarketplaceListingMappable {
  String toJson() {
    return MarketplaceListingMapper.ensureInitialized()
        .encodeJson<MarketplaceListing>(this as MarketplaceListing);
  }

  Map<String, dynamic> toMap() {
    return MarketplaceListingMapper.ensureInitialized()
        .encodeMap<MarketplaceListing>(this as MarketplaceListing);
  }

  MarketplaceListingCopyWith<
    MarketplaceListing,
    MarketplaceListing,
    MarketplaceListing
  >
  get copyWith =>
      _MarketplaceListingCopyWithImpl<MarketplaceListing, MarketplaceListing>(
        this as MarketplaceListing,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MarketplaceListingMapper.ensureInitialized().stringifyValue(
      this as MarketplaceListing,
    );
  }

  @override
  bool operator ==(Object other) {
    return MarketplaceListingMapper.ensureInitialized().equalsValue(
      this as MarketplaceListing,
      other,
    );
  }

  @override
  int get hashCode {
    return MarketplaceListingMapper.ensureInitialized().hashValue(
      this as MarketplaceListing,
    );
  }
}

extension MarketplaceListingValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MarketplaceListing, $Out> {
  MarketplaceListingCopyWith<$R, MarketplaceListing, $Out>
  get $asMarketplaceListing => $base.as(
    (v, t, t2) => _MarketplaceListingCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class MarketplaceListingCopyWith<
  $R,
  $In extends MarketplaceListing,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? title,
    String? description,
    double? price,
    String? ownerId,
  });
  MarketplaceListingCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _MarketplaceListingCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MarketplaceListing, $Out>
    implements MarketplaceListingCopyWith<$R, MarketplaceListing, $Out> {
  _MarketplaceListingCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MarketplaceListing> $mapper =
      MarketplaceListingMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? title,
    String? description,
    double? price,
    String? ownerId,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (title != null) #title: title,
      if (description != null) #description: description,
      if (price != null) #price: price,
      if (ownerId != null) #ownerId: ownerId,
    }),
  );
  @override
  MarketplaceListing $make(CopyWithData data) => MarketplaceListing(
    id: data.get(#id, or: $value.id),
    title: data.get(#title, or: $value.title),
    description: data.get(#description, or: $value.description),
    price: data.get(#price, or: $value.price),
    ownerId: data.get(#ownerId, or: $value.ownerId),
  );

  @override
  MarketplaceListingCopyWith<$R2, MarketplaceListing, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MarketplaceListingCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TournamentMapper extends ClassMapperBase<Tournament> {
  TournamentMapper._();

  static TournamentMapper? _instance;
  static TournamentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TournamentMapper._());
      TournamentStatusMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Tournament';

  static String _$id(Tournament v) => v.id;
  static const Field<Tournament, String> _f$id = Field('id', _$id);
  static String _$name(Tournament v) => v.name;
  static const Field<Tournament, String> _f$name = Field('name', _$name);
  static String _$location(Tournament v) => v.location;
  static const Field<Tournament, String> _f$location = Field(
    'location',
    _$location,
  );
  static DateTime _$date(Tournament v) => v.date;
  static const Field<Tournament, DateTime> _f$date = Field('date', _$date);
  static TournamentStatus _$status(Tournament v) => v.status;
  static const Field<Tournament, TournamentStatus> _f$status = Field(
    'status',
    _$status,
  );
  static String _$organizerId(Tournament v) => v.organizerId;
  static const Field<Tournament, String> _f$organizerId = Field(
    'organizerId',
    _$organizerId,
  );

  @override
  final MappableFields<Tournament> fields = const {
    #id: _f$id,
    #name: _f$name,
    #location: _f$location,
    #date: _f$date,
    #status: _f$status,
    #organizerId: _f$organizerId,
  };

  static Tournament _instantiate(DecodingData data) {
    return Tournament(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      location: data.dec(_f$location),
      date: data.dec(_f$date),
      status: data.dec(_f$status),
      organizerId: data.dec(_f$organizerId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Tournament fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Tournament>(map);
  }

  static Tournament fromJson(String json) {
    return ensureInitialized().decodeJson<Tournament>(json);
  }
}

mixin TournamentMappable {
  String toJson() {
    return TournamentMapper.ensureInitialized().encodeJson<Tournament>(
      this as Tournament,
    );
  }

  Map<String, dynamic> toMap() {
    return TournamentMapper.ensureInitialized().encodeMap<Tournament>(
      this as Tournament,
    );
  }

  TournamentCopyWith<Tournament, Tournament, Tournament> get copyWith =>
      _TournamentCopyWithImpl<Tournament, Tournament>(
        this as Tournament,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TournamentMapper.ensureInitialized().stringifyValue(
      this as Tournament,
    );
  }

  @override
  bool operator ==(Object other) {
    return TournamentMapper.ensureInitialized().equalsValue(
      this as Tournament,
      other,
    );
  }

  @override
  int get hashCode {
    return TournamentMapper.ensureInitialized().hashValue(this as Tournament);
  }
}

extension TournamentValueCopy<$R, $Out>
    on ObjectCopyWith<$R, Tournament, $Out> {
  TournamentCopyWith<$R, Tournament, $Out> get $asTournament =>
      $base.as((v, t, t2) => _TournamentCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TournamentCopyWith<$R, $In extends Tournament, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? name,
    String? location,
    DateTime? date,
    TournamentStatus? status,
    String? organizerId,
  });
  TournamentCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TournamentCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Tournament, $Out>
    implements TournamentCopyWith<$R, Tournament, $Out> {
  _TournamentCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Tournament> $mapper =
      TournamentMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? name,
    String? location,
    DateTime? date,
    TournamentStatus? status,
    String? organizerId,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (location != null) #location: location,
      if (date != null) #date: date,
      if (status != null) #status: status,
      if (organizerId != null) #organizerId: organizerId,
    }),
  );
  @override
  Tournament $make(CopyWithData data) => Tournament(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    location: data.get(#location, or: $value.location),
    date: data.get(#date, or: $value.date),
    status: data.get(#status, or: $value.status),
    organizerId: data.get(#organizerId, or: $value.organizerId),
  );

  @override
  TournamentCopyWith<$R2, Tournament, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TournamentCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayerAvailabilityMapper extends ClassMapperBase<PlayerAvailability> {
  PlayerAvailabilityMapper._();

  static PlayerAvailabilityMapper? _instance;
  static PlayerAvailabilityMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayerAvailabilityMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PlayerAvailability';

  static String _$id(PlayerAvailability v) => v.id;
  static const Field<PlayerAvailability, String> _f$id = Field('id', _$id);
  static String _$eventId(PlayerAvailability v) => v.eventId;
  static const Field<PlayerAvailability, String> _f$eventId = Field(
    'eventId',
    _$eventId,
  );
  static String _$userId(PlayerAvailability v) => v.userId;
  static const Field<PlayerAvailability, String> _f$userId = Field(
    'userId',
    _$userId,
  );
  static String _$displayName(PlayerAvailability v) => v.displayName;
  static const Field<PlayerAvailability, String> _f$displayName = Field(
    'displayName',
    _$displayName,
  );
  static String _$note(PlayerAvailability v) => v.note;
  static const Field<PlayerAvailability, String> _f$note = Field(
    'note',
    _$note,
  );

  @override
  final MappableFields<PlayerAvailability> fields = const {
    #id: _f$id,
    #eventId: _f$eventId,
    #userId: _f$userId,
    #displayName: _f$displayName,
    #note: _f$note,
  };

  static PlayerAvailability _instantiate(DecodingData data) {
    return PlayerAvailability(
      id: data.dec(_f$id),
      eventId: data.dec(_f$eventId),
      userId: data.dec(_f$userId),
      displayName: data.dec(_f$displayName),
      note: data.dec(_f$note),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayerAvailability fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayerAvailability>(map);
  }

  static PlayerAvailability fromJson(String json) {
    return ensureInitialized().decodeJson<PlayerAvailability>(json);
  }
}

mixin PlayerAvailabilityMappable {
  String toJson() {
    return PlayerAvailabilityMapper.ensureInitialized()
        .encodeJson<PlayerAvailability>(this as PlayerAvailability);
  }

  Map<String, dynamic> toMap() {
    return PlayerAvailabilityMapper.ensureInitialized()
        .encodeMap<PlayerAvailability>(this as PlayerAvailability);
  }

  PlayerAvailabilityCopyWith<
    PlayerAvailability,
    PlayerAvailability,
    PlayerAvailability
  >
  get copyWith =>
      _PlayerAvailabilityCopyWithImpl<PlayerAvailability, PlayerAvailability>(
        this as PlayerAvailability,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayerAvailabilityMapper.ensureInitialized().stringifyValue(
      this as PlayerAvailability,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayerAvailabilityMapper.ensureInitialized().equalsValue(
      this as PlayerAvailability,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayerAvailabilityMapper.ensureInitialized().hashValue(
      this as PlayerAvailability,
    );
  }
}

extension PlayerAvailabilityValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayerAvailability, $Out> {
  PlayerAvailabilityCopyWith<$R, PlayerAvailability, $Out>
  get $asPlayerAvailability => $base.as(
    (v, t, t2) => _PlayerAvailabilityCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayerAvailabilityCopyWith<
  $R,
  $In extends PlayerAvailability,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? eventId,
    String? userId,
    String? displayName,
    String? note,
  });
  PlayerAvailabilityCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayerAvailabilityCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayerAvailability, $Out>
    implements PlayerAvailabilityCopyWith<$R, PlayerAvailability, $Out> {
  _PlayerAvailabilityCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayerAvailability> $mapper =
      PlayerAvailabilityMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? eventId,
    String? userId,
    String? displayName,
    String? note,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (eventId != null) #eventId: eventId,
      if (userId != null) #userId: userId,
      if (displayName != null) #displayName: displayName,
      if (note != null) #note: note,
    }),
  );
  @override
  PlayerAvailability $make(CopyWithData data) => PlayerAvailability(
    id: data.get(#id, or: $value.id),
    eventId: data.get(#eventId, or: $value.eventId),
    userId: data.get(#userId, or: $value.userId),
    displayName: data.get(#displayName, or: $value.displayName),
    note: data.get(#note, or: $value.note),
  );

  @override
  PlayerAvailabilityCopyWith<$R2, PlayerAvailability, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayerAvailabilityCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

