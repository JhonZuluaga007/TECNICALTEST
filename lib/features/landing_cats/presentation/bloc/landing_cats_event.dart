// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'landing_cats_bloc.dart';

abstract class LandingCatsEvent {}

class AllCatsEvent extends LandingCatsEvent {}

class AddNameAlreadySearchedEvent extends LandingCatsEvent {
  final List<String> listNamesAlreadySearched;
  AddNameAlreadySearchedEvent({
    required this.listNamesAlreadySearched,
  });
}
