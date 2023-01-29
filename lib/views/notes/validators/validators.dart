String? titleValidator(value) {
  if (value == null || value.isEmpty) {
    return 'Введите заголовок';
  }
  if (value.toString().length < 10) {
    return 'Введите больше 10 символов';
  }
  return null;
}

String? descValidator(value) {
  if (value == null || value.isEmpty) {
    return 'Введите Описание';
  }
  if (value.toString().length < 10) {
    return 'Введите больше 10 символов';
  }
  return null;
}

String? catValidator(value) {
  if (value == null || value.isEmpty) {
    return 'Выберите категорию';
  }

  return null;
}

String? cityValidator(value) {
  if (value == null || value.isEmpty) {
    return 'Выберите город';
  }

  return null;
}
