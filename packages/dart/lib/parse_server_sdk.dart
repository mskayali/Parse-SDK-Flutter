// ignore_for_file: unnecessary_import
library flutter_parse_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xxtea/xxtea.dart';

import 'src/network/parse_http_client.dart';
import 'src/network/parse_websocket.dart' as parse_web_socket;

export 'src/network/parse_dio_client.dart';
export 'src/network/parse_http_client.dart';

part 'src/base/parse_constants.dart';
part 'src/data/parse_core_data.dart';
part 'src/data/parse_subclass_handler.dart';
part 'src/enums/parse_enum_api_rq.dart';
part 'src/network/options.dart';
// part 'src/network/parse_aggregate.dart';
part 'src/network/parse_client.dart';
part 'src/network/parse_connectivity.dart';
part 'src/network/parse_live_query.dart';
part 'src/network/parse_query.dart';
part 'src/objects/parse_acl.dart';
part 'src/objects/parse_aggregate.dart';
part 'src/objects/parse_array.dart';
part 'src/objects/parse_base.dart';
part 'src/objects/parse_cloneable.dart';
part 'src/objects/parse_config.dart';
part 'src/objects/parse_error.dart';
part 'src/objects/parse_exception.dart';
part 'src/objects/parse_file.dart';
part 'src/objects/parse_file_base.dart';
part 'src/objects/parse_file_web.dart';
part 'src/objects/parse_function.dart';
part 'src/objects/parse_geo_point.dart';
part 'src/objects/parse_installation.dart';
part 'src/objects/parse_jobs.dart';
part 'src/objects/parse_number.dart';
part 'src/objects/parse_object.dart';
part 'src/objects/parse_operation/parse_add_operation.dart';
part 'src/objects/parse_operation/parse_add_relation_operation.dart';
part 'src/objects/parse_operation/parse_add_unique_operation.dart';
part 'src/objects/parse_operation/parse_increment_operation.dart';
part 'src/objects/parse_operation/parse_operation.dart';
part 'src/objects/parse_operation/parse_remove_operation.dart';
part 'src/objects/parse_operation/parse_remove_relation_operation.dart';
part 'src/objects/parse_relation.dart';
part 'src/objects/parse_response.dart';
part 'src/objects/parse_save_state_aware_child.dart';
part 'src/objects/parse_session.dart';
part 'src/objects/parse_user.dart';
part 'src/objects/parse_x_file.dart';
part 'src/objects/response/parse_error_response.dart';
part 'src/objects/response/parse_exception_response.dart';
part 'src/objects/response/parse_response_builder.dart';
part 'src/objects/response/parse_response_utils.dart';
part 'src/objects/response/parse_success_no_results.dart';
part 'src/storage/core_store.dart';
part 'src/storage/core_store_memory.dart';
part 'src/storage/core_store_sem_impl.dart';
part 'src/storage/xxtea_codec.dart';
part 'src/utils/parse_date_format.dart';
part 'src/utils/parse_decoder.dart';
part 'src/utils/parse_encoder.dart';
part 'src/utils/parse_live_list.dart';
part 'src/utils/parse_logger.dart';
part 'src/utils/parse_login_helpers.dart';
part 'src/utils/parse_utils.dart';
part 'src/utils/valuable.dart';

class Parse {
  bool _hasBeenInitialized = false;

  static bool objectsExistForEventually = false;

  /// To initialize Parse Server in your application
  ///
  /// This should be initialized in MyApp() creation
  ///
  /// ```
  /// Parse().initialize(
  ///        "PARSE_APP_ID",
  ///        "https://parse.myaddress.com/parse/,
  ///        clientKey: "asd23rjh234r234r234r",
  ///        debug: true,
  ///        liveQuery: true);
  /// ```
  Future<Parse> initialize(
    String appId,
    String serverUrl, {
    bool debug = false,
    String? appName,
    String? appVersion,
    String? appPackageName,
    String? locale,
    String? liveQueryUrl,
    String? clientKey,
    String? masterKey,
    String? sessionId,
    bool autoSendSessionId = true,
    SecurityContext? securityContext,
    CoreStore? coreStore,
    Map<String, ParseObjectConstructor>? registeredSubClassMap,
    ParseUserConstructor? parseUserConstructor,
    ParseFileConstructor? parseFileConstructor,
    List<int>? liveListRetryIntervals,
    ParseConnectivityProvider? connectivityProvider,
    String? fileDirectory,
    Stream<void>? appResumedStream,
    ParseClientCreator? clientCreator,
  }) async {
    final String url = removeTrailingSlash(serverUrl);

    await ParseCoreData.init(
      appId,
      url,
      debug: debug,
      appName: appName,
      appVersion: appVersion,
      appPackageName: appPackageName,
      locale: locale,
      liveQueryUrl: liveQueryUrl,
      masterKey: masterKey,
      clientKey: clientKey,
      sessionId: sessionId,
      autoSendSessionId: autoSendSessionId,
      securityContext: securityContext,
      store: coreStore,
      registeredSubClassMap: registeredSubClassMap,
      parseUserConstructor: parseUserConstructor,
      parseFileConstructor: parseFileConstructor,
      liveListRetryIntervals: liveListRetryIntervals,
      connectivityProvider: connectivityProvider,
      fileDirectory: fileDirectory,
      appResumedStream: appResumedStream,
      clientCreator: clientCreator,
    );

    _hasBeenInitialized = true;

    objectsExistForEventually = await checkObjectsExistForEventually();

    if (objectsExistForEventually) {
      ParseObject.submitEventually();
    }

    return this;
  }

  bool hasParseBeenInitialized() => _hasBeenInitialized;

  Future<ParseResponse> healthCheck(
      {bool? debug, ParseClient? client, bool? sendSessionIdByDefault}) async {
    final bool debugLocal = isDebugEnabled(objectLevelDebug: debug);

    final ParseClient clientLocal = client ??
        ParseCoreData().clientCreator(
            sendSessionId:
                sendSessionIdByDefault ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    const String className = 'parseBase';
    const ParseApiRQ type = ParseApiRQ.healthCheck;

    try {
      final ParseNetworkResponse response = await clientLocal
          .get('${ParseCoreData().serverUrl}$keyEndPointHealth');
      return handleResponse<Parse>(null, response, type, debugLocal, className);
    } on Exception catch (e) {
      return handleException(e, type, debugLocal, className);
    }
  }
}
