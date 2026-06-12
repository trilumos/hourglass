// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionMode, int> mode =
      GeneratedColumn<int>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<SessionMode>($SessionsTable.$convertermode);
  static const VerificationMeta _intentionMeta = const VerificationMeta(
    'intention',
  );
  @override
  late final GeneratedColumn<String> intention = GeneratedColumn<String>(
    'intention',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _plannedSecondsMeta = const VerificationMeta(
    'plannedSeconds',
  );
  @override
  late final GeneratedColumn<int> plannedSeconds = GeneratedColumn<int>(
    'planned_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedSecondsMeta = const VerificationMeta(
    'recordedSeconds',
  );
  @override
  late final GeneratedColumn<int> recordedSeconds = GeneratedColumn<int>(
    'recorded_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _abandonedMeta = const VerificationMeta(
    'abandoned',
  );
  @override
  late final GeneratedColumn<bool> abandoned = GeneratedColumn<bool>(
    'abandoned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("abandoned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _autoContinueMeta = const VerificationMeta(
    'autoContinue',
  );
  @override
  late final GeneratedColumn<bool> autoContinue = GeneratedColumn<bool>(
    'auto_continue',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_continue" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _soundscapeMeta = const VerificationMeta(
    'soundscape',
  );
  @override
  late final GeneratedColumn<String> soundscape = GeneratedColumn<String>(
    'soundscape',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sand'),
  );
  static const VerificationMeta _skinIdMeta = const VerificationMeta('skinId');
  @override
  late final GeneratedColumn<String> skinId = GeneratedColumn<String>(
    'skin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('classic'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    mode,
    intention,
    plannedSeconds,
    recordedSeconds,
    completed,
    abandoned,
    autoContinue,
    soundscape,
    skinId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('intention')) {
      context.handle(
        _intentionMeta,
        intention.isAcceptableOrUnknown(data['intention']!, _intentionMeta),
      );
    }
    if (data.containsKey('planned_seconds')) {
      context.handle(
        _plannedSecondsMeta,
        plannedSeconds.isAcceptableOrUnknown(
          data['planned_seconds']!,
          _plannedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedSecondsMeta);
    }
    if (data.containsKey('recorded_seconds')) {
      context.handle(
        _recordedSecondsMeta,
        recordedSeconds.isAcceptableOrUnknown(
          data['recorded_seconds']!,
          _recordedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedSecondsMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('abandoned')) {
      context.handle(
        _abandonedMeta,
        abandoned.isAcceptableOrUnknown(data['abandoned']!, _abandonedMeta),
      );
    }
    if (data.containsKey('auto_continue')) {
      context.handle(
        _autoContinueMeta,
        autoContinue.isAcceptableOrUnknown(
          data['auto_continue']!,
          _autoContinueMeta,
        ),
      );
    }
    if (data.containsKey('soundscape')) {
      context.handle(
        _soundscapeMeta,
        soundscape.isAcceptableOrUnknown(data['soundscape']!, _soundscapeMeta),
      );
    }
    if (data.containsKey('skin_id')) {
      context.handle(
        _skinIdMeta,
        skinId.isAcceptableOrUnknown(data['skin_id']!, _skinIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      mode: $SessionsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}mode'],
        )!,
      ),
      intention: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intention'],
      )!,
      plannedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_seconds'],
      )!,
      recordedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_seconds'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      abandoned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}abandoned'],
      )!,
      autoContinue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_continue'],
      )!,
      soundscape: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soundscape'],
      )!,
      skinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skin_id'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionMode, int, int> $convertermode =
      const EnumIndexConverter<SessionMode>(SessionMode.values);
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final DateTime startedAt;
  final SessionMode mode;
  final String intention;
  final int plannedSeconds;
  final int recordedSeconds;
  final bool completed;
  final bool abandoned;
  final bool autoContinue;
  final String soundscape;
  final String skinId;
  const Session({
    required this.id,
    required this.startedAt,
    required this.mode,
    required this.intention,
    required this.plannedSeconds,
    required this.recordedSeconds,
    required this.completed,
    required this.abandoned,
    required this.autoContinue,
    required this.soundscape,
    required this.skinId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    {
      map['mode'] = Variable<int>($SessionsTable.$convertermode.toSql(mode));
    }
    map['intention'] = Variable<String>(intention);
    map['planned_seconds'] = Variable<int>(plannedSeconds);
    map['recorded_seconds'] = Variable<int>(recordedSeconds);
    map['completed'] = Variable<bool>(completed);
    map['abandoned'] = Variable<bool>(abandoned);
    map['auto_continue'] = Variable<bool>(autoContinue);
    map['soundscape'] = Variable<String>(soundscape);
    map['skin_id'] = Variable<String>(skinId);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      mode: Value(mode),
      intention: Value(intention),
      plannedSeconds: Value(plannedSeconds),
      recordedSeconds: Value(recordedSeconds),
      completed: Value(completed),
      abandoned: Value(abandoned),
      autoContinue: Value(autoContinue),
      soundscape: Value(soundscape),
      skinId: Value(skinId),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      mode: $SessionsTable.$convertermode.fromJson(
        serializer.fromJson<int>(json['mode']),
      ),
      intention: serializer.fromJson<String>(json['intention']),
      plannedSeconds: serializer.fromJson<int>(json['plannedSeconds']),
      recordedSeconds: serializer.fromJson<int>(json['recordedSeconds']),
      completed: serializer.fromJson<bool>(json['completed']),
      abandoned: serializer.fromJson<bool>(json['abandoned']),
      autoContinue: serializer.fromJson<bool>(json['autoContinue']),
      soundscape: serializer.fromJson<String>(json['soundscape']),
      skinId: serializer.fromJson<String>(json['skinId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'mode': serializer.toJson<int>(
        $SessionsTable.$convertermode.toJson(mode),
      ),
      'intention': serializer.toJson<String>(intention),
      'plannedSeconds': serializer.toJson<int>(plannedSeconds),
      'recordedSeconds': serializer.toJson<int>(recordedSeconds),
      'completed': serializer.toJson<bool>(completed),
      'abandoned': serializer.toJson<bool>(abandoned),
      'autoContinue': serializer.toJson<bool>(autoContinue),
      'soundscape': serializer.toJson<String>(soundscape),
      'skinId': serializer.toJson<String>(skinId),
    };
  }

  Session copyWith({
    int? id,
    DateTime? startedAt,
    SessionMode? mode,
    String? intention,
    int? plannedSeconds,
    int? recordedSeconds,
    bool? completed,
    bool? abandoned,
    bool? autoContinue,
    String? soundscape,
    String? skinId,
  }) => Session(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    mode: mode ?? this.mode,
    intention: intention ?? this.intention,
    plannedSeconds: plannedSeconds ?? this.plannedSeconds,
    recordedSeconds: recordedSeconds ?? this.recordedSeconds,
    completed: completed ?? this.completed,
    abandoned: abandoned ?? this.abandoned,
    autoContinue: autoContinue ?? this.autoContinue,
    soundscape: soundscape ?? this.soundscape,
    skinId: skinId ?? this.skinId,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      mode: data.mode.present ? data.mode.value : this.mode,
      intention: data.intention.present ? data.intention.value : this.intention,
      plannedSeconds: data.plannedSeconds.present
          ? data.plannedSeconds.value
          : this.plannedSeconds,
      recordedSeconds: data.recordedSeconds.present
          ? data.recordedSeconds.value
          : this.recordedSeconds,
      completed: data.completed.present ? data.completed.value : this.completed,
      abandoned: data.abandoned.present ? data.abandoned.value : this.abandoned,
      autoContinue: data.autoContinue.present
          ? data.autoContinue.value
          : this.autoContinue,
      soundscape: data.soundscape.present
          ? data.soundscape.value
          : this.soundscape,
      skinId: data.skinId.present ? data.skinId.value : this.skinId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('mode: $mode, ')
          ..write('intention: $intention, ')
          ..write('plannedSeconds: $plannedSeconds, ')
          ..write('recordedSeconds: $recordedSeconds, ')
          ..write('completed: $completed, ')
          ..write('abandoned: $abandoned, ')
          ..write('autoContinue: $autoContinue, ')
          ..write('soundscape: $soundscape, ')
          ..write('skinId: $skinId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    mode,
    intention,
    plannedSeconds,
    recordedSeconds,
    completed,
    abandoned,
    autoContinue,
    soundscape,
    skinId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.mode == this.mode &&
          other.intention == this.intention &&
          other.plannedSeconds == this.plannedSeconds &&
          other.recordedSeconds == this.recordedSeconds &&
          other.completed == this.completed &&
          other.abandoned == this.abandoned &&
          other.autoContinue == this.autoContinue &&
          other.soundscape == this.soundscape &&
          other.skinId == this.skinId);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<SessionMode> mode;
  final Value<String> intention;
  final Value<int> plannedSeconds;
  final Value<int> recordedSeconds;
  final Value<bool> completed;
  final Value<bool> abandoned;
  final Value<bool> autoContinue;
  final Value<String> soundscape;
  final Value<String> skinId;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.mode = const Value.absent(),
    this.intention = const Value.absent(),
    this.plannedSeconds = const Value.absent(),
    this.recordedSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    this.abandoned = const Value.absent(),
    this.autoContinue = const Value.absent(),
    this.soundscape = const Value.absent(),
    this.skinId = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    required SessionMode mode,
    this.intention = const Value.absent(),
    required int plannedSeconds,
    required int recordedSeconds,
    this.completed = const Value.absent(),
    this.abandoned = const Value.absent(),
    this.autoContinue = const Value.absent(),
    this.soundscape = const Value.absent(),
    this.skinId = const Value.absent(),
  }) : startedAt = Value(startedAt),
       mode = Value(mode),
       plannedSeconds = Value(plannedSeconds),
       recordedSeconds = Value(recordedSeconds);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<int>? mode,
    Expression<String>? intention,
    Expression<int>? plannedSeconds,
    Expression<int>? recordedSeconds,
    Expression<bool>? completed,
    Expression<bool>? abandoned,
    Expression<bool>? autoContinue,
    Expression<String>? soundscape,
    Expression<String>? skinId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (mode != null) 'mode': mode,
      if (intention != null) 'intention': intention,
      if (plannedSeconds != null) 'planned_seconds': plannedSeconds,
      if (recordedSeconds != null) 'recorded_seconds': recordedSeconds,
      if (completed != null) 'completed': completed,
      if (abandoned != null) 'abandoned': abandoned,
      if (autoContinue != null) 'auto_continue': autoContinue,
      if (soundscape != null) 'soundscape': soundscape,
      if (skinId != null) 'skin_id': skinId,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<SessionMode>? mode,
    Value<String>? intention,
    Value<int>? plannedSeconds,
    Value<int>? recordedSeconds,
    Value<bool>? completed,
    Value<bool>? abandoned,
    Value<bool>? autoContinue,
    Value<String>? soundscape,
    Value<String>? skinId,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      mode: mode ?? this.mode,
      intention: intention ?? this.intention,
      plannedSeconds: plannedSeconds ?? this.plannedSeconds,
      recordedSeconds: recordedSeconds ?? this.recordedSeconds,
      completed: completed ?? this.completed,
      abandoned: abandoned ?? this.abandoned,
      autoContinue: autoContinue ?? this.autoContinue,
      soundscape: soundscape ?? this.soundscape,
      skinId: skinId ?? this.skinId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(
        $SessionsTable.$convertermode.toSql(mode.value),
      );
    }
    if (intention.present) {
      map['intention'] = Variable<String>(intention.value);
    }
    if (plannedSeconds.present) {
      map['planned_seconds'] = Variable<int>(plannedSeconds.value);
    }
    if (recordedSeconds.present) {
      map['recorded_seconds'] = Variable<int>(recordedSeconds.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (abandoned.present) {
      map['abandoned'] = Variable<bool>(abandoned.value);
    }
    if (autoContinue.present) {
      map['auto_continue'] = Variable<bool>(autoContinue.value);
    }
    if (soundscape.present) {
      map['soundscape'] = Variable<String>(soundscape.value);
    }
    if (skinId.present) {
      map['skin_id'] = Variable<String>(skinId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('mode: $mode, ')
          ..write('intention: $intention, ')
          ..write('plannedSeconds: $plannedSeconds, ')
          ..write('recordedSeconds: $recordedSeconds, ')
          ..write('completed: $completed, ')
          ..write('abandoned: $abandoned, ')
          ..write('autoContinue: $autoContinue, ')
          ..write('soundscape: $soundscape, ')
          ..write('skinId: $skinId')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessions, settings];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      required SessionMode mode,
      Value<String> intention,
      required int plannedSeconds,
      required int recordedSeconds,
      Value<bool> completed,
      Value<bool> abandoned,
      Value<bool> autoContinue,
      Value<String> soundscape,
      Value<String> skinId,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<SessionMode> mode,
      Value<String> intention,
      Value<int> plannedSeconds,
      Value<int> recordedSeconds,
      Value<bool> completed,
      Value<bool> abandoned,
      Value<bool> autoContinue,
      Value<String> soundscape,
      Value<String> skinId,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionMode, SessionMode, int> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get intention => $composableBuilder(
    column: $table.intention,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedSeconds => $composableBuilder(
    column: $table.plannedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedSeconds => $composableBuilder(
    column: $table.recordedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get abandoned => $composableBuilder(
    column: $table.abandoned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoContinue => $composableBuilder(
    column: $table.autoContinue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundscape => $composableBuilder(
    column: $table.soundscape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skinId => $composableBuilder(
    column: $table.skinId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intention => $composableBuilder(
    column: $table.intention,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedSeconds => $composableBuilder(
    column: $table.plannedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedSeconds => $composableBuilder(
    column: $table.recordedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get abandoned => $composableBuilder(
    column: $table.abandoned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoContinue => $composableBuilder(
    column: $table.autoContinue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundscape => $composableBuilder(
    column: $table.soundscape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skinId => $composableBuilder(
    column: $table.skinId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionMode, int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get intention =>
      $composableBuilder(column: $table.intention, builder: (column) => column);

  GeneratedColumn<int> get plannedSeconds => $composableBuilder(
    column: $table.plannedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedSeconds => $composableBuilder(
    column: $table.recordedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get abandoned =>
      $composableBuilder(column: $table.abandoned, builder: (column) => column);

  GeneratedColumn<bool> get autoContinue => $composableBuilder(
    column: $table.autoContinue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get soundscape => $composableBuilder(
    column: $table.soundscape,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skinId =>
      $composableBuilder(column: $table.skinId, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<SessionMode> mode = const Value.absent(),
                Value<String> intention = const Value.absent(),
                Value<int> plannedSeconds = const Value.absent(),
                Value<int> recordedSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<bool> abandoned = const Value.absent(),
                Value<bool> autoContinue = const Value.absent(),
                Value<String> soundscape = const Value.absent(),
                Value<String> skinId = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                mode: mode,
                intention: intention,
                plannedSeconds: plannedSeconds,
                recordedSeconds: recordedSeconds,
                completed: completed,
                abandoned: abandoned,
                autoContinue: autoContinue,
                soundscape: soundscape,
                skinId: skinId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required SessionMode mode,
                Value<String> intention = const Value.absent(),
                required int plannedSeconds,
                required int recordedSeconds,
                Value<bool> completed = const Value.absent(),
                Value<bool> abandoned = const Value.absent(),
                Value<bool> autoContinue = const Value.absent(),
                Value<String> soundscape = const Value.absent(),
                Value<String> skinId = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                mode: mode,
                intention: intention,
                plannedSeconds: plannedSeconds,
                recordedSeconds: recordedSeconds,
                completed: completed,
                abandoned: abandoned,
                autoContinue: autoContinue,
                soundscape: soundscape,
                skinId: skinId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
