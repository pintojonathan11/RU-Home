import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:path/path.dart' show join;
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'UserInfo.dart';

List<UserInfo> userInfo = [];
List<String> picturesSaved = [];
var i = 30;
var databaseReference;

List<String> getUserInfo(String user) {
  for (var i = 0; i < userInfo.length; i++) {
    if (userInfo[i].name == user) {
      return userInfo[i].picturesSaved;
    }
  }
  return [];
}

Future<void> main() async {
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  var firstCamera = cameras[1];

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: SelectUser(firstCamera),
//      home: TakePictureScreen(
//        // Pass the appropriate camera to the TakePictureScreen widget.
//        camera: firstCamera,
//      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  String user;

  TakePictureScreen({
    Key key,
    this.user,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState(user);
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  String user;
  Future<void> _initializeControllerFuture;

  TakePictureScreenState(user) {
    this.user = user;
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              'image' + i.toString() + '.png',
            );
            i++;

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

//            final File image = new File(path);
//
//            final File newImage = await image.copy("$path/" +
//                user +
//                "image" +
//                (picturesSaved.length + 1).toString());
            picturesSaved.add(path);
            print(picturesSaved);
            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetail(path, user),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String user;
  DisplayPictureScreen({Key key, this.imagePath, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(picturesSaved.length.toString() + ' out of 10')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: ListView(
        children: picturesSaved.map((user) => User(imagePath, user)).toList(),
      ),
      floatingActionButton: new Visibility(
        visible: picturesSaved.length > 9, //Change to 9 later
        child: new FloatingActionButton.extended(
          onPressed: () async {
            for (int i = 0; i < picturesSaved.length; i++) {
              StorageReference storageReference = FirebaseStorage.instance
                  .ref()
                  .child(user + '/${Path.basename(picturesSaved[i])}');
              StorageUploadTask uploadTask =
                  storageReference.putFile(new File(picturesSaved[i]));
              await uploadTask.onComplete;
              print('File Uploaded');
              var a = 0;
              Map<String, String> users = new Map();
              await storageReference.getDownloadURL().then((fileURL) {
                print(fileURL);
                String temp = '${DateTime.now()}';
                users.putIfAbsent(
                    temp.substring(temp.length - 6), () => fileURL);
              });
              databaseReference.child("Users").child(user).update(users);
            }
          },
          icon: Icon(Icons.file_upload),
          label: Text("Upload"),
        ),
      ),
    );
  }
}

class User extends StatelessWidget {
  final String path;
  final String user;

  User(this.path, this.user) {}

  @override
  Widget build(BuildContext context) {
    /// [InkWell] to listen to tap and give ripple effect
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => SimplePicture(path))),
      child: Container(
        /// Give nice padding
        padding: EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            /// This is the important part, we need [Hero] widget with unique tag for this item.
            GestureDetector(
              child: Icon(
                Icons.delete,
                color: Colors.teal,
              ),
              onTap: () async {
                print(path);
                print(picturesSaved);
                picturesSaved.remove(path);
                Navigator.of(context).pop();
                if (picturesSaved.length != 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DisplayPictureScreen(
                        imagePath: path,
                        user: user,
                      ),
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Hero(
                tag: user + path,
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: Image.file(File(path)).image,
                ),
              ),
            ),
            Padding(
              /// Give name text a Padding
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "Picture " + (picturesSaved.indexOf(path) + 1).toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDetail extends StatelessWidget {
  final String path;
  final String user;

  UserDetail(this.path, this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.file(File(path)),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.view_list,
        children: [
          SpeedDialChild(
              child: Icon(Icons.check),
              label: "Save Image",
              labelBackgroundColor: Colors.teal,
              labelStyle: TextStyle(
                color: Colors.white,
              ),
              onTap: () async {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(
                      imagePath: path,
                      user: user,
                    ),
                  ),
                );
              }),
          SpeedDialChild(
              child: Icon(Icons.clear),
              label: "Delete Image",
              labelBackgroundColor: Colors.teal,
              labelStyle: TextStyle(
                color: Colors.white,
              ),
              onTap: () async {
                picturesSaved.remove(path);
                Navigator.of(context).pop();
              }),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class SimplePicture extends StatelessWidget {
  final String path;

  SimplePicture(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Image.file(File(path)),
    );
  }
}

class SelectUser extends StatelessWidget {
  var camera;
  SelectUser(camera) {
    this.camera = camera;
  }

  @override
  Widget build(BuildContext context) {
    final databaseReference = FirebaseDatabase.instance.reference();
    getData(databaseReference);
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Users'),
        leading: null,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: ListView(
        children:
            userInfo.map((user) => SelectUserRow(user.name, camera)).toList(),
      ),

      floatingActionButton: new Visibility(
        child: new FloatingActionButton.extended(
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddUser(camera),
              ),
            );
          },
          icon: Icon(Icons.add_circle_outline),
          label: Text("Add User"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void getData(databaseReference) {
    databaseReference.once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');
    });
  }
}

class SelectUserRow extends StatelessWidget {
  String user;
  var camera;

  SelectUserRow(String user, camera) {
    this.user = user;
    this.camera = camera;
  }

  @override
  Widget build(BuildContext context) {
    databaseReference = FirebaseDatabase.instance.reference();
    getData();
    return InkWell(
      onTap: () {
        picturesSaved = getUserInfo(user);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    TakePictureScreen(user: user, camera: camera)));
      },
      child: Container(
        /// Give nice padding
        padding: EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Text(
              user,
              style: new TextStyle(
                fontSize: 20,
                height: 2.0,
              ),
            ),
            Divider(
              height: 2,
              thickness: 10,
              endIndent: 2,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  void getData() {
    databaseReference.once().then((DataSnapshot snapshot) {
      print('Data : ${snapshot.value}');
    });
  }
}

class AddUser extends StatelessWidget {
  final myController = TextEditingController();
  var camera;
  AddUser(camera) {
    this.camera = camera;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: TextField(
          style: new TextStyle(
            fontSize: 20,
            height: 2.0,
          ),
          controller: myController,
          decoration: InputDecoration(hintText: 'Enter User\'s name'),
        ),
      ),
      floatingActionButton: new Visibility(
        child: new FloatingActionButton.extended(
          onPressed: () async {
            String userName = myController.text;
            userInfo.add(UserInfo(userName, []));
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectUser(camera),
              ),
            );
          },
          icon: Icon(Icons.check),
          label: Text("Done"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
