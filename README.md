<div align="center">
<img width="188" height="200" alt="image" src="https://github.com/user-attachments/assets/60d8a531-d1b0-4282-a91c-0d24467ffd8b" /></div><p>

# <div align="center"><strong>TKAFSLoginGoogle</strong></div> 

<div align="center">
Componente Delphi/FireMonkey para autenticação OAuth2 com Google,<br> 
utilizando servidor HTTP local para captura do código de autorização e obtenção de dados do usuário.
</p>

[![Delphi](https://img.shields.io/badge/Delphi-XE8+-B22222?logo=delphi)](https://www.embarcadero.com/products/delphi)
[![Multiplatform](https://img.shields.io/badge/Multiplatform-Windows/Linux/macOS/Android/IOS-8250DF)]([https://www.embarcadero.com/products/delphi/cross-platform](https://docwiki.embarcadero.com/RADStudio/Athens/en/Developing_Multi-Device_Applications))
[![License](https://img.shields.io/badge/License-GPLv3-blue)](LICENSE)
</div><br>

## ⚠️ Dependências externas

Este projeto utiliza as seguintes unidades externas que devem ser adicionadas ao projeto:
- [uKAFSFuncoes](https://github.com/ViniciusdoAmaralReis/uKAFSFuncoes) 
<div></div><br><br>


## ⚡ Chamada - Autenticação com Google
```pascal
function TKAFSLoginGoogle.Login(const _id, _secret: String): TArray<string>;
```
- Exemplo de chamada:
```pascal
var _logingoogle := TKAFSLoginGoogle.Create;
try
  // Realizar autenticação
  var _dadosusuario := _logingoogle.Login('seu_client_id', 'seu_client_secret');

  // Processar dados do usuário
  ShowMessage('Url da imagem do Usuário: ' + _dadosusuario[0]);
  ShowMessage('Nome do Usuário: ' + _dadosusuario[1]);
  ShowMessage('Sobrenome do Usuário: ' + _dadosusuario[2]);
  ShowMessage('Email do Usuário: ' + _dadosusuario[3]);

finally
  FreeAndNil(_logingoogle);
end;
```
<div></div><br><br>


## 🛠️ Configuração - Google Cloud Console
1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Crie credenciais do tipo "ID do cliente OAuth"
3. Configure as URIs de redirecionamento autorizadas:
```
http://localhost:8080
```
4. Habilite as APIs necessárias:
   - Google People API -> IDs do cliente OAuth 2.0 (cliente para Aplicativo da Web)
<div></div><br><br>
   

---
**Nota**: Requer configuração prévia no Google Cloud Console com URIs de redirecionamento adequadas. Certifique-se de ter a unidade [uKAFSFuncoes](https://github.com/ViniciusdoAmaralReis/uKAFSFuncoes) baixada e configurada corretamente no projeto.

**Para uso em Android**: O comportamento do servidor HTTP local pode variar conforme fabricante e versão do Android.
