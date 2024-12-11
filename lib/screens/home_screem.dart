import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_firebase/screens/add_property.dart';
import 'package:flutter_firebase/screens/filtered_property.dart';
import 'package:flutter_firebase/screens/property_details.dart';
import 'package:flutter_firebase/services/database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Stream? PropertyStream;
  String? selectedType;
  List<String> types = ['Residential Plot', 'Commercial Plot','House', 'Plaza/Shop','Agricultural Land'];

  getontheload()async{
    PropertyStream = await DatabaseMethods().getPropertyDetails();
    setState(() {

    });
  }

  @override
  void initState() {
    getontheload();
    super.initState();
  }

  Widget allpropertyDetails() {
    return StreamBuilder(stream: PropertyStream,builder: (context, AsyncSnapshot snapshot) {
      return snapshot.hasData ? ListView.builder(
        itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
          DocumentSnapshot ds = snapshot.data.docs[index];
          return   InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>PropertyDetail(ds.id)));
            },
            child: Card(
              margin: EdgeInsets.only(top: 20),
              clipBehavior: Clip.antiAlias,
              elevation: 12,
              shadowColor: Colors.black,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Ink.image(
                        image: NetworkImage(
                          ds["image"]
                        ),
                        height: 240,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        left: 16,
                        child: Text(
                          "Price : "+ds["demand_price"]+" Rs",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(16).copyWith(bottom: 0),
                    child: Text(
                      ds["title"],
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.start,
                    children: [
                      Chip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                          label: Text("Property Type : "+ds["type"],style: TextStyle(color: Colors.white),),
                        backgroundColor: Colors.blueGrey,

                      ),

                    ],
                  )
                ],
              ),
            ),

          );
          })
          : Container();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:Drawer(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: types.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                value: selectedType,
                hint: Text('Select Property Type'),
                items: types.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                FilteredPropertyScreen(selectedType: value)));
                  }
                },
              ),
            ),
          ],
        ),
      ),
        appBar: AppBar(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30))
          ),
          backgroundColor: Colors.grey.shade100,
          automaticallyImplyLeading: false,
          title: Text('Home',style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),),
          centerTitle: true,
          elevation: 12,
          shadowColor: Colors.black,
        ),

        body: Container(
      margin: EdgeInsets.only(left: 5, right: 5),
      child: Column(
        children: [
              Expanded(child: allpropertyDetails()),
        ],
      ),
    ),
        floatingActionButton: FloatingActionButton(onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AddProperty()));
        },
          child: Icon(Icons.add),
          backgroundColor: Colors.grey.shade100,

        )
    );
  }
}
