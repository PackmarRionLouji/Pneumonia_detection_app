part of 'sign_up_bloc.dart';

abstract class SignUpEvent {}

class RetrieveLostDataEvent extends SignUpEvent {}

class ChooseImageFromGalleryEvent extends SignUpEvent {
  ChooseImageFromGalleryEvent();
}

class CaptureImageByCameraEvent extends SignUpEvent {
  CaptureImageByCameraEvent();
}

class ValidateFieldsEvent extends SignUpEvent {
  GlobalKey<FormState> key;

  ValidateFieldsEvent(this.key);
}