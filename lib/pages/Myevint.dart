import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/pages/EvinDatils.dart';
import 'package:giftle/pages/cretEvints.dart';

// استيراد الصفحة الجديدة

class MyEvint extends StatefulWidget {
  final String profilid;

  MyEvint({required this.profilid});

  @override
  State<MyEvint> createState() => _MyEvintState();
}

class _MyEvintState extends State<MyEvint> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(248, 243, 236, 199),
        title: Text('My Events'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('userId', isEqualTo: widget.profilid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عرض صورة الحدث
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(event[
                                  'imageUrl']), // استبدل برابط الصورة الفعلي
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 20),
                        // عرض معلومات الحدث
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['name'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                event['date'].toDate().toString(),
                                style: TextStyle(fontSize: 16),
                              ),
                              // يمكنك إضافة المزيد من المعلومات حسب الحاجة
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    CreateEventPage(profilid: widget.profilid)),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Event',
      ),
    );
  }
}
