import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giftle/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

final followeingRef = FirebaseFirestore.instance.collection("followeing");
final user = FirebaseAuth.instance.currentUser!.uid;

class EventDetailsPage extends StatefulWidget {
  final DocumentSnapshot event;

  EventDetailsPage({required this.event});

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  int AttendeesCount = 0;
  int DeclinedCount = 0;
  int witinfCount = 0;
  int allCount = 0;

  Future<void> attendeesCount() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('attendees')
        .where('status', isEqualTo: 'attending')
        .get();

    setState(() {
      AttendeesCount = querySnapshot
          .docs.length; // تحديث قيمة المتغير عند الحصول على البيانات
    });
  }

  Future<void> CountDeclin() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('attendees')
        .where('status', isEqualTo: 'Declined')
        .get();

    setState(() {
      DeclinedCount = querySnapshot.docs.length;
    });
  }

  Future<void> CountWiting() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('attendees')
        .where('status', isEqualTo: 'invited')
        .get();

    setState(() {
      witinfCount = querySnapshot.docs.length;
    });
  }

  Future<void> allCountWiting() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('attendees')
        .where('status1', isEqualTo: 'status1')
        .get();

    setState(() {
      allCount = querySnapshot.docs.length;
    });
  }

  @override
  void initState() {
    super.initState();
    attendeesCount();
    CountDeclin();
    CountWiting();
    allCountWiting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(248, 243, 239, 220),
      appBar: AppBar(
          title: Center(child: Text('Event Details')),
          backgroundColor: Color.fromARGB(248, 243, 236, 199)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 25,
                ),
                Text(
                  'Event Name : ${widget.event['name']}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ],
            ),
            SizedBox(height: 5),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                children: [
                  _buildIconButton(
                      context, 'Attendees', Icons.people, _showAttendees,
                      count: AttendeesCount.toString()),
                  _buildIconButton(context, 'Messages From Invitees',
                      Icons.message, _showInvitedMessages),
                  _buildIconButton(
                      context, 'Declined', Icons.block, _showDeclinedAttendees,
                      count: DeclinedCount.toString()),
                  _buildIconButton(
                    context,
                    'Wish List',
                    Icons.card_giftcard,
                    _showGiftsList,
                  ),
                  _buildIconButton(context, 'Not responded invitation',
                      Icons.help_outline, _showUnresponsiveInvitees,
                      count: witinfCount.toString()),
                  _buildIconButton(context, 'Send Invit', Icons.person_add,
                      _showFollowedInvitees),
                  _buildIconButton(
                      context, 'The invitations', Icons.person, _showallnvitees,
                      count: allCount.toString()),
                  _buildIconButton(context, 'Send Invit WhatsApp',
                      Icons.person_add, _inviteViaWhatsApp),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    String label,
    IconData icon,
    Function showFunction, {
    String? count, // متغير اختياري لعرض العدد بجانب الأيقونة
  }) {
    return GestureDetector(
      onTap: () => showFunction(context),
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 226, 229, 226),
                blurRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Icon(icon, size: 35, color: Colors.black),
                  if (count != null)
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        count,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(color: Colors.black, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12)),
    );
  }

  void _inviteViaWhatsApp(BuildContext context) async {
    try {
      // تأكد من وجود الصلاحيات للوصول إلى جهات الاتصال
      PermissionStatus permissionStatus = await Permission.contacts.status;
      if (permissionStatus != PermissionStatus.granted) {
        permissionStatus = await Permission.contacts.request();
        if (permissionStatus != PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('لا توجد صلاحيات للوصول إلى جهات الاتصال')),
          );
          return;
        }
      }

      // جلب جهات الاتصال
      Iterable<Contact> contacts = await ContactsService.getContacts();

      // قائمة لتخزين الجهات المحددة
      List<Contact> selectedContacts = [];
      List<Contact> filteredContacts = contacts.toList();
      TextEditingController searchController = TextEditingController();

      // عرض Bottom Sheet لاختيار جهة الاتصال وإرسال الدعوة
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return FractionallySizedBox(
                child: Container(
                  height: MediaQuery.of(context).size.height * 4.9,
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'جهات الاتصال',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث عن جهة الاتصال',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {
                            filteredContacts = contacts.where((contact) {
                              return contact.displayName
                                      ?.toLowerCase()
                                      .contains(text.toLowerCase()) ??
                                  false;
                            }).toList();
                          });
                        },
                      ),
                      SizedBox(height: 5),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            var contact = filteredContacts[index];
                            bool isSelected =
                                selectedContacts.contains(contact);

                            return ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 8.0),
                              title: Text(contact.displayName ?? 'بدون اسم'),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value!) {
                                      selectedContacts.add(contact);
                                    } else {
                                      selectedContacts.remove(contact);
                                    }
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedContacts.remove(contact);
                                  } else {
                                    selectedContacts.add(contact);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          for (var contact in selectedContacts) {
                            var phones = contact.phones!.toList();
                            if (phones.isNotEmpty) {
                              var phone = _formatPhoneNumber(phones[0].value!);
                              var eventDoc = await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(widget.event.id)
                                  .get();

                              if (eventDoc.exists) {
                                var eventData = eventDoc.data();
                                var name = eventData!['name'];
                                var eve = eventData['eventId'].toString();
                                var imgevint = eventData['imageUrl'].toString();
                                var inviter = eventData['inviter'];

                                var apiUrl =
                                    'https://graph.facebook.com/v12.0/308221045718941/messages';
                                var payload = json.encode({
                                  "messaging_product": "whatsapp",
                                  "to": phone,
                                  "type": "template",
                                  "template": {
                                    "name": "invited",
                                    "language": {"code": "ar"},
                                    "components": [
                                      {
                                        "type": "header",
                                        "parameters": [
                                          {
                                            "type": "image",
                                            "image": {"link": "$imgevint"}
                                          }
                                        ]
                                      },
                                      {
                                        "type": "body",
                                        "parameters": [
                                          {"type": "text", "text": "$name"},
                                          {"type": "text", "text": "$inviter"}
                                        ]
                                      },
                                      {
                                        "type": "button",
                                        "sub_type": "QUICK_REPLY",
                                        "index": 0,
                                        "parameters": [
                                          {
                                            "type": "text",
                                            "text": "a$eve",
                                            "payload": "D$eve"
                                          }
                                        ]
                                      },
                                      {
                                        "type": "button",
                                        "sub_type": "QUICK_REPLY",
                                        "index": 1,
                                        "parameters": [
                                          {
                                            "type": "text",
                                            "text": "D$eve",
                                            "payload": "D$eve"
                                          }
                                        ]
                                      }
                                    ]
                                  }
                                });

                                var response = await http.post(
                                  Uri.parse(apiUrl),
                                  headers: {
                                    'Authorization':
                                        'Bearer EAAVKrvZCosOIBO4BIuXQ8Y85UMhOgwt5G1Dgz5naZAk733AQE98I7jnB8BKfSCcCg8opwDNIeKE2dSFWZBAhmejQtHNusGYRLEXDsRZAA2au9ISINUOrnb58oZCHGiKAZCcZBy2bNGTZAihGrb0ZB1ITj7l52qzxPP2fbhwuzaLHvyJODwjoelvLy90jGzVGovd4a',
                                    'Content-Type': 'application/json',
                                  },
                                  body: payload,
                                );
                                print(payload);
                                if (response.statusCode == 200) {
                                  // إذا تم إرسال الدعوة بنجاح، قم بحفظ بيانات المدعو في Firestore
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(widget.event.id)
                                        .collection('attendees')
                                        .doc(phone)
                                        .set({
                                      'username':
                                          contact.displayName ?? 'بدون اسم',
                                      'phone': phone,
                                      'status': 'invited',
                                      'avataFotourl':
                                          'https://firebasestorage.googleapis.com/v0/b/fir-giftle-app.appspot.com/o/post_55d597f1-7ea6-4bed-9213-2b1dda415696.jpg?alt=media&token=15935f03-9ab3-4c0d-972a-32a67194958d',
                                      'EvindID': widget.event.id,
                                      'status1': 'status1'
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إرسال الدعوة بنجاح'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'حدث خطأ أثناء حفظ بيانات المدعو: $e'),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('فشل في إرسال الدعوة'),
                                    ),
                                  );
                                }
                              }
                            }
                            Navigator.pop(
                                context); // إغلاق Bottom Sheet بعد الانتهاء
                          }
                        },
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.green)),
                        child: Text(
                          'Send Invitation(${selectedContacts.length})',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الوصول إلى جهات الاتصال: $e')),
      );
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    // إزالة الفراغات وأي رموز غير رقمية من الرقم
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // إذا كان الرقم يبدأ بـ "0" وهو رقم سعودي، استبدله برقم بدون الصفر
    if (phoneNumber.startsWith('0') && phoneNumber.length == 10) {
      return '966${phoneNumber.substring(1)}';
    }

    // في حالة أخرى، استخدم الرقم كما هو (بدون تغيير)
    return phoneNumber;
  }

  void _showAttendees(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor:
              1.1, // يعدل هذا الرقم لتحديد النسبة من ارتفاع الشاشة الكلي
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Attendees',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('events')
                      .doc(widget.event.id)
                      .collection('attendees')
                      .where('status', isEqualTo: 'attending')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'لا يوجد حاضرون حالياً',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    var docs = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        return ListTile(
                          title: Text(
                            doc['username'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          leading: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(doc['avataFotourl']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeclinedAttendees(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),
                Text(
                  'Declined',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.event.id)
                        .collection('attendees')
                        .where('status', isEqualTo: 'Declined')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No Declined',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            title: Text(
                              doc['username'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  doc['avataFotourl']),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInvitedMessages(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.event.id)
                        .collection('messages')
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'خطأ في تحميل الرسائل.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No Messages',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      var messages = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var messageData =
                              messages[index].data() as Map<String, dynamic>;
                          var message = messageData['message'] ?? '';
                          var senderName =
                              messageData['senderName'] ?? 'غير معروف';
                          var senderImage = messageData['senderImage'] ?? '';

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            leading: senderImage.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(senderImage),
                                  )
                                : CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                            title: Text(
                              senderName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(message),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGiftsList(BuildContext context) async {
    // Fetch the gifts from Firestore
    QuerySnapshot giftSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .collection('gifts')
        .get();

    // Show the bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),
                Text(
                  'Wish List',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: giftSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      var gift = giftSnapshot.docs[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                        title: Text(
                          gift['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: gift['image_url'] != null
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: Image.network(gift['image_url'],
                                    fit: BoxFit.cover),
                              )
                            : null,
                        trailing: Text(gift['Sponsored']),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () => _pickImage(context, ImageSource.camera),
                      child: Text('Camera'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () => _pickImage(context, ImageSource.gallery),
                      child: Text('Studio'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(
      source: source,
    );

    if (image != null) {
      TextEditingController commentController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          bool isLoading = false;

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Add comment'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: commentController,
                      maxLength: 20,
                      decoration: InputDecoration(hintText: 'add Comment'),
                    ),
                    if (isLoading)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });

                      File file = File(image.path);
                      String fileName = image.name;
                      try {
                        // رفع الصورة إلى Firebase Storage
                        UploadTask uploadTask = FirebaseStorage.instance
                            .ref('gifts/$fileName')
                            .putFile(file);

                        TaskSnapshot taskSnapshot = await uploadTask;
                        String downloadUrl =
                            await taskSnapshot.ref.getDownloadURL();

                        // إضافة بيانات الهدية إلى Firestore
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(widget.event.id)
                            .collection('gifts')
                            .add({
                          'name': commentController.text,
                          'image_url': downloadUrl,
                          'status': 'nocom',
                          'Sponsored': ''
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gift added successfully')),
                        );

                        Navigator.of(context).pop(); // إغلاق نافذة الإدخال
                        Navigator.of(context).pop(); // إغلاق نافذة الحوار

                        _showGiftsList(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('an error occurred')),
                        );
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _showUnresponsiveInvitees(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),
                Text(
                  'Waiting For Answer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.event.id)
                        .collection('attendees')
                        .where('status', isEqualTo: 'invited')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No Waiting',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            title: Text(
                              doc['username'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  doc['avataFotourl']),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showallnvitees(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),
                Text(
                  'Waiting For Answer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('events')
                        .doc(widget.event.id)
                        .collection('attendees')
                        .where('status1', isEqualTo: 'status1')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No Waiting',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            title: Text(
                              doc['username'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  doc['avataFotourl']),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFollowedInvitees(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),
                Text(
                  'Send Invits',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('followeing')
                        .doc(user)
                        .collection('userfolloers')
                        .get(),
                    builder: (context, followingSnapshot) {
                      if (!followingSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var followingDocs = followingSnapshot.data!.docs;

                      return ListView(
                        children: followingDocs.map((doc) {
                          String followedUserId = doc.id;

                          return FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('events')
                                .doc(widget.event.id)
                                .collection('attendees')
                                .doc(followedUserId)
                                .get(),
                            builder: (context, inviteeSnapshot) {
                              if (!inviteeSnapshot.hasData) {
                                return ListTile(
                                  title: Text('جار التحميل...'),
                                );
                              }
                              var inviteeData = inviteeSnapshot.data!.data();

                              return ListTile(
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 8.0),
                                title: Text(doc['username']),
                                leading: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                      doc['avataFotourl']),
                                ),
                                trailing: inviteeData != null
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 7),
                                          shadowColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: Text(
                                          'Sender',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                        onPressed: () {
                                          _inviteFollower(
                                              doc.id,
                                              doc['avataFotourl'],
                                              doc['username']);
                                        },
                                        child: Text(
                                          'Send',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _inviteFollower(
      String followerId, String avataFotourl, String username) async {
    DocumentSnapshot snapshot = await usersRef.doc(user).get();

    // استخراج معلومات المستخدم
    var userData = snapshot.data() as Map<String, dynamic>;
    var userPhotoUrl = userData['photoUrl'];
    var usernamee = userData['name'];
    try {
      // إضافة المتابع إلى قائمة المدعوين في الحدث
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('attendees')
          .doc(followerId)
          .set({
        'status': 'invited',
        'avataFotourl': avataFotourl,
        'username': username,
        'EvindID': widget.event.id,
        'status1': 'status1'
      });

      // إضافة العنصر إلى مجموعة feeditem
      await feedsRef.doc(followerId).collection('feeditem').add({
        'type': 'Evints',
        'username': usernamee,
        'userId': followerId,
        'userprofimf': userPhotoUrl,
        'timestamp': Timestamp.now(),
        'commentdata': '',
        'userIdadd': user,
        'EvindID': widget.event.id
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت دعوة المتابع بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء دعوة المتابع')),
      );
    }
  }

  void _showBottomSheet(
      BuildContext context, String title, Future<QuerySnapshot> future) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _buildModalBottomSheetContent(context, title, future);
      },
    );
  }

  Widget _buildModalBottomSheetContent(
      BuildContext context, String title, Future<QuerySnapshot> future) {
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor),
          ),
          Expanded(
            child: FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                return ListView(
                  children: docs
                      .map((doc) => ListTile(title: Text(doc['name'])))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
