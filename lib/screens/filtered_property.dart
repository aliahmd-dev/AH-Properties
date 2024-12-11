import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase/screens/property_details.dart';

class FilteredPropertyScreen extends StatefulWidget {
  final String selectedType;

  const FilteredPropertyScreen({super.key, required this.selectedType});

  @override
  State<FilteredPropertyScreen> createState() => _FilteredPropertyScreenState();
}

class _FilteredPropertyScreenState extends State<FilteredPropertyScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> filteredPropertyStream;

  @override
  void initState() {
    super.initState();
    filteredPropertyStream = FirebaseFirestore.instance
        .collection('PropertyDetail')
        .where('type', isEqualTo: widget.selectedType)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (data, _) => data,
    )
        .snapshots();
  }

  Widget filteredPropertyDetails() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: filteredPropertyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No properties found for this type"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final ds = snapshot.data!.docs[index];
            final data = ds.data();
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetail(ds.id),
                  ),
                );
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
                          image: NetworkImage(data['image']),
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          left: 16,
                          child: Text(
                            "Price : " + data['demand_price'] + " Rs",
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
                        data['title'],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
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
                          label: Text(
                            "Property Type : " + data['type'],
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        backgroundColor: Colors.grey.shade100,
        automaticallyImplyLeading: true,
        title: Text(
          "Type : "+widget.selectedType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        elevation: 12,
        shadowColor: Colors.black,
      ),
      body: Container(
        margin: EdgeInsets.only(left: 5, right: 5),
        child: Column(
          children: [
            Expanded(child: filteredPropertyDetails()),
          ],
        ),
      ),
    );
  }
}
