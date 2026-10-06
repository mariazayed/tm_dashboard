import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm_dashboard/main.dart';
import 'package:tm_dashboard/configs/routes.dart';
import 'package:tm_dashboard/services/api_client.dart';

http.Response fixture(http.Request request) {
  final path = request.url.path;
  final week = {'weekStart':'2026-09-21','weekEnd':'2026-09-27','capacityHours':40};
  final month = {'year':2026,'month':9};
  const label = 'A long example name that must wrap on a small mobile screen';
  final asset = {'id':1,'name':label,'symbol':'EURUSD','contractSize':100000};
  final reason = {'id':1,'name':label};
  final records = <String, List<Object>>{
    'asset':[asset],
    'strategies':[{'id':1,'name':label,'link':'https://example.com','tags':[]}],
    'goal':[{'id':1,'title':label,'category':1,'status':1,'startDate':'2026-09-01','endDate':'2026-12-31','progressPct':42}],
    'decision':[{'id':1,'decisionNumber':1,'decisionDate':'2026-09-21','title':label,'category':1,'status':1,'description':label}],
    'questionCategories':[reason],
    'questionAnswers':[{'id':1,'question':label,'answer':label,'category':reason}],
    'expenseReason':[reason],
    'expense':[{'id':1,'date':'2026-09-21','amount':12345.67,'expenseReason':reason}],
    'reminderNotes':[{'id':1,'text':label}],
    'strictRules':[{'id':1,'text':label}],
    'capital':[{'dateTime':'2026-09-21T10:00:00','amount':12345.67,'reason':1}],
    'trade':[{'id':1,'entryDateTime':'2026-09-21T10:00:00','exitDateTime':'2026-09-21T11:00:00','asset':asset,'direction':1,'entryPrice':1.1,'exitPrice':1.2,'lotSize':0.1,'pips':10,'pnl':123.45}],
  };
  final resource = request.url.pathSegments.where((s) => s != 'search').last;
  Object data = records[resource] ?? [];
  if (path.endsWith('/search')) data = {'status':'success','data':data,'last':true};
  if (path.endsWith('/staticData') || path.endsWith('/settings')) data = {};
  if (path.endsWith('/week')) data = week;
  if (path.endsWith('/month')) data = month;
  if (path.endsWith('/overview')) data = {'currentWeek':week,'currentMonth':month};
  return http.Response(jsonEncode(data),200);
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final path in ['/', '/calendar', '/trading-hours', '/risk-management', '/trades', '/goals', '/planner', '/capital', '/decisions', '/questions-answers', '/assets', '/reminder-notes', '/strict-rules', '/strategies', '/expenses', '/expense-reasons']) {
      testWidgets('$path fits $width wide', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await http.runWithClient(() async {
          ApiClient.shared.clear();
          routes.go(path);
          await tester.pumpWidget(const MyApp());
          await tester.pumpAndSettle();
          final scrolls = find.byType(Scrollable);
          if (scrolls.evaluate().isNotEmpty) {
            await tester.drag(scrolls.first, const Offset(0, -450));
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }, () => MockClient((r) async => fixture(r)));
      });
    }
  }
}
