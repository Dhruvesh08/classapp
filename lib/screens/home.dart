import 'dart:io';

import 'package:classapp/modals/post.dart';
import 'package:classapp/modals/user.dart';
import 'package:classapp/screens/create_user_account.dart';
import 'package:classapp/widgets/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'chat.dart';
import 'feed.dart';
import 'package:image/image.dart' as Im;

final GoogleSignIn googleSignIn = GoogleSignIn();
final FirebaseStorage storagerRef = FirebaseStorage.instance;
final userRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final DateTime timestamp = DateTime.now();
User localuser;
var userId;
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;

  @override
  void initState() {
    super.initState();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handleSignIn(GoogleSignInAccount account) {
    if (account != null) {
      createUserinFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserinFirestore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.doc(user.id).get();

    if (!doc.exists) {
      final User newuser = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateUserAccount(),
        ),
      );
      userRef.doc(user.id).set({
        "id": user.id,
        "userName": newuser.name,
        "photoUrl": user.photoUrl,
        "middleName": newuser.middleName,
        "lastName": newuser.lastName,
        "mobile": newuser.middleName,
        "department": newuser.department,
        "address": newuser.address,
        "city": newuser.city,
        "pincode": newuser.pincode,
        "state": newuser.state,
        "country": newuser.country,
        "isFaculty": newuser.isFaculty,
        "timestamp": timestamp
      });
      doc = await userRef.doc(user.id).get();
    }

    currentUser = User.fromDocument(doc);

    print("====================");

    print(currentUser.id);
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  List<Widget> _pages = [
    Feed(),
    UploadImage(),
    Chat(),
    Profile(),
  ];

  int _selectedPageIndex = 0;

  void _selectedPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context).size;
    return isAuth ? userScreen(mediaQuery) : loginScreen(mediaQuery);
  }

  Scaffold loginScreen(mediaQuery) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () => login(),
                child: Container(
                  child: Column(
                    children: [
                      Container(
                        height: mediaQuery.height * 0.2,
                        width: mediaQuery.width * 0.3,
                        child: Image.asset("assets/images/teacher01.png"),
                      ),
                      Text(
                        "Teacher",
                        style: Theme.of(context).textTheme.headline6,
                      )
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => login(),
                child: Container(
                  child: Column(
                    children: [
                      Container(
                        height: mediaQuery.height * 0.2,
                        width: mediaQuery.width * 0.3,
                        child: Image.asset("assets/images/student.png"),
                      ),
                      Text(
                        "Student",
                        style: Theme.of(context).textTheme.headline6,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Please Select any one.",
                    style: Theme.of(context)
                        .textTheme
                        .headline6
                        .copyWith(color: Colors.blue)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Scaffold userScreen(mediaQuery) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: _selectedPage,
        currentIndex: _selectedPageIndex,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: _pages[_selectedPageIndex],
    );
  }
}

class UploadImage extends StatefulWidget {
  const UploadImage({Key key}) : super(key: key);
  @override
  _UploadImageState createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  File _image;
  final picker = ImagePicker();
  String postId = Uuid().v4();
  TextEditingController _postDataController = TextEditingController();

  bool isUploading = false;

  Future getImage() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.camera, imageQuality: 30);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  _handleChoosePhoto() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 30);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  _compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    Im.Image imageFile = Im.decodeImage(_image.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 30));
    setState(() {
      _image = compressedImageFile;
    });
  }

  _createPostInForeStore({String mediaUrl, String postData}) {
    postsRef.doc(currentUser.id).collection("userPosts").doc(postId).set({
      "postId": postId,
      "creatorId": currentUser.id,
      "userName": currentUser.name,
      "mediaUrl": mediaUrl,
      "caption": postData,
      "timestemp": timestamp,
      "likes": {},
    });
    _postDataController.clear();
    setState(() {
      _image = null;
      isUploading = false;
    });
  }

  _handleSubmit() async {
    setState(() {
      isUploading = true;
    });

    await _compressImage();
    String mediaUrl = await _uploadImage(File);
    _createPostInForeStore(
      mediaUrl: mediaUrl,
      postData: _postDataController.text,
    );
    _postDataController.clear();
    print(_postDataController.text);
    setState(() {
      _image = null;
      isUploading = false;
    });
  }

  Future<String> _uploadImage(imageFile) async {
    UploadTask uploadTask =
        storagerRef.ref().child("post_$postId.jpg").putFile(_image);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => uploadTask);
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQurey = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: SafeArea(
        child: Column(
          children: [
            Card(
              elevation: 10.00,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.00),
                child: Container(
                  height: mediaQurey.height * 0.3,
                  width: mediaQurey.width * 0.6,
                  child: _image == null
                      ? Image.asset(
                          "assets/images/image_upload.png",
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          _image,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            SizedBox(
              height: mediaQurey.height * 0.1,
            ),
            Column(
              children: [
                Text("Post"),
                ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    foregroundImage: NetworkImage(currentUser.photoUrl),
                  ),
                  title: TextField(
                    controller: _postDataController,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: mediaQurey.height * 0.1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => getImage(),
                      child: Container(
                        width: mediaQurey.width * 0.2,
                        child: Image.asset(
                          "assets/images/camera.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Text(
                      "Camera",
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(color: Colors.black, fontSize: 16),
                    )
                  ],
                ),
                Column(
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => _handleChoosePhoto(),
                      child: Container(
                        width: mediaQurey.width * 0.2,
                        child: Image.asset(
                          "assets/images/gallery.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Text(
                      "Gallery",
                      style: Theme.of(context)
                          .textTheme
                          .headline6
                          .copyWith(color: Colors.black, fontSize: 16),
                    )
                  ],
                ),
              ],
            ),
            SizedBox(
              height: mediaQurey.height * 0.05,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isUploading ? null : () => _handleSubmit(),
                      child: Text("Create Post"),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  int postCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getProfilePosts();
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(currentUserId)
        .collection("userPosts")
        .orderBy('timestemp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildProfilePost() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        // children: posts,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 40,
              foregroundImage: NetworkImage(currentUser.photoUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Name : ",
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    currentUser.name,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Department : ",
                      style: Theme.of(context).textTheme.headline6),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    currentUser.department,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "City : ",
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    currentUser.city,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "State : ",
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    currentUser.state,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Country : ",
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    currentUser.country,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Conatct No : ",
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    currentUser.mobileNo,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Profile"),
      ),
      body: SingleChildScrollView(
          child: Container(
        child: buildProfilePost(),
      )),
    );
  }
}

class Feed extends StatefulWidget {
  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  List<Post> feedPosts;
  @override
  void initState() {
    // TODO: implement initState
    getTimeLine();
  }

  getTimeLine() async {
    QuerySnapshot snapshot = await postsRef
        .doc(currentUser.id)
        .collection("userPosts")
        .orderBy("timestemp", descending: true)
        .get();

    List<Post> feedPosts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.feedPosts = feedPosts;
    });
  }

  buildTimeLine() {
    if (feedPosts == null) {
      return Center(child: CircularProgressIndicator());
    } else {
      return ListView(
        children: feedPosts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: RefreshIndicator(
          child: buildTimeLine(), onRefresh: () => getTimeLine()),
    );
  }
}
