
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_firebase/services/database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


class PropertyDetail extends StatefulWidget {
  final String id;


  PropertyDetail(this.id);

  @override
  State<PropertyDetail> createState() => _PropertyDetailState();
}

class _PropertyDetailState extends State<PropertyDetail> {


  TextEditingController titleController = TextEditingController();
  TextEditingController demandPriceController = TextEditingController();
  TextEditingController marketPriceController = TextEditingController();
  TextEditingController acceptablePriceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController referenceController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  String? previousImageUrl; // Store the URL of the previous image if any
  String? currentImageUrl; // Store the URL of the currently uploaded image
  File? selectedImage;
  bool isImageUploading = false;

  String? selectedType;
 // Variable to store selected dropdown type
  List<String> types = ['Residential Plot', 'Commercial Plot','House', 'Plaza/Shop','Agricultural Land'];
 // Initialize with static types
  String imageURL= "";

  @override
  void initState() {
    super.initState();
    _fetchTypes(); // Fetch types from Firestore when the widget is initialized
  }

  Future<void> _fetchTypes() async {
    // Fetch types from Firestore
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('property_types').get();

    // Convert the fetched documents into a list of strings (types)
    List<String> fetchedTypes = snapshot.docs.map((doc) => doc['type'] as String).toList();

    // Update the state with the fetched types, ensuring we don't duplicate types
    setState(() {
      // Combine static types with fetched types, removing duplicates
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

  Future<void> _updateImage() async {
    if (selectedImage == null) return;

    setState(() {
      isImageUploading = true; // Set upload status to true
    });

    try {
      // Fetch the current image URL from Firestore
      DocumentSnapshot<Map<String, dynamic>> propertyDoc =
      await FirebaseFirestore.instance.collection('PropertyDetail').doc(widget.id).get();

      String? oldImageUrl = propertyDoc.data()?['image'];

      // Delete the previous image if it exists
      if (oldImageUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
        } catch (e) {
          print("Error deleting previous image: $e");
        }
      }

      String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference referenceRoot = FirebaseStorage.instance.ref();
      Reference referenceDirImages = referenceRoot.child('images');
      Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

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
        isImageUploading = false; // Set upload status to false in case of an error
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



  @override
  Widget build(BuildContext context) {

    // Edit and Delete

    return Scaffold(
      floatingActionButton: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [


                  FloatingActionButton(
                    backgroundColor: Colors.grey.shade100,
                    heroTag: 'Delete',
                    onPressed: () async {
                      bool? confirmDelete = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirm Deletion'),
                            content: Text('Are you sure you want to delete this property?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false); // User pressed No
                                },
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true); // User pressed Yes
                                },
                                child: Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete == true) {
                        await DatabaseMethods().deleteImage(widget.id);
                        await DatabaseMethods().deleteProperty(widget.id);
                        Navigator.pop(context);
                      }
                    },
                    child: Icon(Icons.delete),
                    tooltip: 'Delete',
                  ),


                  SizedBox(height: 16),


                  FloatingActionButton(
                    heroTag: 'Edit',
                    backgroundColor: Colors.grey.shade100,
                    onPressed: ()async{
                      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
                          await FirebaseFirestore.instance.collection('PropertyDetail').doc(widget.id).get();

                      if (docSnapshot.exists) {
                        var data = docSnapshot.data()!;
                        titleController.text = data["title"] ?? '';
                        demandPriceController.text = data["demand_price"] ?? '';
                        marketPriceController.text = data["market_price"] ?? '';
                        acceptablePriceController.text = data["acceptable_price"] ?? '';
                        descriptionController.text = data["description"] ?? '';
                        selectedType = data["type"] ?? '';
                        referenceController.text = data["reference"] ?? '';
                        currentImageUrl = data["image"] ?? '';
                        locationController.text = data["location"] ?? '';

                        // Open the edit dialog
                        EditPropertyDetails(context, widget.id);
                      } else {
                        // Handle case where the document doesn't exist
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Document does not exist"),
                        ));
                      }
                    },
                    child: Icon(Icons.edit),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),


      appBar: AppBar(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30))
        ),
        backgroundColor: Colors.grey.shade100,
        title: Text('Property Details',style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
        ),),
        centerTitle: true,
        elevation: 8,
        shadowColor: Colors.black,
      ),

      // Get Data of the specific property




        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(left: 5, right: 5),
            child: Column(
              children: [
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection('PropertyDetail').doc(widget.id).get(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(child: Text('Document does not exist'));
                    }

                    final property = snapshot.data!.data()!;
                    final title = property['title'] ?? 'No title';
                    final demandPrice = property['demand_price'] ?? 'No price';
                    final marketPrice = property['market_price'] ?? 'No price';
                    final acceptablePrice = property['acceptable_price'] ?? 'No price';
                    final type = property['type'] ?? 'No type';
                    final image = property['image'] ?? 'No image';
                    final description = property['description'] ?? 'No description';
                    final reference = property['reference'] ?? 'No reference';
                    final location = property['location'] ?? 'No location';
                    final date = property['date'].toString() ?? 'No date';

                    return Container(
                      padding: EdgeInsets.only(left: 5, right: 5),

                      child: Column(
                        children: [
                          InkWell(
                            onTap : (){
                              showDialog(
                              context: context,
                              builder: (_) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: GestureDetector(
                              onTap: () {
                              Navigator.of(context).pop(); // Close the dialog when the image is tapped
                              },
                              child: InteractiveViewer(
                              panEnabled: true, // Enables panning
                              minScale: 1, // Minimum zoom scale
                              maxScale: 4, // Maximum zoom scale
                              child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                              image, // Use the actual image URL
                              fit: BoxFit.contain, // Ensure the image fits within the view
                              ),
                              ),
                              ),
                              ),
                              ),
                              );
                          },
                            child: Card(
                              margin: EdgeInsets.only(top: 10),
                              clipBehavior: Clip.antiAlias,
                              elevation: 12,
                              shadowColor: Colors.black,
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                               child: Ink.image(
                                image: NetworkImage(image),
                                height: 240,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                            Container(
                              width: double.infinity,
                              child: Card(
                              margin: EdgeInsets.only(top: 10),
                              clipBehavior: Clip.antiAlias,
                              elevation: 12,
                              shadowColor: Colors.black,
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Aligns all child widgets to the left
                                children: [


                                  SizedBox(height: 10),

                                  // Price
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        ),
                                        SizedBox(height: 8),

                                        // Property Type
                                        Chip(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          label: Text("Property Type : "+ type,style: TextStyle(color: Colors.white),),
                                          backgroundColor: Colors.blueGrey,

                                        ),
                                        SizedBox(height: 16),

                                        Text(
                                          "Demanded Price : " + demandPrice +" Rs",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),

                                        Text(
                                          "Market Price : " + marketPrice +" Rs",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),

                                        Text(
                                          "Acceptable Price : " + acceptablePrice +" Rs",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),

                                        Text("Address:",style: TextStyle(fontWeight: FontWeight.bold),),
                                        Text(
                                          location,
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        // Description
                                        Text("Description:",style: TextStyle(fontWeight: FontWeight.bold),),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),

                                        Text("Reference:",style: TextStyle(fontWeight: FontWeight.bold),),

                                        Text(
                                          reference,
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),

                                        SizedBox(height: 8),

                                        Text(
                                          date,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic
                                          ),
                                        ),


                                      ],
                                    ),
                                  ),

                                ],
                              ),
                                                        ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }


        // Implementation of AlertDiaog for Editting
  Future EditPropertyDetails(BuildContext context, String id) => showDialog(
    context: context,
    builder: (context) => AlertDialog(

      title:  Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.cancel),
          ),
          SizedBox(width: 8),
          Text(
            "Edit Details",
            style: TextStyle(
              fontSize: 25,
            ),
          ),
        ],
      ),
      content: Container(
        width: 420,

        child: SingleChildScrollView(
          child: Column(

            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                margin: EdgeInsets.only(top: 20),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 40,
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Add new ', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
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
                      onPressed: _updateImage,
                      child: Row(children: [
                        Text('Update  ' , style: TextStyle(color: Colors.white)),
                        Icon(Icons.image,color: Colors.white)
                      ] ),
                      style: ElevatedButton.styleFrom(
                        maximumSize: Size(130, 40),
                        backgroundColor: Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 30),

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

              // // TextField for Demanded Price
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

              // TextField for Market Price
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

              // TextField for Acceptable Price
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

              // DropdownButtonFormField for Property Type
              DropdownButtonFormField<String>(
                value: selectedType,
                hint: Text('Select Type'),
                items: types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value; // Update selected type when changed
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
              // TextField for Description
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

              // TextField for Reference
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



              ElevatedButton(
                onPressed: isImageUploading ? null : () async {
                  // Handle the update logic
                  Map<String, dynamic> updateData = {
                    'title': titleController.text,
                    'demand_price': demandPriceController.text,
                    'market_price': marketPriceController.text,
                    'acceptable_price': acceptablePriceController.text,
                    'type': selectedType,
                    'description': descriptionController.text,
                    'reference': referenceController.text,
                    'location': locationController.text,
                    'image': currentImageUrl, // Updated image URL
                  };
                  await FirebaseFirestore.instance.collection('PropertyDetail').doc(id).update(updateData).then(
                        (value){
                    Fluttertoast.showToast(
                      msg: 'Changes Saved',
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
                child: Icon(Icons.cloud_upload_outlined, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isImageUploading ? Colors.grey : Colors.blue, // Disable the button if image is uploading
                ),
              ),

            ],
          ),
        ),
      ),
    ),
    );

}
