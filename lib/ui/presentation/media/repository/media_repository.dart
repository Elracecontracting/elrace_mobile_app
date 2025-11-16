import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../../utils/di.dart';
import '../../../../utils/urll_utils.dart';
import '../../signin/data/repository.dart';
import '../data/media_model.dart';
import 'i_media_repository.dart';

class MediaRepository implements IMediaRepository {
  final userRepo = sl.get<UserRepo>();

  @override
  Future<List<MediaModel>> getMediaList() async {
    try {
      final loginResponse = await userRepo.getLoginResponse();
      var token = loginResponse!.result!.token!;

      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token"
      };

      final body = jsonEncode({"jsonrpc": "2.0", "params": {}});
      final url = Uri.parse("${UrlUtil.baseUrl}${UrlUtil.mediaAttachmentsApi}");
      final request = http.Request('GET', url)
        ..headers.addAll(headers)
        ..body = body;
      print(token);
      print(url);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('Media Attachments API Response: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['result'] != null && json['result']['data'] != null) {
          List<dynamic> mediaData = json['result']['data'];
          return mediaData.map((item) => MediaModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      log('Error in getMediaList: $e');
      return [];
    }
  }

  @override
  Future<void> addMedia(MediaModel media) async {
    throw UnimplementedError('Add media functionality not implemented in API');
  }

  @override
  Future<void> updateMedia(MediaModel media) async {
    throw UnimplementedError(
        'Update media functionality not implemented in API');
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    throw UnimplementedError(
        'Delete media functionality not implemented in API');
  }

  @override
  Future<List<MediaModel>> getMediaByType(MediaType type) async {
    final allMedia = await getMediaList();
    return allMedia.where((media) => media.type == type).toList();
  }

  @override
  Future<List<MediaModel>> searchMedia(String keyword) async {
    final allMedia = await getMediaList();
    return allMedia
        .where((media) =>
            media.name.toLowerCase().contains(keyword.toLowerCase()) ||
            media.type.name.toLowerCase().contains(keyword.toLowerCase()) ||
            media.fileExtension.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }
}
