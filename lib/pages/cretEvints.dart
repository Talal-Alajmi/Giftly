import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CreateEventPage extends StatefulWidget {
  final String profilid;

  CreateEventPage({required this.profilid});

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _eventName = '';
  File? _eventImage;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  String _eventCity = '';
  String _eventLocationUrl = '';
  String _eventInviter = '';
  String eventId = const Uuid().v4();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _eventImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference storageReference =
        FirebaseStorage.instance.ref().child('event_images').child(fileName);
    final UploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask;
    String imageUrl = await storageReference.getDownloadURL();
    return imageUrl;
  }

  Future<void> _pickDate() async {
    try {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        setState(() {
          _eventDate = pickedDate;
        });
      }
    } catch (e) {
      print("Error picking date: $e");
    }
  }

  Future<void> _pickTime() async {
    try {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _eventTime = pickedTime;
        });
      }
    } catch (e) {
      print("Error picking time: $e");
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      String imageUrl = '';
      if (_eventImage != null) {
        imageUrl = await _uploadImageToStorage(_eventImage!);
      }

      DateTime? eventDateTime;
      if (_eventDate != null && _eventTime != null) {
        eventDateTime = DateTime(
          _eventDate!.year,
          _eventDate!.month,
          _eventDate!.day,
          _eventTime!.hour,
          _eventTime!.minute,
        );
      }

      await FirebaseFirestore.instance.collection('events').doc(eventId).set({
        'name': _eventName,
        'userId': widget.profilid,
        'date': eventDateTime,
        'city': _eventCity,
        'locationUrl': _eventLocationUrl,
        'imageUrl': imageUrl,
        'inviter': _eventInviter,
        'eventId': eventId
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      decoration:
                          inputDecoration.copyWith(labelText: 'Name Event'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please Enter Name Event';
                        }
                        if (value.length > 25) {
                          return 'Name cannot exceed 25 characters';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventName = value!;
                      },
                    ),
                  ),
                  SizedBox(height: 5),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      readOnly: true,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Date of Event',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _pickDate,
                      controller: TextEditingController(
                        text: _eventDate != null
                            ? DateFormat('yyyy-MM-dd').format(_eventDate!)
                            : '',
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      readOnly: true,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Event Time',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: _pickTime,
                      controller: TextEditingController(
                        text: _eventTime != null
                            ? _eventTime!.format(context)
                            : '',
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      decoration: inputDecoration.copyWith(labelText: 'City'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please Enter City';
                        }
                        if (value.length > 15) {
                          return 'City cannot exceed 15 characters';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventCity = value!;
                      },
                    ),
                  ),
                  SizedBox(height: 5),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      decoration:
                          inputDecoration.copyWith(labelText: 'The Preacher'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please Enter Inviter Name';
                        }
                        if (value.length > 15) {
                          return 'Inviter name cannot exceed 15 characters';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventInviter = value!;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    shadowColor: const Color.fromRGBO(126, 187, 57, 1),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      decoration:
                          inputDecoration.copyWith(labelText: 'Event Map Link'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please Enter Event Map Link';
                        }
                        if (value.length > 70) {
                          return 'Link cannot exceed 70 characters';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventLocationUrl = value!;
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(
                      'Choose Event Image',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      shadowColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_eventImage != null) ...[
                    SizedBox(height: 20),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_eventImage!, height: 200),
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createEvent,
                    child: Text(
                      'Create Event',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 79, 247, 79),
                      shadowColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
