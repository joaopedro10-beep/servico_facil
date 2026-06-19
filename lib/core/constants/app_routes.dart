class AppRoutes {
  AppRoutes._();

  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const registerClient = '/register-client';
  static const registerWorker = '/register-worker';
  static const documentUpload = '/document-upload';
  static const verifyEmail = '/verify-email';
  static const pendingVerification = '/pending-verification';

  // Client
  static const clientHome = '/client/home';
  static const workerProfile = '/client/worker-profile';
  static const myOrders = '/client/my-orders';
  static const orderDetail = '/order-detail';
  static const rateService = '/client/rate-service';
  static const clientProfile = '/client/profile';

  // Worker
  static const workerHome = '/worker/home';
  static const workerOrders = '/worker/orders';
  static const workerEarnings = '/worker/earnings';
  static const workerReviews = '/worker/reviews';
  static const editWorkerProfile = '/worker/edit-profile';

  // Shared
  static const chat = '/chat';
  static const chatsList = '/chats';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const report = '/report';
  static const safetyTips = '/safety-tips';
  static const block = '/block';
  static const reviews = '/reviews';

}
