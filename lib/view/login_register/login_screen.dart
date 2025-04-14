// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanlink_assignment/controller/session_data.dart';
import 'package:vanlink_assignment/view/login_register/reset_password_screen.dart';
import 'package:vanlink_assignment/view/driver_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanlink_assignment/view/login_register/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanlink_assignment/view/parents_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => EzyEventUIState();
}

class EzyEventUIState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool rememberMeSwitch = false;
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  
  String selectedRole = "User";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/vanlink_logo_no_background.png",
                height: 300,
              ),

              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  roleButton("Parent"),
                  roleButton("Driver"),
                ],
              ),

              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: loginForm(),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: rememberMeSwitch,
                    onChanged: (value) {
                      setState(() {
                        rememberMeSwitch = value!;
                      });
                    },
                  ),
                  Text("Remember Me", style: GoogleFonts.openSans()),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return const ResetPasswordPage();
                      }));
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.openSans(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: GoogleFonts.openSans()),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return const SignUpPage();
                        }));
                      },
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.openSans(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  Widget loginForm() {
    return Column(
      key: ValueKey<String>(selectedRole),
      children: [
        SizedBox(
          height: 56,
          width: 317,
          child: TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "abc@gmail.com",
              prefixIcon: const Icon(Icons.email_outlined),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => value!.isEmpty ? "Please enter email" : null,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          width: 317,
          child: TextFormField(
            obscureText: _obscurePassword,
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: "Your password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) =>
                value!.isEmpty ? "Please enter password" : null,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(255, 193, 7, 1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
          onPressed: () async {
            bool isValid = _formKey.currentState!.validate();

            if (isValid) {
              try {
                await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim());

                QuerySnapshot response = await FirebaseFirestore.instance
                    .collection("AppUsers")
                    .get();

                String? role = "";
                String? email;
                String? name;

                for (int i = 0; i < response.docs.length; i++) {
                  if (response.docs[i]['email'] ==
                      _emailController.text.trim()) {
                    email = response.docs[i]['email'];

                    name = response.docs[i]['name'];

                    role = response.docs[i]['role'];
                    break;
                  }
                }

                await SessionData.storeSessionData(
                  loginData: true,
                  email: email!,
                  name: name!,
                  role: role!,
                );

                if (role == "Parent") {
                  

                  if (selectedRole == "Parent") {
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (context) {
                      return const ParentsHomeScreen();
                    }));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid Credentials")));
                  }
                } else if (role == "Driver") {
                  if (selectedRole == "Driver") {
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (context) {
                      return const DriverHomeScreen();
                    }));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid Credentials")));
                  }
                }
                
              } on FirebaseAuthException {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid Credentials")));
              }
            }
          },
          child: Text(
            "Login",
      
            style: GoogleFonts.openSans(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
