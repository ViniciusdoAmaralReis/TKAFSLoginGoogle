unit uKAFSLoginGoogle;

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
    Cancelado: Boolean;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;

    Codigo: String;

    constructor Create; reintroduce;
    //--------------------------------------------------------------------------
    function  Login(const _id, _secret: String): TArray<string>;
    procedure Cancelar;
    procedure Resposta(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    function  TelaFechamento: String;
    function  RestCodigoParaJsonDados(const _codigo: String): String;
    //--------------------------------------------------------------------------
    destructor Destroy; override;
  end;

implementation

uses
  uKAFSFuncoes;

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

function  TKAFSLoginGoogle.Login(const _id, _secret: String): TArray<string>;
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

    //while Codigo = '' do
      //Sleep(100);

    OnCodigo.WaitFor(INFINITE);

    if Cancelado then Exit;

    var _jsondados := RestCodigoParaJsonDados(Codigo);
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



    {// Espera pelo código de forma não bloqueante
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
              TThread.Synchronize(nil, procedure begin ShowMessage(_jsondados); end);

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
            TThread.Synchronize(nil, procedure begin ShowMessage('Tempo limite excedido na requisição REST'); end);
        finally
          FreeAndNil(OnDados);
        end;
      end;
      wrTimeout:
        TThread.Synchronize(nil, procedure begin ShowMessage('Tempo limite excedido ao aguardar autorização'); end);
      else
        TThread.Synchronize(nil, procedure begin ShowMessage('Erro ao aguardar autorização'); end);
    end;}
  finally
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
  end;
end;
procedure TKAFSLoginGoogle.Cancelar;
begin

  Cancelado := True;
  OnCodigo.SetEvent; // Desbloqueia o WaitFor imediatamente

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
'    * { margin: 0; padding: 0; box-sizing: border-box; }' +
'    body {' +
'      font-family: Arial, sans-serif;' +
'      background: #2b2b2b;' +
'      min-height: 100vh;' +
'      display: flex;' +
'      align-items: center;' +
'      justify-content: center;' +
'    }' +
'    .card {' +
'      text-align: center;' +
'      padding: 48px 56px;' +
'      border-radius: 18px;' +
'      background: #232323;' +
'      border: 1px solid #3a3a3a;' +
'      max-width: 360px;' +
'      width: 100%;' +
'    }' +
'    .check {' +
'      width: 48px; height: 48px;' +
'      border-radius: 50%;' +
'      background: linear-gradient(135deg, #7c3fe0, #b07af0);' +
'      display: flex; align-items: center; justify-content: center;' +
'      margin: 0 auto 20px;' +
'    }' +
'    .check svg { width: 24px; height: 24px; }' +
'    .title {' +
'      margin: 0 0 8px;' +
'      font-size: 22px;' +
'      font-weight: 700;' +
'      background: linear-gradient(135deg, #9b6fe0, #c89ef2);' +
'      -webkit-background-clip: text;' +
'      -webkit-text-fill-color: transparent;' +
'      background-clip: text;' +
'    }' +
'    .sub {' +
'      font-size: 14px;' +
'      color: #888;' +
'      margin: 0 0 28px;' +
'      line-height: 1.6;' +
'    }' +
'    .divider {' +
'      height: 1px;' +
'      background: linear-gradient(90deg, transparent, #4a3060, transparent);' +
'      margin: 24px 0;' +
'    }' +
'    .brand {' +
'      font-size: 11px;' +
'      letter-spacing: 0.08em;' +
'      text-transform: uppercase;' +
'      background: linear-gradient(135deg, #9b6fe0, #c89ef2);' +
'      -webkit-background-clip: text;' +
'      -webkit-text-fill-color: transparent;' +
'      background-clip: text;' +
'    }' +
'  </style>' +
'</head>' +
'<body>' +
'  <div class="card">' +
'    <div class="check">' +
'      <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">' +
'        <path d="M5 12L10 17L19 7" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>' +
'      </svg>' +
'    </div>' +
'    <div class="title">Login realizado!</div>' +
'    <div class="sub">Você já pode retornar ao aplicativo.<br>' +
'      <span id="instrucao">Fechando esta aba...</span>' +
'    </div>' +
'    <div class="divider"></div>' +
'    <div class="brand">KAFS Group</div>' +
'  </div>' +
'  <script>' +
'    var fechou = false;' +
'    try { window.close(); fechou = true; } catch (e) {}' +
'    if (!fechou) {' +
'      setTimeout(function() {' +
'        document.getElementById("instrucao").innerText = "Você pode fechar esta aba.";' +
'      }, 1500);' +
'    }' +
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

