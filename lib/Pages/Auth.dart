import 'dart:io';
import 'dart:math';
import 'package:chat_app/Widgets/userimgpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firebase = FirebaseAuth.instance;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  var enteredUserName = '';
  var enteredEmail = '';
  var enteredPassword = '';
  final _formKey = GlobalKey<FormState>();
  var isLogin = true;
  var isUploading = false;
  File? _selectedImage;

  void submit() async {
    setState(() {
      isUploading = true;
    });

    final isvalid = _formKey.currentState!.validate();

    if (!isvalid) {
      return;
    }
    if (isvalid) {
      _formKey.currentState!.save();
    }

    if (!isLogin && _selectedImage == null) {
      return;
    }
    if (isLogin) {
      try {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Invalid mail or password")));
        setState(() {
          isUploading = false;
        });
      }
    } else {
      try {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
        final imageData = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child("${userCredentials.user!.uid}.jpg");
        await imageData.putFile(_selectedImage!);
        final imageURL = await imageData.getDownloadURL();
        FirebaseFirestore.instance
            .collection('users')
            .doc('${userCredentials.user!.uid}')
            .set({
          'username': enteredUserName,
          'email': enteredEmail,
          'imageURL': imageURL
        });
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {}
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed")));
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  margin: EdgeInsets.only(
                    top: 30,
                    bottom: 10,
                    left: 20,
                    right: 20,
                  ),
                  child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        "assets/images/chat.png",
                        width: 150,
                      ))),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (!isLogin)
                          UserImagePicker(
                            onPickedImage: (pickedImage) {
                              _selectedImage = pickedImage;
                            },
                          ),
                        if (!isLogin)
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Username',
                              hintText: 'Enter Userame',
                            ),
                            keyboardType: TextInputType.name,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter a valid UserName";
                              }
                            },
                            onSaved: (value) {
                              enteredUserName = value!;
                            },
                          ),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter Email Address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains("@")) {
                              return "Please enter a valid email address";
                            }
                          },
                          onSaved: (value) {
                            enteredEmail = value!;
                          },
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter Password',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Password cannot be empty";
                            } else {
                              if (value.length < 8) {
                                return "Password should contain minimum 8 characters";
                              }
                            }
                          },
                          onSaved: (value) {
                            enteredPassword = value!;
                          },
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        if (isUploading) CircularProgressIndicator(),
                        if (!isUploading)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            onPressed: () => submit(),
                            child: Text(isLogin ? "Login" : "Register"),
                          ),
                        if (!isUploading)
                          TextButton(
                              onPressed: () => setState(() {
                                    isLogin = !isLogin;
                                  }),
                              child: Text(isLogin
                                  ? "Create an Account"
                                  : "I Already have an Account"))
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
