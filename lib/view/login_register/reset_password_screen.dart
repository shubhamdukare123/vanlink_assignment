import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:vanlink_assignment/view/login_register/login_screen.dart";

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 60,
            ),
            Row(
              children: [
                const SizedBox(width: 10),
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Image.asset("assets/sign_up_page/arrow_left.png")),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 20),
                Text(
                  "Reset Password",
                  style: GoogleFonts.openSans(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "Please enter your email address to",
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w400, fontSize: 15),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "request a password reset",
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w400, fontSize: 15),
              ),
            ),
            const SizedBox(height: 30),
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
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
                child:
                    Image.asset("assets/verification_page/continue_button.png"),
                onTap: () {
                  Navigator.of(context).pop();
                })
          ],
        ),
      ),
    );
  }
}
