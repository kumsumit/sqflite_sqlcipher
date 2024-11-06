// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:matcher/matcher.dart';

/// An exception thrown when a test assertion fails.
class TestFailure extends Error {
  /// An exception thrown when a test assertion fails.
  TestFailure(this.message);

  /// Exception message
  final String message;

  @override
  String toString() => message;
}

/// The type used for functions that can be used to build up error reports
/// upon failures in [expect].
@Deprecated('Will be removed in 0.13.0.')
typedef ErrorFormatter = String Function(dynamic actual, Matcher matcher,
    String? reason, Map matchState, bool verbose);

/// Assert that [actual] matches [matcher].
///
/// This is the main assertion function. [reason] is optional and is typically
/// not supplied, as a reason is generated from [matcher]; if [reason]
/// is included it is appended to the reason generated by the matcher.
///
/// [matcher] can be a value in which case it will be wrapped in an
/// [equals] matcher.
///
/// If the assertion fails a [TestFailure] is thrown.
///
/// If [skip] is a String or `true`, the assertion is skipped. The arguments are
/// still evaluated, but [actual] is not verified to match [matcher]. If
/// [actual] is a [Future], the test won't complete until the future emits a
/// value.
///
/// If [skip] is a string, it should explain why the assertion is skipped; this
/// reason will be printed when running the test.
///
/// Certain matchers, like [completion] and [throwsA], either match or fail
/// asynchronously. When you use [expect] with these matchers, it ensures that
/// the test doesn't complete until the matcher has either matched or failed. If
/// you want to wait for the matcher to complete before continuing the test, you
/// can call [expectLater] instead and `await` the result.
void expect(
  actual,
  matcher, {
  String? reason,
  skip,
}) {
  _expect(actual, matcher, reason: reason, skip: skip);
}

/// Just like [expect], but returns a [Future] that completes when the matcher
/// has finished matching.
///
/// For the [completes] and [completion] matchers, as well as [throwsA] and
/// related matchers when they're matched against a [Future], the returned
/// future completes when the matched future completes. For the [prints]
/// matcher, it completes when the future returned by the callback completes.
/// Otherwise, it completes immediately.
///
/// If the matcher fails asynchronously, that failure is piped to the returned
/// future where it can be handled by user code.
Future expectLater(actual, matcher, {String? reason, skip}) =>
    _expect(actual, matcher, reason: reason, skip: skip);

String _formatFailure(Matcher expected, actual, String which,
    {String? reason}) {
  var buffer = StringBuffer();
  buffer.writeln(indent(prettyPrint(expected), first: 'Expected: '));
  buffer.writeln(indent(prettyPrint(actual), first: '  Actual: '));
  if (which.isNotEmpty) buffer.writeln(indent(which, first: '   Which: '));
  if (reason != null) buffer.writeln(reason);
  return buffer.toString();
}

/// The implementation of [expect] and [expectLater].
Future<void> _expect(actual, matcher,
    {String? reason,
    skip,
    bool verbose = false,
    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
    ErrorFormatter? formatter}) async {
  formatter ??= (actual, matcher, reason, matchState, verbose) {
    var mismatchDescription = StringDescription();
    matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);

    // ignore: deprecated_member_use
    return _formatFailure(matcher, actual, mismatchDescription.toString(),
        reason: reason);
  };

  if (skip != null && skip is! bool && skip is! String) {
    throw ArgumentError.value(skip, 'skip', 'must be a bool or a String');
  }

  matcher = wrapMatcher(matcher);

  var matchState = {};
  try {
    if ((matcher as Matcher).matches(actual, matchState)) {
      return Future.sync(() {});
    }
  } catch (e, trace) {
    reason ??= '$e at $trace';
  }

  final errorStr =
      formatter(actual, matcher as Matcher, reason, matchState, verbose);
  print('Error str: $errorStr');
  fail(errorStr);
}

/// Convenience method for throwing a new [TestFailure] with the provided
/// [message].
Never fail([String? message]) => throw TestFailure(message ?? 'should fail');

/// index text helper.
String indent(String text, {String? first}) {
  if (first != null) {
    return '$first $text';
  }
  return '$text';
}

/// index text helper.
String prettyPrint(dynamic text, {String? first}) {
  if (first != null) {
    return '$first $text';
  }
  return '$text';
}

/// The default error formatter.
@Deprecated('Will be removed in 0.13.0.')
String formatFailure(Matcher expected, actual, String which, {String? reason}) {
  var buffer = StringBuffer();
  buffer.writeln(indent(prettyPrint(expected), first: 'Expected: '));
  buffer.writeln(indent(prettyPrint(actual), first: '  Actual: '));
  if (which.isNotEmpty) buffer.writeln(indent(which, first: '   Which: '));
  if (reason != null) buffer.writeln(reason);
  return buffer.toString();
}
