import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseMethods {
  Future addPropertyDetail(Map<String, dynamic> propertyInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection('PropertyDetail')
        .doc(id)
        .set(propertyInfoMap);
  }

  Future<Stream<QuerySnapshot>> getPropertyDetails() async {
    return await FirebaseFirestore.instance.collection('PropertyDetail').snapshots();
  }

  Future getSingleProperty(String id) async {
    return await FirebaseFirestore.instance.collection('PropertyDetail').doc(id).snapshots();
  }

  Future updateProperty(String id, Map<String, dynamic> updateData) async {
    return await FirebaseFirestore.instance.collection('PropertyDetail').doc(id).update(updateData);
  }

  Future deleteProperty(String id) async {
    return await FirebaseFirestore.instance.collection('PropertyDetail').doc(id).delete();
  }
  Future deleteImage(String id) async {

    DocumentSnapshot<Map<String, dynamic>> propertyDoc =
    await FirebaseFirestore.instance.collection('PropertyDetail').doc(id).get();

    String? currentImageUrl = propertyDoc.data()?['image'];
    if (currentImageUrl != null) {
      try {
        return await FirebaseStorage.instance.refFromURL(currentImageUrl!).delete();
      } catch (e) {
        print("Error deleting image on cancel: $e");
      }
    }

  }

  Stream<QuerySnapshot> getPropertyDetailsByType(String type) {
    return FirebaseFirestore.instance
        .collection("PropertyDetail")
        .where("type", isEqualTo: type)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllPropertyTypes() {
    return FirebaseFirestore.instance.collection('PropertyTypes').snapshots();
  }


}
