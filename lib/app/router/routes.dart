/// Every route path of the app. Screens navigate through these constants
/// (and the helpers below) instead of string literals.
class Routes {
  const Routes._();

  // Startup and blocking states
  static const splash = '/splash';
  static const maintenance = '/maintenance';
  static const update = '/update';
  static const offline = '/offline';

  // Signed out
  static const welcome = '/welcome';
  static const login = '/login';
  static const registerEmail = '/register/email';
  static const registerOtp = '/register/otp';
  static const registerPassword = '/register/password';
  static const registerCharacter = '/register/character';
  static const forgotOtp = '/forgot/otp';
  static const forgotPassword = '/forgot/password';

  // Shell tabs
  static const home = '/home';
  static const categories = '/categories';
  static const wallet = '/wallet';
  static const profile = '/profile';

  // Pushed over the shell
  static const giveaways = '/giveaways';
  static const myGiveaways = '/my-giveaways';
  static const ticket = '/ticket';
  static const celebration = '/celebration';
  static const orders = '/orders';
  static const notifications = '/notifications';
  static const transactions = '/transactions';
  static const earn = '/earn';
  static const refer = '/refer';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const changePassword = '/settings/password';
  static const sessions = '/settings/sessions';
  static const notificationSettings = '/settings/notifications';
  static const deleteAccount = '/settings/delete';

  static String category(String id) => '/category/$id';
  static String giveaway(String id) => '/giveaway/$id';
  static String order(String id) => '/order/$id';
  static String notification(String id) => '/notification/$id';
  static String info(InfoKind kind) => '/info/${kind.name}';

  static const signedOutPaths = {
    welcome,
    login,
    registerEmail,
    registerOtp,
    registerPassword,
    registerCharacter,
    forgotOtp,
    forgotPassword,
  };
}

enum InfoKind { about, privacy, terms }
