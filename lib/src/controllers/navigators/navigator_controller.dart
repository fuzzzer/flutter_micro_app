// ignore_for_file: non_constant_identifier_names
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_micro_app/flutter_micro_app.dart';
import 'package:flutter_micro_app/src/presentation/pages/page_transition/micro_page_transition.dart';
import 'package:flutter_micro_app/src/utils/enums/navigator_status.dart';

import '../../utils/platform/platform_stub.dart'
    if (dart.library.io) '../../utils/platform/mobile_platform.dart'
    if (dart.library.html) '../../utils/platform/web_platform.dart';
import 'navigator_event_controller.dart';

/// instance hidden
MicroAppNavigatorController? _navigatorInstance;

/// Global instance (can be accessed from any micro app)
MicroAppNavigatorController get NavigatorInstance {
  _navigatorInstance ??=
      MicroAppNavigatorController(MicroAppNavigatorEventController());
  return _navigatorInstance as MicroAppNavigatorController;
}

/// [MicroAppNavigatorController]
class MicroAppNavigatorController extends RouteObserver<PageRoute<dynamic>> {
  final Map<String, PageBuilder> _pageBuilders = {};
  final MicroAppNavigatorEventController eventController;

  MicroAppNavigatorController(this.eventController) {
    _navigatorInstance = this;
  }

  /// [addPageBuilders]
  void addPageBuilders(Map<String, PageBuilder> map) {
    _pageBuilders.addAll(map);
  }

  /// [hasRoute]
  bool hasRoute(String route) => _pageBuilders.containsKey(route);
  Map<String, PageBuilder> get pageBuilders => _pageBuilders;

  /// [navigatorKey]
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// [NavigatorState]
  NavigatorState get _nav => navigatorKey.currentState as NavigatorState;

  /// [getPageWidget]
  Widget getPageWidget(String route, BuildContext context,
          {Object? arguments, String? type, Widget? orElse}) =>
      getPageBuilder(route)?.builder.call(context, arguments) ??
      orElse ??
      const SizedBox.shrink();

  /// [pushNamedNative]
  Future<T?> pushNamedNative<T>(String routeName,
      {Object? arguments, String? type}) {
    eventController.logNavigationEvent(routeName,
        arguments: arguments,
        type: type ?? MicroAppNavigationType.pushNamedNative.name);
    return eventController.pushNamedNative(routeName,
        arguments: arguments, type: type);
  }

  /// [pushNamed]
  Future<T?> pushNamed<T extends Object?>(String routeName,
      {Object? arguments, String? type, BuildContext? context}) {
    eventController.logNavigationEvent(routeName,
        arguments: arguments,
        type: type ?? MicroAppNavigationType.pushNamed.name);
    if (context != null) {
      return Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } else {
      return _nav.pushNamed(routeName, arguments: arguments);
    }
  }

  /// [pushReplacementNamed]
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
      String routeName,
      {TO? result,
      Object? arguments,
      String? type,
      BuildContext? context}) {
    eventController.logNavigationEvent(routeName,
        arguments: arguments,
        type: type ?? MicroAppNavigationType.pushReplacementNamed.name);

    if (context != null) {
      return Navigator.of(context).pushReplacementNamed(routeName,
          arguments: arguments, result: result);
    } else {
      return _nav.pushReplacementNamed(routeName,
          arguments: arguments, result: result);
    }
  }

  /// [push]
  Future<T?> push<T extends Object?>(Route<T> route,
      {BuildContext? context, String? type}) {
    eventController.logNavigationEvent(route.settings.name,
        arguments: route.settings.arguments,
        type: type ?? MicroAppNavigationType.push.name);

    if (context != null) {
      return Navigator.of(context).push(route);
    } else {
      return _nav.push(route);
    }
  }

  /// [pop]
  void pop<T extends Object?>(
      [T? result, BuildContext? context, String? type]) {
    eventController.logNavigationEvent(null,
        type: type ?? MicroAppNavigationType.pop.name,
        arguments: result?.toString());

    if (context != null) {
      return Navigator.of(context).pop(result);
    } else {
      return _nav.pop(result);
    }
  }

  /// [popAndPushNamed]
  Future<T?> popAndPushNamed<T extends Object?, TO extends Object?>(
      String routeName,
      {TO? result,
      Object? arguments,
      String? type,
      BuildContext? context}) {
    eventController.logNavigationEvent(routeName,
        arguments: arguments,
        type: type ?? MicroAppNavigationType.popAndPushNamed.name);
    if (context != null) {
      return Navigator.of(context)
          .popAndPushNamed(routeName, arguments: arguments, result: result);
    } else {
      return _nav.popAndPushNamed(routeName,
          arguments: arguments, result: result);
    }
  }

  /// [pushNamedAndRemoveUntil]
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
      String newRouteName, RoutePredicate predicate,
      {Object? arguments, String? type, BuildContext? context}) {
    eventController.logNavigationEvent(newRouteName,
        arguments: arguments,
        type: type ?? MicroAppNavigationType.pushNamedAndRemoveUntil.name);

    if (context != null) {
      return Navigator.of(context).pushNamedAndRemoveUntil(
          newRouteName, predicate,
          arguments: arguments);
    } else {
      return _nav.pushNamedAndRemoveUntil(newRouteName, predicate,
          arguments: arguments);
    }
  }

  /// [popUntil]
  void popUntil(RoutePredicate predicate,
      {String? type, BuildContext? context}) {
    eventController.logNavigationEvent(null,
        type: type ?? MicroAppNavigationType.popUntil.name);

    if (context != null) {
      return Navigator.of(context).popUntil(predicate);
    } else {
      return _nav.popUntil(predicate);
    }
  }

  /// [getPageRoute]
  PageRoute? getPageRoute(RouteSettings settings,
      {MicroAppBaseRoute? baseRoute, bool? routeNativeOnError}) {
    final routeName = settings.name;
    final routeArguments = settings.arguments;
    final pageBuilder = getPageBuilder(routeName, baseRoute: baseRoute);

    if (pageBuilder == null) {
      if (routeName != null && (routeNativeOnError ?? false)) {
        pushNamedNative(routeName, arguments: routeArguments);
      }
      return null;
    }

    final transitionType = pageBuilder.transitionType ??
        MicroAppPreferences.config.pageTransitionType;

    if (transitionType != MicroPageTransitionType.platform) {
      return MicroPageTransition(
          pageBuilder: pageBuilder.builder, type: transitionType);
    } else {
      if (isIOS) {
        return CupertinoPageRoute(
          builder: (context) => pageBuilder.builder(context, routeArguments),
        );
      } else {
        return MaterialPageRoute(
          builder: (context) => pageBuilder.builder(context, routeArguments),
        );
      }
    }
  }

  PageBuilder? getPageBuilder(String? name, {MicroAppBaseRoute? baseRoute}) {
    PageBuilder? pageBuilder;
    if (baseRoute == null || baseRoute.toString().isEmpty) {
      pageBuilder = _pageBuilders[name];
    } else {
      final buildersForBaseRoute = filterPageBuilderForBaseRoute(baseRoute);
      pageBuilder = buildersForBaseRoute[name];
    }
    return pageBuilder;
  }

  Map<String, PageBuilder> filterPageBuilderForBaseRoute(
      MicroAppBaseRoute baseRoute) {
    var filteredMap = Map<String, PageBuilder>.from(_pageBuilders);
    filteredMap
        .removeWhere((key, value) => !key.startsWith(baseRoute.toString()));
    return filteredMap;
  }

  /// [didPush]
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    eventController.logNavigationEvent(route.settings.name,
        type: MicroAppNavigationType.didPush.name);
  }

  /// [didReplace]
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    eventController.logNavigationEvent(newRoute?.settings.name,
        type: MicroAppNavigationType.didReplace.name);
  }

  /// [didPop]
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    eventController.logNavigationEvent(previousRoute?.settings.name,
        type: MicroAppNavigationType.didPop.name);
  }
}
