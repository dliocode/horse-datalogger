# Horse-DataLogger

<p align="center">
  <img src="https://img.shields.io/github/v/release/dliocode/horse-datalogger?style=flat-square">
  <img src="https://img.shields.io/github/stars/dliocode/horse-datalogger?style=flat-square">
  <img src="https://img.shields.io/github/forks/dliocode/horse-datalogger?style=flat-square">
  <img src="https://img.shields.io/github/contributors/dliocode/horse-datalogger?color=orange&style=flat-square">
  <img src="https://tokei.rs/b1/github/dliocode/horse-datalogger?color=red&category=lines">
  <img src="https://tokei.rs/b1/github/dliocode/horse-datalogger?color=green&category=code">
  <img src="https://tokei.rs/b1/github/dliocode/horse-datalogger?color=yellow&category=files">
</p>

# 

Middleware projetado para registrar todas às requisições e solicitações HTTP no [Horse](https://github.com/hashload/horse).

Support: developer.dlio@gmail.com

## ⚙️ Instalação

### Para instalar em seu projeto usando [boss](https://github.com/HashLoad/boss):
```sh
$ boss install github.com/dliocode/horse-datalogger
```

### Instalação Manual

Adicione as seguintes pastas ao seu projeto, em *Project > Options > Delphi Compiler > Search path*

```
../src
```

### Dependências

[DataLogger](https://github.com/dliocode/datalogger) - Essa é ferramenta utilizado para registrar todas solicitações HTTP do Horse. 

Para mais informações de como utilizar essa ferramenta em outras situações, [clique aqui](https://github.com/dliocode/datalogger#providers).

[ClientIP](https://github.com/dliocode/horse-utils-clientip) - Utilizado para capturar o IP.

## Observações

Para usar este Middleware é necessário entender algumas coisas.

_Providers_: Serve essencialmente para armazenar seus logs.

_Providers_ diponíveis: [Clique aqui](https://github.com/dliocode/datalogger#providers)

Em qual posição é recomendado utilizar este _provider_ no [Horse](https://github.com/hashload/horse): Recomendamos que seja adicionado na primeira posição, para que seja registrado todas as informações passadas por ele.


## Como Usar

Para utilizar é necessário adicionar a Uses ```Horse.DataLogger``` e depois adicionar os _Providers_ escolhidos para fazer o registro dos logs;

Agora que você já entendeu um pouco de como funciona, vamos aos exemplos;

### Simples

```delphi
uses 
  Horse, Horse.DataLogger,
  DataLogger.Provider.Console; // Provider para Console

begin
  THorse
  .Use(THorseDataLogger.Logger([TProviderConsole.Create])) // Adiconando Middleware e o Provider

  .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
```

## Formatos Predefinidos

``` 
  Combined, Common, Dev, Short, Tiny 
```

Cada formato possui uma estrutura diferente e preestabelecida.

### Combined

Saída de log combinada Apache padrão.

```
${request_remote_clientip} [${time}] "${request_method} ${request_raw_path_info}${request_query} '${request_protocol_version}" ${response_status_code} ${response_content_length} "${request_referer}" "${request_user_agent}"
```

### Common

Saída de log comum Apache padrão.

```
${request_remote_clientip} [${time}] "${request_method} ${request_raw_path_info}${request_query} '${request_protocol_version}" ${response_status_code} ${response_content_length}
```

### Dev

Saída de log simples

```
${request_method} ${request_raw_path_info}${request_query} ${response_status_code} ${execution_time} ms - ${response_content_length}
```

### Short

Mais curto que o padrão, incluindo também o tempo de resposta.

```
${request_remote_clientip} ${request_method} ${request_raw_path_info}${request_query} ${request_protocol_version} ${response_status_code} ${response_content_length} ${execution_time} ms
```

### Tiny

Saída mínima de log

```
${request_method} ${request_raw_path_info}${request_query} ${response_status_code} ${response_content_length} - ${execution_time} ms
```

## Exemplo de uso

```delphi
uses 
  Horse, Horse.DataLogger,
  DataLogger.Provider.Console; // Provider para Console

begin
  THorse
  .Use(
    THorseDataLogger.Logger(
      THorseDataLoggerFormat.tfCombined, // Formato dos logs  
      [TProviderConsole.Create]          // Adicionado o Middleware
    )
  ) 

  .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

   // output: 0:0:0:0:0:0:0:1 [2022-12-22 17:18:31:791] "GET /ping HTTP/1.1" 200 4 "-" "PostmanRuntime/7.30.0"

  THorse.Listen(9000);
end.
```

## Formatos customizados

Você pode definir seus próprios formatos de utilização

```delphi
uses 
  Horse, Horse.DataLogger,
  DataLogger.Provider.Console; // Provider para Console

begin
  THorse
  .Use(
    THorseDataLogger.Logger(
      // Formato dos logs  
      '${request_method} ${request_raw_path_info}${request_query} ${response_status_code} ${response_content_length} - ${execution_time} ms', 

      // Adicionado o Middleware
      [TProviderConsole.Create]          
    )
  ) 

  .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

   // output: 0:0:0:0:0:0:0:1 [2022-12-22 17:18:31:791] "GET /ping HTTP/1.1" 200 4 "-" "PostmanRuntime/7.30.0"

  THorse.Listen(9000);
end.
```

## Formatos disponíveis

```
${time}
${execution_time}
${request_accept}
${request_authorization}
${request_cache_control}
${request_connection}
${request_content}
${request_content_encoding}
${request_content_length}
${request_content_type}
${request_content_version}
${request_cookie}
${request_cookie_fields}
${request_derived_from}
${request_from}
${request_host}
${request_internal_path_info}
${request_internal_script_name}
${request_method}
${request_path_info}
${request_path_translated}
${request_protocol_version}
${request_query}
${request_query_fields}
${request_raw_path_info}
${request_referer}
${request_remote_addr}
${request_remote_clientip}
${request_remote_host}
${request_remote_ip}
${request_script_name}
${request_server_port}
${request_title}
${request_url}
${request_user_agent}
${response_allow}
${response_content}
${response_content_encoding}
${response_content_length}
${response_content_type}
${response_content_version}
${response_custom_headers}
${response_date}
${response_derived_from}
${response_expires}
${response_last_modified}
${response_location}
${response_log_message}
${response_realm}
${response_reason}
${response_server}
${response_status_code}
${response_title}
${response_version}
${response_wwwauthenticate}
```

## Adicionando outros _Providers_

Você pode adicionar vários _Providers_ para registrar cada solicitação em locais diferentes.

Para este exemplo, vamos mostrar as requisições em Console e vamos salvar no formato Texto, tudo isso utilizando duas _Units_ para registrar 
``` 
DataLogger.Provider.Console, DataLogger.Provider.TextFile 
```

### Múltiplos _Providers_

```delphi
uses 
  Horse, Horse.DataLogger,
  DataLogger.Provider.Console, // Provider para Console
  DataLogger.Provider.TextFile, // Provider para TextFile
  System.IOUtils;

begin
  THorse
  .Use(
    THorseDataLogger.Logger(
      THorseDataLoggerFormat.tfCombined, // Formato dos logs  
        TProviderConsole.Create,
      
        TProviderTextFile.Create
          .LogDir(TPath.GetDirectoryName(ParamStr(0)) + '\log\request')
          .PrefixFileName('request_')  
          .Extension('.txt')      
      ]          
    )
  ) 

  .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

   // output: 0:0:0:0:0:0:0:1 [2022-12-22 17:18:31:791] "GET /ping HTTP/1.1" 200 4 "-" "PostmanRuntime/7.30.0"

  THorse.Listen(9000);
end.
```