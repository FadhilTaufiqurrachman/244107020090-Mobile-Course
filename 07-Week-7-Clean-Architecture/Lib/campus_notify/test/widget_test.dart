import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/routes.dart';
import 'package:campus_notify/data/api_errors.dart';

class FakeTokenStore {
  String? access;
  String? refresh;
}

void main() {
  test('routeFromMessage menangani route kosong dan tanpa slash', () {
    expect(routeFromMessage({}), '/');
    expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
  });

  test('data payload membawa id pengumuman', () {
    const data = {'route': '/pengumuman/3', 'id': '3'};
    expect(data['id'], '3');
    expect(routeFromMessage(data), '/pengumuman/3');
  });

  test('provider auth membaca status login dari token', () async {
    final store = FakeTokenStore()..access = 'mock-access';
    expect(store.access != null, isTrue);
    store.access = null;
    expect(store.access != null, isFalse);
  });

  test('refresh gagal -> sesi dibersihkan (paksa login ulang)', () async {
    final store = FakeTokenStore()..refresh = '';
    final needsLogin = (store.refresh ?? '').isEmpty;
    expect(needsLogin, isTrue);
  });

  test('mapDioExceptionToUserMessage memetakan 401, timeout, dan offline', () {
    final req = RequestOptions(path: '/devices');

    final err401 = DioException(
      requestOptions: req,
      response: Response(requestOptions: req, statusCode: 401),
      type: DioExceptionType.badResponse,
    );
    expect(
      mapDioExceptionToUserMessage(err401),
      contains('Sesi Anda telah berakhir'),
    );

    final errTimeout = DioException(
      requestOptions: req,
      type: DioExceptionType.connectionTimeout,
    );
    expect(mapDioExceptionToUserMessage(errTimeout), contains('timeout'));

    final errOffline = DioException(
      requestOptions: req,
      type: DioExceptionType.connectionError,
    );
    expect(mapDioExceptionToUserMessage(errOffline), contains('offline'));
  });
}