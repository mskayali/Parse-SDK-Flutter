import 'package:parse_server_sdk/parse_server_sdk.dart';

Future<void> main() async {
  // Parse initialize
  await Parse().initialize("keyApplicationId", "keyParseServerUrl",
      clientKey: "keyParseClientKey",
      debug: true,
      liveQueryUrl: "keyLiveQueryUrl",
      autoSendSessionId: true,
      coreStore: CoreStoreMemoryImp());

  // Set a ParseObject and save it
  var dietPlan = ParseObject('DietPlan')
    ..set('Name', 'Ketogenic')
    ..set('Fat', 65);



  var response = await dietPlan.save();

  if (response.success) {
    dietPlan = response.results?.first;
    print("Response received successfully");
  }

  final res = await ParseAggregate('DietPlan').execute({
    r'$match': {'Name': 'Ketogenic'},
    r'$group': {
      '_id': r'isHungry',
      'count': {r'$sum': 1}
    },
  });

  print('${res.statusCode}, ${res.results}');

}
