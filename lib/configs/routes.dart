// import 'package:go_router/go_router.dart';
// import 'package:trader_beast_dashboard/constants/route_names.dart';
// import 'package:trader_beast_dashboard/screens/asset.dart';
// import 'package:trader_beast_dashboard/screens/assets_list.dart';
// import 'package:trader_beast_dashboard/screens/sector.dart';
// import 'package:trader_beast_dashboard/screens/sectors_list.dart';
// import 'package:trader_beast_dashboard/screens/stop_loss_strategies_list.dart';
// import 'package:trader_beast_dashboard/screens/stop_loss_strategy.dart';
// import 'package:trader_beast_dashboard/screens/strategies_list.dart';
// import 'package:trader_beast_dashboard/screens/strategy.dart';
// import 'package:trader_beast_dashboard/screens/take_profit_strategies_list.dart';
// import 'package:trader_beast_dashboard/screens/take_profit_strategy.dart';
// import 'package:trader_beast_dashboard/widgets/menu_bar.dart';
//
// import '../screens/create_trade.dart';
// import '../screens/home.dart';
//
// final GoRouter routes = GoRouter(
//   routes: [
//     ShellRoute(
//       builder: (context, state, child) {
//         return MyMenuBar(child: child);
//       },
//       routes: [
//         GoRoute(
//           name: RouteNames.home,
//           path: '/',
//           builder: (context, state) => const HomeWidget(),
//           routes: [
//             // Assets routes
//             GoRoute(
//               name: RouteNames.assetList,
//               path: 'asset-list',
//               builder: (context, state) => AssetsListWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.assetCreate,
//               path: 'create-asset',
//               builder: (context, state) => const AssetWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.assetUpdate,
//               path: 'update-asset/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return AssetWidget(id: id);
//               },
//             ),
//             GoRoute(
//               name: RouteNames.assetView,
//               path: 'view-asset/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return AssetWidget(id: id, readOnly: true);
//               },
//             ),
//
//             // Sectors routes
//             GoRoute(
//               name: RouteNames.sectorList,
//               path: 'sector-list',
//               builder: (context, state) => SectorsListWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.sectorCreate,
//               path: 'create-sector',
//               builder: (context, state) => const SectorWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.sectorUpdate,
//               path: 'update-sector/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return SectorWidget(id: id);
//               },
//             ),
//             GoRoute(
//               name: RouteNames.sectorView,
//               path: 'view-sector/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return SectorWidget(id: id, readOnly: true);
//               },
//             ),
//
//             // Strategies routes
//             GoRoute(
//               name: RouteNames.strategyList,
//               path: 'strategy-list',
//               builder: (context, state) => StrategiesListWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.strategyCreate,
//               path: 'create-strategy',
//               builder: (context, state) => const StrategyWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.strategyUpdate,
//               path: 'update-strategy/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return StrategyWidget(id: id);
//               },
//             ),
//             GoRoute(
//               name: RouteNames.strategyView,
//               path: 'view-strategy/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return StrategyWidget(id: id, readOnly: true);
//               },
//             ),
//
//             // Stop Loss Strategies routes
//             GoRoute(
//               name: RouteNames.stopLossStrategyList,
//               path: 'stop-loss-strategy-list',
//               builder: (context, state) => StopLossStrategiesListWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.stopLossStrategyCreate,
//               path: 'create-sl-strategy',
//               builder: (context, state) => const StopLossStrategyWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.stopLossStrategyUpdate,
//               path: 'update-sl-strategy/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return StopLossStrategyWidget(id: id);
//               },
//             ),
//             GoRoute(
//               name: RouteNames.stopLossStrategyView,
//               path: 'view-sl-strategy/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return StopLossStrategyWidget(id: id, readOnly: true);
//               },
//             ),
//
//             // Take Profit Strategies routes
//             GoRoute(
//               name: RouteNames.takeProfitStrategyList,
//               path: 'take-profit-strategy-list',
//               builder: (context, state) => TakeProfitStrategiesListWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.takeProfitStrategyCreate,
//               path: 'create-tp-strategy',
//               builder: (context, state) => const TakeProfitStrategyWidget(),
//             ),
//             GoRoute(
//               name: RouteNames.takeProfitStrategyUpdate,
//               path: 'update-tp-strategy/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return TakeProfitStrategyWidget(id: id);
//               },
//             ),
//             GoRoute(
//               name: RouteNames.takeProfitStrategyView,
//               path: 'view-tp-strategy/:id',
//               builder: (context, state) {
//                 final id = int.parse(state.pathParameters['id']!);
//                 return TakeProfitStrategyWidget(id: id, readOnly: true);
//               },
//             ),
//
//             // Trade routes
//             GoRoute(
//               name: RouteNames.tradeCreate,
//               path: 'create-trade',
//               builder: (context, state) => CreateTrade(),
//             ),
//           ],
//         ),
//       ],
//     ),
//   ],
// );
