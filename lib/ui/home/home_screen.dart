import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_login_screen/constants.dart';
import 'package:flutter_login_screen/model/user.dart';
import 'package:flutter_login_screen/services/helper.dart';
import 'package:flutter_login_screen/ui/auth/authentication_bloc.dart';
import 'package:flutter_login_screen/ui/auth/welcome/welcome_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../services/authenticate.dart';
import '../auth/signUp/sign_up_bloc.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  late User user;
  XFile? image;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  Future getImage(ImageSource media) async {
    var img = await picker.pickImage(source: media);
    File imageFile = File(img!.path);
    Uint8List imageRaw = await imageFile.readAsBytes();
    String data = await FireStoreUtils.uploadImageToServer(imageRaw);
    var map = <String, dynamic>{};
    map['image'] = img.path;
    try {
      final request = http
          .MultipartRequest("POST", Uri.parse('http://43.204.232.249:5000/predict'));
      final httpImage = await http.MultipartFile.fromPath('image', img.path);
      request.files.add(httpImage);
      final response = await request.send();
      switch (response.statusCode) {
        case 200:
          debugPrint('Hello world');
          var responsed = await http.Response.fromStream(response);
          final jsonResponse = json.decode(responsed.body);
          log(jsonResponse);
          break;
      // return Success(Location.fromMap(data));
        default:
        // 3. return Error with the desired exception
          debugPrint(response.reasonPhrase);
      }
    }on SocketException catch (_) {
      // make it explicit that a SocketException will be thrown if the network connection fails
      rethrow;
    }

    setState(() {
      image = img;
    });
  }

  void myAlert() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text('Please choose media to select'),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 6,
              child: Column(
                children: [
                  ElevatedButton(
                    //if user click this button, user can upload image from gallery
                    onPressed: () {
                      Navigator.pop(context);
                      getImage(ImageSource.gallery);
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.image),
                        Text('From Gallery'),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    //if user click this button. user can upload image from camera
                    onPressed: () {
                      Navigator.pop(context);
                      getImage(ImageSource.camera);
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.camera),
                        Text('From Camera'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }


  _onCameraClick(BuildContext context) {
    final action = CupertinoActionSheet(
      title: const Text(
        'Add Profile Picture',
        style: TextStyle(fontSize: 15.0),
      ),
      actions: [
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            context.read<SignUpBloc>().add(ChooseImageFromGalleryEvent());
          },
          child: const Text('Choose from gallery'),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            context.read<SignUpBloc>().add(CaptureImageByCameraEvent());
          },
          child: const Text('Take a picture'),
        )
      ],
      cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context)),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state.authState == AuthState.unauthenticated) {
          pushAndRemoveUntil(context, const WelcomeScreen(), false);
        }
      },
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(colorPrimary),
                ),
                child: Text(
                  'Drawer Header',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                title: Text(
                  'Logout',
                  style: TextStyle(
                      color: isDarkMode(context)
                          ? Colors.grey.shade50
                          : Colors.grey.shade900),
                ),
                leading: Transform.rotate(
                  angle: pi / 1,
                  child: Icon(
                    Icons.exit_to_app,
                    color: isDarkMode(context)
                        ? Colors.grey.shade50
                        : Colors.grey.shade900,
                  ),
                ),
                onTap: () {
                  context.read<AuthenticationBloc>().add(LogoutEvent());
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text(
            'Home',
            style: TextStyle(
                color: isDarkMode(context)
                    ? Colors.grey.shade50
                    : Colors.grey.shade900),
          ),
          iconTheme: IconThemeData(
              color: isDarkMode(context)
                  ? Colors.grey.shade50
                  : Colors.grey.shade900),
          backgroundColor:
              isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade50,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              user.profilePictureURL == ''
                  ? CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey.shade400,
                      child: ClipOval(
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  : displayCircleImage(user.profilePictureURL, 80, false),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(user.fullName()),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(user.email),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(user.userID),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 8.0, top: 32, right: 8, bottom: 8),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        myAlert();
                      },
                      child: const Text('Upload Photo'),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    //if image not null show the image
                    //if image null show text
                    image != null
                        ? Stack(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            image = null;
                          },
                          child: const Text('Clean Image'),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              //to show image, you type like this.
                              File(image!.path),
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width,
                              height: 300,
                            ),
                          ),
                        )
                      ],
                    )
                        :
                        const SizedBox(width: 10, height: 10,)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
