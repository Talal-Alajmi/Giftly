import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class CreateUsers extends StatefulWidget {
  const CreateUsers({Key? key}) : super(key: key);

  @override
  State<CreateUsers> createState() => _CreateUsersState();
}

class _CreateUsersState extends State<CreateUsers> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore userRef = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? selectedRegion;
  bool snapsho = false;
  bool isNameValid = true; // حالة التحقق من الاسم
  bool isEmailValid = true; // حالة التحقق من البريد الإلكتروني
  bool isEmailFormatValid = true; // حالة التحقق من تنسيق البريد الإلكتروني

  Future<void> _validateInputs() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // التحقق من الاسم
    var nameSnapshot =
        await userRef.collection('users').where('name', isEqualTo: name).get();

    setState(() {
      isNameValid = name.length >= 4 &&
          name.isNotEmpty &&
          !name.contains(' ') &&
          name == name.toLowerCase() && // التحقق من عدم وجود أحرف كبيرة
          RegExp(r'^[a-zA-Z]+$')
              .hasMatch(name) && // التحقق من وجود أحرف غير إنجليزية
          nameSnapshot.docs.isEmpty;
    });

    // التحقق من تنسيق البريد الإلكتروني
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    final emailFormatValid = emailRegExp.hasMatch(email);

    // التحقق من البريد الإلكتروني
    var emailSnapshot =
        emailFormatValid ? await _auth.fetchSignInMethodsForEmail(email) : [];

    setState(() {
      isEmailFormatValid = emailFormatValid;
      isEmailValid = emailFormatValid && emailSnapshot.isEmpty;
    });
  }

  Future<void> _signup() async {
    setState(() {
      snapsho = true;
    });

    await _validateInputs(); // التحقق من الاسم والبريد الإلكتروني

    if (!isNameValid || !isEmailValid || selectedRegion == null) {
      // إذا كان الاسم أو البريد الإلكتروني غير صحيح
      setState(() {
        snapsho = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!isNameValid
              ? 'Name is incorrect or already used'
              : !isEmailFormatValid
                  ? 'تنسيق البريد الإلكتروني غير صحيح'
                  : selectedRegion == null
                      ? 'الرجاء اختيار منطقة'
                      : 'البريد الإلكتروني مستخدم من قبل'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_confirmPasswordController.text == _passwordController.text) {
      try {
        // إنشاء حساب Firebase Authentication
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final user = FirebaseAuth.instance.currentUser;
        // إضافة البيانات إلى قاعدة بيانات Firestore
        await userRef.collection('users').doc(user!.uid).set({
          'id': user.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'region': selectedRegion,
          'photoUrl':
              'https://firebasestorage.googleapis.com/v0/b/fir-giftle-app.appspot.com/o/post_8093dd0b-78a6-4cdc-b9d5-e24697da480d.jpg?alt=media&token=db4df314-8cfa-4d5a-a1af-ad4a2b9fe9a2',
          'displayname': _nameController.text.trim(),
          'bio': 'مرحبا أنا مستخدم جديد',
          'timestam': Timestamp.now(),
          'deviceToken': ''
        });

        Navigator.of(context).pushNamed('/');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Check your email'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password mismatch'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      snapsho = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: snapsho,
        child: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('images/start.jpg'),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isNameValid
                          ? const Color.fromARGB(250, 252, 241, 183)
                          : Color.fromARGB(255, 253, 155, 155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _nameController,
                        onChanged: (value) =>
                            _validateInputs(), // التحقق عند تغيير القيمة
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Name',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isEmailValid
                          ? const Color.fromARGB(250, 252, 241, 183)
                          : Color.fromARGB(255, 253, 155, 155),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _emailController,
                        onChanged: (value) =>
                            _validateInputs(), // التحقق عند تغيير القيمة
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Email',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(250, 252, 241, 183),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Password',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(250, 252, 241, 183),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Confirm Password',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(250, 252, 241, 183),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        value: selectedRegion,
                        items: [
                          DropdownMenuItem(
                            child: Text('Western'),
                            value: 'Western',
                          ),
                          DropdownMenuItem(
                            child: Text('Eastern'),
                            value: 'Eastern',
                          ),
                          DropdownMenuItem(
                            child: Text('Southern'),
                            value: 'Southern',
                          ),
                          DropdownMenuItem(
                            child: Text('Northern'),
                            value: 'Northern',
                          ),
                          DropdownMenuItem(
                            child: Text('Central'),
                            value: 'Central',
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRegion = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select the region',
                          labelStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          border: InputBorder.none,
                        ),
                        dropdownColor: const Color.fromARGB(250, 252, 241, 183),
                        icon:
                            Icon(Icons.arrow_drop_down, color: Colors.black54),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 70),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(126, 187, 57, 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: _signup,
                      child: const Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(126, 187, 57, 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushReplacementNamed('loginscreen');
                      },
                      child: const Center(
                        child: Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String bio;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.bio,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      name: doc['name'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      bio: doc['bio'],
    );
  }
}
