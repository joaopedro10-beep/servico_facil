class AppStrings {
  AppStrings._();

  static const appName = 'ServiçoFácil';

  // Auth
  static const welcome = 'Bem-vindo ao ServiçoFácil';
  static const welcomeSub = 'Encontre profissionais de confiança perto de você';
  static const iAmClient = 'Sou Cliente';
  static const iAmWorker = 'Sou Prestador';
  static const login = 'Entrar';
  static const register = 'Criar conta';
  static const email = 'E-mail';
  static const password = 'Senha';
  static const confirmPassword = 'Confirmar senha';
  static const forgotPassword = 'Esqueci minha senha';
  static const noAccount = 'Não tem conta? ';
  static const hasAccount = 'Já tem conta? ';
  static const continueWithGoogle = 'Continuar com Google';
  static const verifyEmailTitle = 'Verifique seu e-mail';
  static const verifyEmailSub = 'Enviamos um link de confirmação para o seu e-mail. Por favor, verifique sua caixa de entrada.';
  static const resendEmail = 'Reenviar e-mail';
  static const pendingTitle = 'Cadastro em análise';
  static const pendingSub = 'Seus documentos estão sendo verificados. Isso pode levar até 24 horas.';

  // Segurança
  static const safetyWarning =
      'Nunca realize pagamentos fora do app. Em caso de problema, use o botão Denunciar.';

  // Erros
  static const genericError = 'Ocorreu um erro. Tente novamente.';
  static const networkError = 'Sem conexão com a internet.';
  static const authError = 'E-mail ou senha incorretos.';
  static const weakPassword = 'A senha deve ter pelo menos 6 caracteres.';
  static const emailInUse = 'Este e-mail já está cadastrado.';

  // Categorias de serviço
  static const List<String> serviceCategories = [
    'Encanador',
    'Eletricista',
    'Diarista',
    'Pintor',
    'Jardineiro',
    'Montador',
    'Pedreiro',
    'TI / Suporte',
  ];

}
