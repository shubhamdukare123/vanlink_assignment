// ignore_for_file: use_build_context_synchronously

import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phonenumberController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _cnfpassController = TextEditingController();

  String selectedRole = "Parent";

  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Row(
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Image.asset("assets/arrow_left.png")),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 20),
                Text(
                  "Sign Up",
                  style: GoogleFonts.openSans(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                roleButton("Parent"),
                roleButton("Driver"),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: 317,
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    hintText: "Full Name",
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: 317,
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                    hintText: "abc@gmail.com",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: 317,
              child: TextField(
                controller: _phonenumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: "Phone No.",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: 317,
              child: TextField(
                controller: _passController,
                decoration: InputDecoration(
                    hintText: "Your Password",
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              width: 317,
              child: TextField(
                controller: _cnfpassController,
                decoration: InputDecoration(
                    hintText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),

            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isNotEmpty &&
                    _emailController.text.trim().isNotEmpty &&
                    _passController.text.trim().isNotEmpty &&
                    _cnfpassController.text.trim().isNotEmpty &&
                    (_passController.text.trim() ==
                        _cnfpassController.text.trim())) {
                  try {
                    await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passController.text.trim());
              
                    await FirebaseFirestore.instance
                        .collection("AppUsers")
                        .add({
                      "name": _nameController.text,
                      "email": _emailController.text,
                      "role": selectedRole,
                      "password": _passController.text
                    });

                    if (selectedRole == "Driver") {
                      await FirebaseFirestore.instance.collection("Driver").add(
                        {
                          "name": _nameController.text.trim(),
                          "email": _emailController.text.trim(),
                        },
                      );
                    }

                    Navigator.pop(context);

                    //sendOTP();
                  } on FirebaseAuthException catch (exception) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${exception.message}")));
                  }
                } else {
                  if (_passController.text.trim() ==
                      _cnfpassController.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password does not match")));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 193, 7, 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                "Sign Up",
                style: GoogleFonts.openSans(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(
              height: 50,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 80,
                ),
                Text(
                  "Already have an account? ",
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Sign in",
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget roleButton(String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedRole == role
              ? const Color.fromRGBO(255, 193, 7, 1)
              : Colors.grey[300],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          setState(() {
            selectedRole = role;

          });
        },
        child: Text(
          role,
          style: GoogleFonts.openSans(
            color: selectedRole == role ? Colors.black : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
