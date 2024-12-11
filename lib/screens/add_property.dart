import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_firebase/services/database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:random_string/random_string.dart';
import 'package:image_picker/image_picker.dart';

class AddProperty extends StatefulWidget {
  @override
  State<AddProperty> createState() => _AddPropertyState();
}

class _AddPropertyState extends State<AddProperty> {
  TextEditingController titleController = TextEditingController();
  TextEditingController demandPriceController = TextEditingController();
  TextEditingController marketPriceController = TextEditingController();
  TextEditingController acceptablePriceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController referenceController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  String? selectedType;
  List<String> types = ['Residential Plot', 'Commercial Plot','House', 'Plaza/Shop','Agricultural Land'];

  GlobalKey<FormState> key = GlobalKey();

  CollectionReference _reference = FirebaseFirestore.instance.collection('PropertyDetail');

  String? previousImageUrl; // Store the URL of the previous image if any
  String? currentImageUrl; // Store the URL of the currently uploaded image
  File? selectedImage;
  bool isImageUploading = false; // Track image upload status

  @override
  void initState() {
    super.initState();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('property_types').get();
    List<String> fetchedTypes = snapshot.docs.map((doc) => doc['type'] as String).toList();
    setState(() {
      types = List.from(Set.from(types + fetchedTypes));
    });
  }

  Future<void> _pickImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        selectedImage = File(file.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (selectedImage == null) return;

    setState(() {
      isImageUploading = true; // Set upload status to true
    });

    // Delete the previous image if it exists
    if (currentImageUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(currentImageUrl!).delete();
      } catch (e) {
        print("Error deleting previous image: $e");
      }
    }

    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceRoot = FirebaseStorage.instance.ref();
    Reference referenceDirImages = referenceRoot.child('images');
    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

    try {
      await referenceImageToUpload.putFile(selectedImage!);
      String downloadUrl = await referenceImageToUpload.getDownloadURL();
      setState(() {
        currentImageUrl = downloadUrl;
        isImageUploading = false; // Set upload status to false
        Fluttertoast.showToast(
          msg: 'Image uploaded successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      });
    } catch (error) {
      setState(() {
        isImageUploading = false; // Set upload status to false
      });
      Fluttertoast.showToast(
        msg: 'Failed to upload image',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleCancel() async {
    if (currentImageUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(currentImageUrl!).delete();
      } catch (e) {
        print("Error deleting image on cancel: $e");
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30))
        ),
        backgroundColor: Colors.grey.shade100,
        automaticallyImplyLeading: false,
        title: Text('Add Property',style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
        ),),
        centerTitle: true,
        elevation: 12,
        shadowColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: _handleCancel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        key: key,
        child: SingleChildScrollView(

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),
              TextField(
                controller: demandPriceController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: 'Demanded Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),
              TextField(
                controller: marketPriceController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: 'Market Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),
              TextField(
                controller: acceptablePriceController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    labelText: 'Acceptable Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),
              DropdownButtonFormField<String>(
                value: selectedType,
                hint: Text('Select Priperty Type'),
                items: types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),

              TextField(
                controller: locationController,
                decoration: InputDecoration(
                    labelText: 'Address/Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),


              TextField(
                controller: referenceController,
                decoration: InputDecoration(
                    labelText: 'Reference',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 2.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade400, width: 3.0),
                    )),
              ),
              SizedBox(height: 30),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 50,
                  width: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Add image', style: TextStyle(color: Colors.white)),
                      Icon(Icons.add_a_photo_outlined, color: Colors.white),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Image', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 30),


              Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: isImageUploading ? null : () async {


                    if(titleController.text.isEmpty || demandPriceController.text.isEmpty){
                      Fluttertoast.showToast(msg: "'Title' and 'Demanded Price' are Required", backgroundColor: Colors.red);
                      return;
                    }
                    if (selectedType == null) {
                      Fluttertoast.showToast(msg: 'Please select a type', backgroundColor: Colors.red);
                      return;
                    }
                    if (currentImageUrl == null) {
                      Fluttertoast.showToast(msg: 'Please upload an Image', backgroundColor: Colors.red);
                      return;
                    }



                    String id = randomAlphaNumeric(10);
                    Map<String, dynamic> propertyInfoMap = {
                      "title": titleController.text,
                      "demand_price": demandPriceController.text,
                      "market_price": marketPriceController.text,
                      "acceptable_price": acceptablePriceController.text,
                      "type": selectedType,
                      "id": id,
                      "image": currentImageUrl,
                      "description": descriptionController.text,
                      "reference": referenceController.text,
                      "location": locationController.text,
                      "date": DateTime.now().toString()
                    };

                    await DatabaseMethods().addPropertyDetail(propertyInfoMap, id).then(
                          (value) {
                        Fluttertoast.showToast(
                          msg: 'Property has been added successfully',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
