import "dart:async";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";

class VerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  VerificationPage({required this.phoneNumber, required this.verificationId});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _box1Controller = TextEditingController();
  final TextEditingController _box2Controller = TextEditingController();
  final TextEditingController _box3Controller = TextEditingController();
  final TextEditingController _box4Controller = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  String otpCode = "";

  int timeLeft = 30;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    startCountDownTimer();
  }

  void startCountDownTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void verifyOTP() async {
    String otp = _box1Controller.text +
        _box2Controller.text +
        _box3Controller.text +
        _box4Controller.text;
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );
      await auth.signInWithCredential(credential);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("OTP Verified!")));
      // Navigate to the next screen
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Text("Enter OTP",
              style: GoogleFonts.openSans(
                  fontWeight: FontWeight.bold, fontSize: 24)),
          Text("Sent to: ${widget.phoneNumber}",
              style: GoogleFonts.openSans(fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOTPBox(_box1Controller),
              _buildOTPBox(_box2Controller),
              _buildOTPBox(_box3Controller),
              _buildOTPBox(_box4Controller),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: verifyOTP, child: Text("Verify")),
          Text("Resend code in: 0:$timeLeft"),
        ],
      ),
    );
  }

  Widget _buildOTPBox(TextEditingController controller) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(border: OutlineInputBorder()),
      ),
    );
  }
}
