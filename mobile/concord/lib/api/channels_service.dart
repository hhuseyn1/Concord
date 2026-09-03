import 'api_client.dart';
import 'models/channel_response.dart';
import 'models/enums.dart';

class ChannelsService {
  ChannelsService(this._client);

  final ApiClient _client;

  Future<List<ChannelResponse>> listChannels(String serverId) async {
    final data = await _client.get('/Servers/$serverId/Channels');
    return (data as List<dynamic>)
        .map((e) => ChannelResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChannelResponse> createChannel(
    String serverId, {
    required String name,
    required ChannelType type,
  }) async {
    final data = await _client.post(
      '/Servers/$serverId/Channels',
      body: {'Name': name, 'Type': type.toWire()},
    );
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<ChannelResponse> updateChannel(
    String serverId,
    String channelId, {
    required String name,
  }) async {
    final data = await _client.put(
      '/Servers/$serverId/Channels/$channelId',
      body: {'Name': name},
    );
    return ChannelResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteChannel(String serverId, String channelId) {
    return _client.delete('/Servers/$serverId/Channels/$channelId');
  }
}
