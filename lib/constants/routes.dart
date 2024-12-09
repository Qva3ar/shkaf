const createNoteRoute = '/notes/create-note/';
const updateNoteRoute = '/notes/update-note/';
const login = '/login/';
const noteDetailsRoute = '/note-details/';
const allNotes = '/all-notes/';
const userDetails = '/user-details/';
const userNotes = '/user-notes/';
const register = '/register/';
const forgotPassword = '/forgot-password/';
const emailVerification = '/email-verification/';
const addScreen = '/add-screen/';
const categoryScreen = '/categories-Screen';

class ListViewArguments {
  final int categoryId;
  final int mainCategoryId;

  ListViewArguments(this.categoryId, this.mainCategoryId);
}
