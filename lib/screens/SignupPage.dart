// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:personlayze/constants/colors.dart';
// import 'package:personlayze/screens/LoginPage.dart';
// import 'package:personlayze/widgets/CustomHeader.dart';

// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController contactController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/images/bg.jpg"),
//                 fit: BoxFit.fitWidth,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const CustomHeader(title: "Personalyze"),
//                 const SizedBox(height: 30),
//                 const Text(
//                   "SIGN UP",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 22,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 _buildTextField(fullNameController, "Full Name"),
//                 const SizedBox(height: 10),
//                 _buildTextField(contactController, "Contact Number"),
//                 const SizedBox(height: 10),
//                 _buildTextField(emailController, "Email"),
//                 const SizedBox(height: 10),
//                 _buildTextField(passwordController, "Password", isPassword: true),
//                 const SizedBox(height: 20),
//                 const Center(
//                   child: Text("or", style: TextStyle(color: Colors.white, fontSize: 16)),
//                 ),
//                 const SizedBox(height: 10),
//                 Center(
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.6,
//                     child: ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(25),
//                           side: BorderSide(color: Colors.blue, width: 2),
                          
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//                       ),
//                       child:  Row(
//                         children: [
//                           FaIcon(FontAwesomeIcons.google),
//                           SizedBox(width: 10,),
//                           Text(
//                             "Continue with Google",
//                             style: TextStyle(fontSize: 16, color: Colors.black),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 10,),
//                 GestureDetector(
//                   onTap: (){
//                     Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginPage()));
//                   },
//                   child: Center(child: Text("Already a user? Sign in instead"))),
//                   SizedBox(height: 10,),
//                   Center(
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width * 0.35,
//                     child: ElevatedButton(
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(25),
//                           side: BorderSide(color: Colors.blue, width: 2),
                          
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//                       ),
//                       child:  Text(
//                           "Skip for now",
//                           style: TextStyle(fontSize: 16, color: Colors.black),
//                         ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
//     return TextField(
//       controller: controller,
//       obscureText: isPassword,
//       style: const TextStyle(color: Colors.black),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.black),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.black),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.black),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.black),
//         ),
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.2),
//       ),
//     );
//   }
// }