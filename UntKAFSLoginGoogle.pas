unit UntKAFSLoginGoogle;

interface

uses
  System.Classes, System.JSON, System.SyncObjs, System.SysUtils,
  System.Threading,
  FMX.Dialogs,
  IdContext, IdCustomHTTPServer, IdHTTPServer,
  REST.Authenticator.OAuth, REST.Client, REST.Types;

type
  TKAFSLoginGoogle = class
  private
    OnCodigo: TEvent;
    OnDados: TEvent;
  public
    IdHTTPServer: TIdHTTPServer;
    OAuth2Authenticator: TOAuth2Authenticator;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;

    Codigo: String;

    constructor Create; reintroduce;
    function Login(const _id, _secret: String): TArray<string>;
    procedure Resposta(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    function TelaFechamento: String;
    function RestCodigoParaJsonDados(const _codigo: String): String;
    destructor Destroy; override;
  end;

implementation

uses
  UntKAFSFuncoes;

constructor TKAFSLoginGoogle.Create;
begin
  inherited Create;

  // Cria o evento para sincronização
  OnCodigo := TEvent.Create(nil, True, False, '');
  OnDados := TEvent.Create(nil, True, False, '');

  // Cria o servidor local
  IdHTTPServer := TIdHTTPServer.Create(nil);
  IdHTTPServer.DefaultPort := 8080;

  // Cria o autenticador
  OAuth2Authenticator := TOAuth2Authenticator.Create(nil);
  with OAuth2Authenticator do
  begin
    AccessTokenEndpoint := 'https://oauth2.googleapis.com/token';
    AuthorizationEndpoint := 'https://accounts.google.com/o/oauth2/auth';
    //Precisa de ser habilitado nas cofigs da Google Gloud. Tipo: sistema Web
    OAuth2Authenticator.RedirectionEndpoint := 'http://localhost:' + IntToStr(IdHTTPServer.DefaultPort);
    ResponseType := TOAuth2ResponseType.rtCODE;
    Scope := 'openid email profile';
  end;

  // Cria componentes REST
  RESTClient := TRESTClient.Create(nil);
  with RESTClient do
  begin
    Authenticator := OAuth2Authenticator;
    BaseURL := 'https://www.googleapis.com';
  end;

  RESTResponse := TRESTResponse.Create(nil);

  RESTRequest := TRESTRequest.Create(nil);
  with RESTRequest do
  begin
    Client := RESTClient;
    Method := TRESTRequestMethod.rmGET;
    Resource := 'oauth2/v1/userinfo';
    Response := RESTResponse;
  end;
end;

function TKAFSLoginGoogle.Login(const _id, _secret: String): TArray<string>;
begin
  try
    // Reseta código
    Codigo := '';

    // Reseta eventos
    OnCodigo.ResetEvent;
    OnDados.ResetEvent;

    // Ativa servidor local
    with IdHTTPServer do
    begin
      Active := False;
      OnCommandGet := Resposta;
      Active := True;
    end;

    // Configura o autenticador
    with OAuth2Authenticator do
    begin
      OAuth2Authenticator.ClientID := _id;
      OAuth2Authenticator.ClientSecret := _secret;

      // Aciona o navegador usando o servidor local
      AbrirNavegador(AuthorizationRequestURI);
    end;

    // Espera pelo código de forma não bloqueante
    case OnCodigo.WaitFor(30000) of
      wrSignaled:
      begin
        // Cria um evento adicional para esperar a resposta assíncrona
        var _jsondados := '';
        var _erro := False;

        try
          // Executa a requisição REST de forma assíncrona
          TTask.Run(procedure
          begin
            try
              _jsondados := RestCodigoParaJsonDados(Codigo);
              OnDados.SetEvent;
            except
              on E: Exception do
              begin
                _erro := True;
                _jsondados := E.Message;
                OnDados.SetEvent;
              end;
            end;
          end);

          // Espera pela resposta da requisição REST (com timeout)
          if OnDados.WaitFor(30000) = wrSignaled then
          begin
            if _erro then
              raise Exception.Create('Erro na requisição REST: ' + _jsondados);

            // Converte json para objeto e preenche respostas
            var _jsonobj := TJSONObject.ParseJSONValue(_jsondados) as TJSONObject;
            try
              if _jsonobj <> nil then
                with _jsonobj do
                  Result := [GetValue('picture').Value, //Link da imagem
                             GetValue('given_name').Value, //Nome
                             GetValue('family_name').Value, //Sobrenome
                             GetValue('email').Value]; //Email
            finally
              FreeAndNil(_jsonobj);
            end;
          end
          else
            raise Exception.Create('Tempo limite excedido na requisição REST');
        finally
          FreeAndNil(OnDados);
        end;
      end;
      wrTimeout:
        raise Exception.Create('Tempo limite excedido ao aguardar autorização');
      else
        raise Exception.Create('Erro ao aguardar autorização');
    end;
  finally
    IdHTTPServer.Active := False;

    FreeAndNil(RESTRequest);
    FreeAndNil(RESTResponse);
    FreeAndNil(RESTClient);
    FreeAndNil(OAuth2Authenticator);
    FreeAndNil(IdHTTPServer);
    FreeAndNil(OnCodigo);
  end;
end;

procedure TKAFSLoginGoogle.Resposta(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  // Preenche resposta
  Codigo := ARequestInfo.Params.Values['code'];

  // Sinaliza que o código foi recebido
  TThread.Synchronize(nil, procedure begin OnCodigo.SetEvent; end);

  AResponseInfo.ContentText := TelaFechamento;
  AResponseInfo.ContentType := 'text/html; charset=utf-8';
end;
function TKAFSLoginGoogle.TelaFechamento: String;
begin
  Result :=
'<!DOCTYPE html>' +
'<html>' +
'<head>' +
'  <meta charset="UTF-8">' +
'  <meta name="viewport" content="width=device-width, initial-scale=1.0">' +
'  <title>Login Concluído</title>' +
'  <style>' +
'    body { font-family: Arial, sans-serif; text-align: center; padding: 20px; }' +
'    .message { margin: 20px 0; }' +
'  </style>' +
'</head>' +
'<body>' +
'  <h2>Login Concluído</h2>' +
'  <div class="message">Você pode retornar ao aplicativo</div>' +
'  <script>' +
'    // Tenta fechar a janela (funciona em alguns navegadores)' +
'    try { window.close(); } catch (e) {}' +
'    ' +
'    // Redireciona após um tempo se não fechar' +
'    setTimeout(function() {' +
'      window.location.href = "about:blank";' +
'    }, 1000);' +
'  </script>' +
'</body>' +
'</html>';
end;

function TKAFSLoginGoogle.RestCodigoParaJsonDados(const _codigo: String): String;
begin
  // Configura o OAuth2Authenticator para trocar o código pelo token
  with OAuth2Authenticator do
  begin
    AuthCode := _codigo;
    ChangeAuthCodeToAccesToken;

    // Verifica se o token foi recebido
    if AccessToken <> '' then
    begin
      RESTRequest.Execute;

      Result := RESTResponse.Content;
    end;
  end;
end;

destructor TKAFSLoginGoogle.Destroy;
begin
  // Libera os componentes na ordem inversa da criação
  if Assigned(RESTRequest) then
    FreeAndNil(RESTRequest);

  if Assigned(RESTResponse) then
    FreeAndNil(RESTResponse);

  if Assigned(RESTClient) then
    FreeAndNil(RESTClient);

  if Assigned(OAuth2Authenticator) then
    FreeAndNil(OAuth2Authenticator);

  if Assigned(IdHTTPServer) then
  begin
    IdHTTPServer.Active := False;
    FreeAndNil(IdHTTPServer);
  end;

  if Assigned(OnDados) then
    FreeAndNil(OnDados);

  if Assigned(OnCodigo) then
    FreeAndNil(OnCodigo);

  inherited Destroy;
end;

end.

