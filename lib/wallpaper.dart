import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

String query = 'minimalistic';
String pic =
    'https://images.pexels.com/photos/6569306/pexels-photo-6569306.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2';
List<String> photos = [];
List<String> finalPhotos = [];
Future getCuratedPhotos() async {
  http.Response response = await http.get(
      Uri.parse(
          "https://api.pexels.com/v1/search?query=$query&per_page=62&page=1"),
      headers: {
        HttpHeaders.authorizationHeader:
            '563492ad6f91700001000001fd3fd596460d401a9dbb386b14bfec52'
      });
  var data = response.body;
  for (int i = 1; i < 61; i++) {
    pic = jsonDecode(data)['photos'][i]['src']['portrait'];
    photos.add(pic);
  }
  finalPhotos = photos;
}
