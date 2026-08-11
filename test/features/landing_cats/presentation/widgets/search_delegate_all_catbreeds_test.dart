import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tecnical_test_pragma/core/common_widgets/card/card_cat_widget.dart';
import 'package:tecnical_test_pragma/features/landing_cats/domain/entities/catbreed_entity.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/bloc/landing_cats_bloc.dart';
import 'package:tecnical_test_pragma/features/landing_cats/presentation/widgets/search_delegate_all_catbreeds.dart';

import '../../../../helpers/builders.dart';
import '../../../../helpers/ignore_overflow_errors.dart';
import '../../../../helpers/mocks.dart';

/// This uses `MockLandingCatsBloc` (`MockBloc` + `whenListen`) rather than the
/// real bloc: the tests need to pin exact states — including a two-state sequence
/// to prove the history updates live — and to verify the dispatched event. Wiring
/// a real bloc plus its use case would be indirection for no gain.
void main() {
  late MockLandingCatsBloc bloc;

  final breeds = <CatBreedEntity>[
    catBreedModel(id: 'siam', name: 'Siamese'),
    catBreedModel(id: 'abob', name: 'American Bobtail'),
    catBreedModel(id: 'aege', name: 'Aegean'),
  ];

  /// The delegate only reads `searchHistory`, which lives on the sealed base, so
  /// any variant would do. `CatsLoaded` is used because it is the state the app is
  /// actually in when the search icon is tapped.
  LandingCatsState loaded({List<String> history = const []}) =>
      CatsLoaded(breeds: breeds, searchHistory: history);

  setUp(() {
    bloc = MockLandingCatsBloc();
    registerFallbackValue(const AllCatsEvent());
  });

  void seed(LandingCatsState state, {List<LandingCatsState> then = const []}) {
    whenListen(
      bloc,
      Stream<LandingCatsState>.fromIterable(then),
      initialState: state,
    );
  }

  Future<void> openSearch(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<LandingCatsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => showSearch(
                  context: context,
                  delegate: SearchDelegateAllCatbreeds(
                    listCatBreedEntity: breeds,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
  }

  group('SearchDelegateAllCatbreeds history', () {
    testWidgets('with an empty query it renders the history FROM THE BLOC', (
      tester,
    ) async {
      // The history used to arrive via the constructor. It now comes from state.
      seed(loaded(history: const ['siamese', 'aegean']));

      await openSearch(tester);

      expect(find.text('siamese'), findsOneWidget);
      expect(find.text('aegean'), findsOneWidget);
      expect(find.byType(CardCatWidget), findsNothing);
    });

    testWidgets('tapping a history entry applies that query', (tester) async {
      ignoreOverflowErrors();
      seed(loaded(history: const ['siamese']));

      await openSearch(tester);
      await tester.tap(find.text('siamese'));
      await tester.pumpAndSettle();

      expect(find.text('Siamese'), findsOneWidget);
      expect(find.byType(CardCatWidget), findsOneWidget);
    });

    testWidgets('the history updates live', (tester) async {
      // This does NOT work today: the list arrives immutable via the
      // constructor, so searching and then clearing the query does not show the
      // term just searched until the search is reopened.
      seed(
        loaded(history: const ['siamese']),
        then: [
          loaded(history: const ['siamese', 'aegean']),
        ],
      );

      await openSearch(tester);

      expect(find.text('siamese'), findsOneWidget);
      expect(find.text('aegean'), findsOneWidget);
    });
  });

  group('SearchDelegateAllCatbreeds filtering', () {
    testWidgets('filters by name, case-insensitively', (tester) async {
      ignoreOverflowErrors();
      seed(loaded());

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'aege');
      await tester.pumpAndSettle();

      expect(find.text('Aegean'), findsOneWidget);
      expect(find.text('Siamese'), findsNothing);
      expect(find.byType(CardCatWidget), findsOneWidget);
    });

    testWidgets('a query with no match renders no cards', (tester) async {
      seed(loaded());

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.byType(CardCatWidget), findsNothing);
    });
  });

  group('SearchDelegateAllCatbreeds event dispatch', () {
    testWidgets('submitting the query dispatches the event exactly once', (
      tester,
    ) async {
      ignoreOverflowErrors();
      seed(loaded());

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'aege');
      await tester.pumpAndSettle();

      // Nothing should have been dispatched before submitting: the event used to
      // come out of `buildResults`, which is a build method.
      verifyNever(
        () => bloc.add(const AddNameAlreadySearchedEvent(name: 'aege')),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(const AddNameAlreadySearchedEvent(name: 'aege')),
      ).called(1);
    });

    testWidgets('trims the query before dispatching', (tester) async {
      ignoreOverflowErrors();
      seed(loaded());

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), '  aege  ');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(const AddNameAlreadySearchedEvent(name: 'aege')),
      ).called(1);
    });

    testWidgets('a whitespace-only query dispatches nothing', (tester) async {
      seed(loaded());

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('does NOT mutate the history list held by the state', (
      tester,
    ) async {
      // The highest-value test in this file. Fails before Phase 2: the delegate
      // did `filterNamesSearched.add(query)` on the SAME list instance living in
      // `state.searchHistory`.
      ignoreOverflowErrors();
      final stateHistory = ['siamese'];
      seed(loaded(history: stateHistory));

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'aege');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(stateHistory, ['siamese']);
    });
  });

  group('SearchDelegateAllCatbreeds scroll', () {
    testWidgets('each vertical list owns its own scroll position', (
      tester,
    ) async {
      // `_SearchPageState` uses a 300 ms `AnimatedSwitcher`, so both subtrees are
      // mounted during the suggestions->results transition. They used to share ONE
      // `ScrollController` that was also never released (`SearchDelegate` has no
      // dispose hook): one leak per tap on the search icon. `primary: false` with
      // no controller gives each list its own position and stops them from going
      // back to sharing the `ModalRoute`'s.
      ignoreOverflowErrors();
      seed(loaded());

      await openSearch(tester);
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 150));

      final verticalLists = tester
          .widgetList<ListView>(find.byType(ListView))
          .where((list) => list.scrollDirection == Axis.vertical);

      expect(verticalLists, isNotEmpty);
      for (final list in verticalLists) {
        expect(list.controller, isNull);
        expect(list.primary, isFalse);
      }

      await tester.pumpAndSettle();
    });
  });
}
