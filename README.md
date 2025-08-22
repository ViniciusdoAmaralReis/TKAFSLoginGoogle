# 🚀 TKAFSLoginGoogle

Componente Delphi/FireMonkey para autenticação OAuth2 com Google, incluindo servidor HTTP local para captura do código de autorização.

## 📋 Descrição

Componente especializado em gerenciar autenticação OAuth2 com Google em aplicações Delphi/FireMonkey, com suporte multiplataforma e interface web integrada para fluxo de autorização.

## ✨ Características

- ✅ Autenticação OAuth2 com Google
- ✅ Servidor HTTP local integrado (porta 8080)
- ✅ Interface web automática para fechamento
- ✅ Troca automática de código por token de acesso
- ✅ Obtenção de dados do usuário (perfil, email, foto)
- ✅ Suporte multiplataforma
- ✅ Timeout configurável (30 segundos padrão)
- ✅ Tratamento de erros robusto

## 🛠️ Configuração

### Endpoints OAuth2 Padrão

```
AuthorizationEndpoint: https://accounts.google.com/o/oauth2/auth
AccessTokenEndpoint: https://oauth2.googleapis.com/token
RedirectionEndpoint: http://localhost:8080
BaseURL: https://www.googleapis.com
```

### Escopos Padrão

```
Scope: openid email profile
```

## 📦 Como Usar

### Instanciação e Autenticação

```pascal
var
  LoginGoogle: TKAFSLoginGoogle;
  DadosUsuario: TArray<string>;
begin
  LoginGoogle := TKAFSLoginGoogle.Create;
  try
    DadosUsuario := LoginGoogle.Login('seu_client_id', 'seu_client_secret');
    // Dados retornados: [URL_imagem, Nome, Sobrenome, Email]
  finally
    LoginGoogle.Free;
  end;
end;
```

### Métodos Principais

| Método | Descrição |
|--------|-----------|
| `Login` | Inicia processo de autenticação |
| `RestCodigoParaJsonDados` | Converte código em dados do usuário |
| `TelaFechamento` | Gera HTML para interface de conclusão |
| `Resposta` | Manipula resposta do servidor HTTP |

## 🔧 Dependências

- `System.Classes`
- `System.JSON` 
- `System.SyncObjs`
- `System.SysUtils`
- `System.Threading`
- `FMX.Dialogs`
- `IdContext`, `IdCustomHTTPServer`, `IdHTTPServer`
- `REST.Authenticator.OAuth`, `REST.Client`, `REST.Types`
- `UntKAFSFuncoes` (para `AbrirNavegador`)

## ⚠️ Pré-requisitos Google Cloud

1. Criar projeto no [Google Cloud Console](https://console.cloud.google.com/)
2. Configurar tela de consentimento OAuth
3. Criar credenciais OAuth 2.0 (Tipo: Aplicativo Web)
4. Adicionar URI de redirecionamento: `http://localhost:8080`

## 🎯 Fluxo de Autenticação

1. Componente inicia servidor HTTP local
2. Abre navegador com URL de autorização Google
3. Usuário faz login e concede permissões
4. Google redireciona para localhost:8080 com código
5. Componente troca código por token de acesso
6. Obtém dados do usuário da API Google
7. Retorna informações do perfil

## ⚠️ Tratamento de Erros

- Timeout de 30 segundos para autorização
- Timeout de 30 segundos para requisição REST
- Exceções descriptivas em caso de falhas
- Liberação adequada de recursos em todos os cenários

---

**Nota:** Este componente requer a unit `UntKAFSFuncoes` para funcionamento completo, contendo a função `AbrirNavegador`.
