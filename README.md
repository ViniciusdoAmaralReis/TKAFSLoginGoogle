# 🧩 TKAFSLoginGoogle

Componente Delphi/FireMonkey para autenticação OAuth2 com Google, utilizando servidor HTTP local para captura do código de autorização e obtenção de dados do usuário.

## ⚠️ Dependências externas

Este projeto utiliza as seguintes unidades externas que devem ser adicionadas ao projeto:
- 🧩 [uKAFSFuncoes](https://github.com/ViniciusdoAmaralReis/uKAFSFuncoes) 

## 💡 Chamada - Autenticação com Google

```pascal
function TKAFSLoginGoogle.Login(const _id, _secret: String): TArray<string>;
```
- Exemplo de chamada:
```pascal
var _logingoogle := TKAFSLoginGoogle.Create;
try
  // Realizar autenticação
  var _dadosusuario := LoginGoogle.Login('seu_client_id', 'seu_client_secret');

  // Processar dados do usuário
  ShowMessage('Url da imagem do Usuário: ' + _dadosusuario[0]);
  ShowMessage('Nome do Usuário: ' + _dadosusuario[1]);
  ShowMessage('Sobrenome do Usuário: ' + _dadosusuario[2]);
  ShowMessage('Email do Usuário: ' + _dadosusuario[3]);

finally
  FreeAndNil(_logingoogle);
end;
```

## 🛠️ Configuração - Google Cloud Console

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Crie credenciais do tipo "ID do cliente OAuth"
3. Configure as URIs de redirecionamento autorizadas:
```
http://localhost:8080
```
4. Habilite as APIs necessárias:
   - Google People API -> IDs do cliente OAuth 2.0 (cliente para Aplicativo da Web)
   
## 🏛️ Status de compatibilidade

| Sistema operacional | Status | Observações |
|---------------------|--------|-------------|
| **Windows** | ✅ **Totalmente Compatível** | Funcionamento completo com todos os recursos |
| **macOS** | ✅ **Compatível** | Requer permissões de rede |
| **Linux** | ✅ **Compatível** | Requer permissões de rede |
| **Android** | ⚠️ **Compatibilidade Parcial** | Comportamento pode variar entre dispositivos |

| IDE | Versão mínima | Observações |
|---------------------|------------------------|-------------|
| **Delphi** | ✅ **XE8** | Versões com suporte a REST components |

---

**Nota**: Requer configuração prévia no Google Cloud Console com URIs de redirecionamento adequadas. Certifique-se de ter a unidade `uKAFSFuncoes` baixada e configurada corretamente no projeto.

**Para uso em Android**: O comportamento do servidor HTTP local pode variar conforme fabricante e versão do Android.
