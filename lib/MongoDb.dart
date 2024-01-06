import 'package:mongo_dart/mongo_dart.dart';
import '../const.dart';

class MongoDatabase {
  static dynamic db;
  static connect() async {
    db = await Db.create(Mongo_URL);
    await db.open();
    // var tutorsCollection = db.collection(tutorCollection_Name);
    // inspect(db);
    // //print(await tutorsCollection.find().toList());
  }

  static Future<String> fetchAll() async {
    String res = "";
    var tutorsCollection =
        await db.collection(tutorCollection_Name).find().toList();
    for (final doc in tutorsCollection) {
      res = res +
          "tutorId: " +
          doc['UID'] +
          " : " +
          "tutorName: " +
          doc['name'] +
          " subjects: " +
          doc['subjects'] +
          ", schedule: " +
          doc['schedule'] +
          ".";
    }
    return res;
  }

  static addtoFavs(String tutorID, int score) async {
    await db.collection(studentPref_Name).modernUpdate(where.eq("UID", UID),
        modify.push("tutors", {"tutorID": tutorID, "score": score}));
  }
}
