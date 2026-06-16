import 'package:flutter_test/flutter_test.dart';
import 'package:easy_auth/easy_auth.dart';

void main() {
  // ==========================================================================
  // MergeEvent — 解析后端 binding.go 的 merge_event 字段
  // ==========================================================================
  group('MergeEvent.fromJson', () {
    test('parses other_into_me direction', () {
      final e = MergeEvent.fromJson({
        'merge_id': 'm1',
        'direction': 'other_into_me',
        'source_user_id': 'src',
        'target_user_id': 'tgt',
        'merged_at': '2026-06-15T10:00:00Z',
        'revert_deadline': '2026-06-22T10:00:00Z',
      });
      expect(e.mergeId, 'm1');
      expect(e.direction, MergeDirection.otherIntoMe);
      expect(e.sourceUserId, 'src');
      expect(e.targetUserId, 'tgt');
      // 业务 app 用 fromUserId / toUserId 屏蔽 direction 细节
      expect(e.fromUserId, 'src');
      expect(e.toUserId, 'tgt');
    });

    test('parses me_into_other direction', () {
      final e = MergeEvent.fromJson({
        'merge_id': 'm2',
        'direction': 'me_into_other',
        'source_user_id': 'src',
        'target_user_id': 'tgt',
        'merged_at': '2026-06-15T10:00:00Z',
      });
      expect(e.direction, MergeDirection.meIntoOther);
      // me_into_other 时 source 仍是被吞的一方 — from/to 不变
      expect(e.fromUserId, 'src');
      expect(e.toUserId, 'tgt');
    });

    test('fromUserId / toUserId 始终等价于 sourceUserId / targetUserId (合并不可逆)', () {
      final e = MergeEvent.fromJson({
        'merge_id': 'm3',
        'direction': 'me_into_other',
        'source_user_id': 'src',
        'target_user_id': 'tgt',
        'merged_at': '2026-06-15T10:00:00Z',
      });
      expect(e.fromUserId, 'src');
      expect(e.toUserId, 'tgt');
    });

    test('falls back to otherIntoMe on unknown direction string', () {
      final e = MergeEvent.fromJson({
        'merge_id': 'm4',
        'direction': 'garbage_value',
        'source_user_id': 'a',
        'target_user_id': 'b',
        'merged_at': '2026-06-15T10:00:00Z',
      });
      expect(e.direction, MergeDirection.otherIntoMe);
    });

    test('handles missing fields gracefully', () {
      final e = MergeEvent.fromJson({});
      expect(e.mergeId, '');
      expect(e.sourceUserId, '');
      expect(e.targetUserId, '');
      expect(e.mergedAt.millisecondsSinceEpoch, 0);
    });
  });

  // ==========================================================================
  // BindResult — 三态 + merge_event 嵌入 BindOk
  // ==========================================================================
  group('BindResult.fromJson', () {
    test('status=ok → BindOk without merge_event', () {
      final r = BindResult.fromJson({
        'status': 'ok',
        'linked_channels': [
          {
            'channel_id': 'sms',
            'channel_name': 'SMS',
            'channel_user_id_masked': '139***1234',
            'bound_at': '2026-06-15T10:00:00Z',
          }
        ],
      });
      expect(r, isA<BindOk>());
      final ok = r as BindOk;
      expect(ok.linkedChannels.length, 1);
      expect(ok.linkedChannels.first.channelId, 'sms');
      expect(ok.mergeEvent, isNull);
    });

    test('status=ok with merge_event → BindOk.mergeEvent populated', () {
      final r = BindResult.fromJson({
        'status': 'ok',
        'linked_channels': [],
        'merge_event': {
          'merge_id': 'mid',
          'direction': 'other_into_me',
          'source_user_id': 's',
          'target_user_id': 't',
          'merged_at': '2026-06-15T10:00:00Z',
        },
      });
      expect(r, isA<BindOk>());
      final ok = r as BindOk;
      expect(ok.mergeEvent, isNotNull);
      expect(ok.mergeEvent!.mergeId, 'mid');
      expect(ok.mergeEvent!.direction, MergeDirection.otherIntoMe);
    });

    test('status=already_bound → BindAlreadyBound', () {
      final r = BindResult.fromJson({
        'status': 'already_bound',
        'linked_channels': [],
      });
      expect(r, isA<BindAlreadyBound>());
    });

    test('status=conflict → BindConflict with token + summaries', () {
      final r = BindResult.fromJson({
        'status': 'conflict',
        'conflict_token': 'ct_token_value',
        'other_user_summary': {
          'user_id_masked': 'aaaaaa...zzzz',
          'nickname': '张三',
          'avatar': 'https://x.com/a.png',
          'bound_channels': ['wechat', 'sms'],
          'created_at': '2026-01-01T00:00:00Z',
        },
        'current_user_summary': {
          'user_id_masked': 'bbbbbb...yyyy',
          'nickname': '当前',
          'bound_channels': ['apple'],
          'created_at': '2026-05-01T00:00:00Z',
        },
      });
      expect(r, isA<BindConflict>());
      final c = r as BindConflict;
      expect(c.conflictToken, 'ct_token_value');
      expect(c.other.nickname, '张三');
      expect(c.other.boundChannels, ['wechat', 'sms']);
      expect(c.current, isNotNull);
      expect(c.current!.nickname, '当前');
    });

    test('status=conflict with no current_user_summary still parses', () {
      final r = BindResult.fromJson({
        'status': 'conflict',
        'conflict_token': 'ct',
        'other_user_summary': {
          'user_id_masked': 'x',
          'bound_channels': [],
          'created_at': '2026-01-01T00:00:00Z',
        },
      });
      expect(r, isA<BindConflict>());
      expect((r as BindConflict).current, isNull);
    });

    test('unknown status → BindError', () {
      final r = BindResult.fromJson({'status': 'wtf'}, httpStatus: 500);
      expect(r, isA<BindError>());
      expect((r as BindError).message, contains('wtf'));
    });
  });

  // ==========================================================================
  // LinkedChannel
  // ==========================================================================
  group('LinkedChannel.fromJson', () {
    test('parses full record', () {
      final c = LinkedChannel.fromJson({
        'channel_id': 'wechat',
        'channel_name': '微信',
        'channel_user_id_masked': 'wx_o***',
        'nickname': '昵称',
        'scene_id': 'app_native',
        'bound_at': '2026-06-15T10:00:00Z',
      });
      expect(c.channelId, 'wechat');
      expect(c.channelName, '微信');
      expect(c.channelUserIdMasked, 'wx_o***');
      expect(c.nickname, '昵称');
      expect(c.sceneId, 'app_native');
    });

    test('handles missing optional fields', () {
      final c = LinkedChannel.fromJson({
        'channel_id': 'sms',
        'channel_name': 'SMS',
        'channel_user_id_masked': '139***1234',
        'bound_at': '2026-06-15T10:00:00Z',
      });
      expect(c.nickname, isNull);
      expect(c.sceneId, isNull);
    });
  });

  // ==========================================================================
  // AccountSummary
  // ==========================================================================
  group('AccountSummary.fromJson', () {
    test('parses bound_channels list correctly', () {
      final a = AccountSummary.fromJson({
        'user_id_masked': 'masked',
        'bound_channels': ['wechat', 'apple', 'sms'],
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(a.boundChannels, ['wechat', 'apple', 'sms']);
    });

    test('empty bound_channels', () {
      final a = AccountSummary.fromJson({
        'user_id_masked': 'masked',
        'bound_channels': [],
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(a.boundChannels, isEmpty);
    });

    test('missing bound_channels defaults to empty list', () {
      final a = AccountSummary.fromJson({
        'user_id_masked': 'masked',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(a.boundChannels, isEmpty);
    });
  });

  // ==========================================================================
  // AccountStateException
  // ==========================================================================
  group('AccountStateException', () {
    test('isMerged / isCancelled flags', () {
      final m = AccountStateException(
        errorCode: 'account_merged',
        mergedInto: 'tgt',
        message: 'merged',
      );
      expect(m.isMerged, isTrue);
      expect(m.isCancelled, isFalse);
      expect(m.mergedInto, 'tgt');

      final c = AccountStateException(
        errorCode: 'account_cancelled',
        message: 'cancelled',
      );
      expect(c.isMerged, isFalse);
      expect(c.isCancelled, isTrue);
      expect(c.mergedInto, isNull);
    });

    test('toString format', () {
      final e = AccountStateException(
        errorCode: 'account_merged',
        mergedInto: 'tgt',
        message: 'msg',
      );
      expect(e.toString(), contains('account_merged'));
      expect(e.toString(), contains('mergedInto=tgt'));
    });
  });

  // ==========================================================================
  // Enum wire format — 后端约定的字符串值
  // ==========================================================================
  group('enum wire formats', () {
    test('ResolveAction.wire matches backend contract', () {
      expect(ResolveAction.otherIntoMe.wire, 'other_into_me');
      expect(ResolveAction.meIntoOther.wire, 'me_into_other');
      expect(ResolveAction.abort.wire, 'abort');
    });

    test('MergeDirection.wire matches backend contract', () {
      expect(MergeDirection.otherIntoMe.wire, 'other_into_me');
      expect(MergeDirection.meIntoOther.wire, 'me_into_other');
    });
  });
}
