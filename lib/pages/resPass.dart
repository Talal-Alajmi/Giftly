import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:validators/validators.dart';
// تحتاج إلى إضافة حزمة validators في pubspec.yaml

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool showSpinner = false;
  String message = '';

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    setState(() {
      showSpinner = true;
      message = '';
    });

    final email = emailController.text.trim();

    if (!isEmail(email)) {
      setState(() {
        message = 'Please Enter a Valid Email';
        showSpinner = false;
      });
      return;
    }

    try {
      // أرسل رابط إعادة تعيين كلمة المرور
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        message = 'Check Your Email To Reset Your Password';
        showSpinner = false;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          message = 'The Email is Not Found';
          showSpinner = false;
        });
      } else {
        setState(() {
          message = 'Error: ${e.message}';
          showSpinner = false;
        });
      }
    } catch (e) {
      setState(() {
        message = 'An unexpected error occurred: $e';
        showSpinner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        body: Container(
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
                SizedBox(
                  height: 70,
                ),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(250, 252, 241, 183),
                        borderRadius: BorderRadius.circular(10)),
                    child: Image.asset(
                      'images/44.png',
                      height: 130,
                      width: 130,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Your Email',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 70,
                      ),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(126, 187, 57, 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: resetPassword,
                          child: const Center(
                            child: Text(
                              'Send Link',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
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
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: message.contains('حدث خطأ')
                        ? Colors.red
                        : const Color.fromARGB(255, 8, 10, 8),
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
