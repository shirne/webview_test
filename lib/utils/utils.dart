import 'dart:math' as math;
import 'dart:convert';
import 'dart:developer';

import 'package:logging/logging.dart';

typedef DataParser<T> = T Function(dynamic m);

T defaultParser<T>(data) => as<T>(data) ?? getDefault<T>();

typedef Json = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

const emptyJson = <String, dynamic>{};

T getDefault<T>() {
  if (null is T) {
    return null as T;
  } else if (T == int) {
    return 0 as T;
  } else if (T == double || T == num) {
    return 0.0 as T;
  } else if (T == BigInt) {
    return BigInt.zero as T;
  } else if (T == String) {
    return '' as T;
  } else if (T == bool) {
    return false as T;
  } else if (T == DateTime) {
    return DateTime.fromMillisecondsSinceEpoch(0) as T;
  } else if (T == List) {
    return [] as T;
  } else if (T == Json) {
    return emptyJson as T;
  } else if (T == Map) {
    return {} as T;
  }
  throw Exception('Failed to create default value for $T.');
}

T? as<T>(dynamic value, [T? defaultValue]) {
  if (value is T) {
    return value;
  }
  if (value == null) {
    return defaultValue;
  }

  // num 强转
  if (value is num) {
    dynamic result;
    if (T == double) {
      result = value.toDouble();
    } else if (T == int) {
      result = value.toInt() as T;
    } else if (T == BigInt) {
      result = BigInt.from(value) as T;
    } else if (T == bool) {
      result = (value != 0) as T;
    } else if (T == DateTime) {
      if (value < 10000000000) {
        value *= 1000;
      }
      result = DateTime.fromMillisecondsSinceEpoch(value.toInt()) as T;
    }
    if (result != null) {
      return result as T;
    }
  } else

  // String parse
  if (value is String) {
    if (value.isEmpty) {
      return defaultValue;
    }
    dynamic result;
    if (T == int) {
      result = int.tryParse(value);
    } else if (T == double) {
      result = double.tryParse(value);
    } else if (T == BigInt) {
      result = BigInt.tryParse(value);
    } else if (T == DateTime) {
      // DateTime.parse不支持 /
      if (value.contains('/')) {
        value = value.replaceAll('/', '-');
      }
      result = DateTime.tryParse(value)?.toLocal();
    } else if (T == bool) {
      return {'1', '-1', 'true', 'yes'}.contains(value.toLowerCase()) as T;
    } else if (T == JsonList || T == Json) {
      try {
        return jsonDecode(value) as T;
      } catch (e) {
        logger.warning(
          'Json decode error: $e',
          StackTrace.current.cast(3),
        );
      }
    } else {
      logger.warning(
        'Unsupported type cast from $value (${value.runtimeType}) to $T.',
        StackTrace.current.cast(3),
      );
      return defaultValue;
    }
    if (result == null) {
      logger.fine(
        'Cast $value(${value.runtimeType}) to $T failed',
        StackTrace.current.cast(3),
      );
    }
    return result as T? ?? defaultValue;
  }

  // String 强转
  if (T == String) {
    logger.info(
      'Force cast $value(${value.runtimeType}) to $T',
      StackTrace.current.cast(3),
    );
    return '$value' as T;
  }
  logger.warning(
    'Type $T cast error: $value (${value.runtimeType})',
    StackTrace.current.cast(3),
  );

  return defaultValue;
}

final logger = Logger.root
  ..level = Level.ALL
  ..onRecord.listen((record) {
    log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
      sequenceNumber: record.sequenceNumber,
    );
  });

StackTrace? castStackTrace(StackTrace? trace, [int lines = 3]) {
  if (trace != null) {
    final errors = trace.toString().split('\n');
    return StackTrace.fromString(
      errors.sublist(0, math.min(lines, errors.length)).join('\n'),
    );
  }
  return null;
}

extension StackTraceExt on StackTrace {
  StackTrace cast(int lines) {
    return castStackTrace(this, lines)!;
  }
}
