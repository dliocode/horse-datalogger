{
  ********************************************************************************

  Github - https://github.com/dliocode/horse-datalogger

  ********************************************************************************

  MIT License

  Copyright (c) 2023 Danilo Lucas

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

  ********************************************************************************
}

unit Horse.DataLogger;

interface

uses
  Horse, Horse.Utils.ClientIP,
  DataLogger,
  Web.HTTPApp,
  System.SysUtils, System.JSON, System.DateUtils, System.SyncObjs;

type
{$SCOPEDENUMS ON}
  THorseDataLoggerFormat = (Combined, Common, Dev, Short, Tiny);
{$SCOPEDENUMS OFF}

  THorseDataLogger = class
  private
  class var
    FCriticalSection: TCriticalSection;
    FDataLogger: TDataLogger;
    FLogFormat: string;
    FLoggerProvider: TArray<TDataLoggerProviderBase>;

    class function ValidateValue(AValue: Int64): string; overload;
    class function ValidateValue(AValue: string): string; overload;
    class function ValidateValue(AValue: TDateTime): string; overload;

    class constructor Create;
    class destructor Destroy;
  public
    class function Logger(const AProvider: TArray<TDataLoggerProviderBase>): THorseCallback; overload;
    class function Logger(const ALogFormat: THorseDataLoggerFormat; const AProvider: TArray<TDataLoggerProviderBase>): THorseCallback; overload;
    class function Logger(const ALogFormat: string; const AProvider: TArray<TDataLoggerProviderBase>): THorseCallback; overload;
  end;

implementation

{ THorseDataLogger }

class constructor THorseDataLogger.Create;
begin
  FCriticalSection := TCriticalSection.Create;
  FDataLogger := nil;
end;

class destructor THorseDataLogger.Destroy;
var
  I: Integer;
begin
  if Assigned(FDataLogger) then
  begin
    FDataLogger.Free;
    FDataLogger := nil;
  end
  else
    for I := Low(FLoggerProvider) to High(FLoggerProvider) do
      FLoggerProvider[I].Free
end;

class function THorseDataLogger.Logger(const AProvider: TArray<TDataLoggerProviderBase>): THorseCallback;
begin
  Result := Logger(THorseDataLoggerFormat.Combined, AProvider);
end;

class function THorseDataLogger.Logger(const ALogFormat: THorseDataLoggerFormat; const AProvider: TArray<TDataLoggerProviderBase>): THorseCallback;
var
  LFormat: string;
begin
  case ALogFormat of
    THorseDataLoggerFormat.Combined:
      LFormat :=
        '${request_remote_clientip} [${time}] "${request_method} ${request_raw_path_info}${request_query} ' +
        '${request_protocol_version}" ${response_status_code} ${response_content_length} "${request_referer}" "${request_user_agent}"';

    THorseDataLoggerFormat.Common:
      LFormat :=
        '${request_remote_clientip} [${time}] "${request_method} ${request_raw_path_info}${request_query} ' +
        '${request_protocol_version}" ${response_status_code} ${response_content_length}';

    THorseDataLoggerFormat.Dev:
      LFormat :=
        '${request_method} ${request_raw_path_info}${request_query} ' +
        '${response_status_code} ${execution_time} ms - ${response_content_length}';

    THorseDataLoggerFormat.Short:
      LFormat :=
        '${request_remote_clientip} ${request_method} ${request_raw_path_info}${request_query} ' +
        '${request_protocol_version} ${response_status_code} ${response_content_length} ${execution_time} ms';

    THorseDataLoggerFormat.Tiny:
      LFormat :=
        '${request_method} ${request_raw_path_info}${request_query} ' +
        '${response_status_code} ${response_content_length} - ${execution_time} ms';
  end;

  Result := Logger(LFormat, AProvider);
end;

class function THorseDataLogger.Logger(const ALogFormat: string; const AProvider: TArray<TDataLoggerProviderBase>): THorseCallback;
begin
  FLogFormat := ALogFormat;
  FLoggerProvider := AProvider;

  Result :=
      procedure(ARequest: THorseRequest; AResponse: THorseResponse; ANext: TProc)
    var
      LBeforeDateTime: TDateTime;
      LMilliSecondsBetween: Integer;
      LWebRequest: TWebRequest;
      LWebResponse: TWebResponse;
      LJOMessage: TJSONObject;
    begin
      if not Assigned(FDataLogger) then
      begin
        FCriticalSection.Acquire;
        try
          if not Assigned(FDataLogger) then
          begin
            FDataLogger := TDataLogger.Builder;
            FDataLogger.SetProvider(FLoggerProvider);
            FDataLogger.SetLogFormat(FLogFormat);
          end;
        finally
          FCriticalSection.Release;
        end;
      end;

      LJOMessage := TJSONObject.Create;
      try
        LBeforeDateTime := Now;
        try
          ANext;
        finally
          LMilliSecondsBetween := MilliSecondsBetween(Now, LBeforeDateTime);

          LWebRequest := ARequest.RawWebRequest;
          LWebResponse := AResponse.RawWebResponse;

          LJOMessage.AddPair('time', ValidateValue(LBeforeDateTime));
          LJOMessage.AddPair('execution_time', ValidateValue(LMilliSecondsBetween));

          // Request
          LJOMessage.AddPair('request_accept', ValidateValue(LWebRequest.Accept));
          LJOMessage.AddPair('request_authorization', ValidateValue(LWebRequest.Authorization));
          LJOMessage.AddPair('request_cache_control', ValidateValue(LWebRequest.CacheControl));
          LJOMessage.AddPair('request_connection', ValidateValue(LWebRequest.Connection));

          try
            if not Trim(LWebRequest.ContentType).Contains('multipart/form-data') then
              LJOMessage.AddPair('request_content', ValidateValue(LWebRequest.Content));
          except
            LJOMessage.AddPair('request_content', ValidateValue(''));
          end;

          LJOMessage.AddPair('request_content_encoding', ValidateValue(LWebRequest.ContentEncoding));
          LJOMessage.AddPair('request_content_length', ValidateValue(LWebRequest.ContentLength));
          LJOMessage.AddPair('request_content_type', ValidateValue(LWebRequest.ContentType));
          LJOMessage.AddPair('request_content_version', ValidateValue(LWebRequest.ContentVersion));
          LJOMessage.AddPair('request_cookie', ValidateValue(LWebRequest.Cookie));
          LJOMessage.AddPair('request_cookie_fields', ValidateValue(LWebRequest.CookieFields.Text));
          LJOMessage.AddPair('request_derived_from', ValidateValue(LWebRequest.DerivedFrom));
          LJOMessage.AddPair('request_from', ValidateValue(LWebRequest.From));
          LJOMessage.AddPair('request_host', ValidateValue(LWebRequest.Host));
          LJOMessage.AddPair('request_internal_path_info', ValidateValue(LWebRequest.InternalPathInfo));
          LJOMessage.AddPair('request_internal_script_name', ValidateValue(LWebRequest.InternalScriptName));
          LJOMessage.AddPair('request_method', ValidateValue(LWebRequest.Method));
          LJOMessage.AddPair('request_path_info', ValidateValue(LWebRequest.PathInfo));
          LJOMessage.AddPair('request_path_translated', ValidateValue(LWebRequest.PathTranslated));
          LJOMessage.AddPair('request_protocol_version', ValidateValue(LWebRequest.ProtocolVersion));

          if Trim(LWebRequest.Query).IsEmpty then
            LJOMessage.AddPair('request_query', '')
          else
            LJOMessage.AddPair('request_query', '?' + ValidateValue(LWebRequest.Query));

          LJOMessage.AddPair('request_query_fields', ValidateValue(LWebRequest.QueryFields.Text));
          LJOMessage.AddPair('request_raw_path_info', ValidateValue(LWebRequest.RawPathInfo));
          LJOMessage.AddPair('request_referer', ValidateValue(LWebRequest.Referer));
          LJOMessage.AddPair('request_remote_addr', ValidateValue(LWebRequest.RemoteAddr));
          LJOMessage.AddPair('request_remote_clientip', ValidateValue(ClientIP(ARequest)));
          LJOMessage.AddPair('request_remote_host', ValidateValue(LWebRequest.RemoteHost));
          LJOMessage.AddPair('request_remote_ip', ValidateValue(LWebRequest.RemoteIP));
          LJOMessage.AddPair('request_script_name', ValidateValue(LWebRequest.ScriptName));
          LJOMessage.AddPair('request_server_port', ValidateValue(LWebRequest.ServerPort));
          LJOMessage.AddPair('request_title', ValidateValue(LWebRequest.Title));
          LJOMessage.AddPair('request_url', ValidateValue(LWebRequest.URL));
          LJOMessage.AddPair('request_user_agent', ValidateValue(LWebRequest.UserAgent));

          // Response
          LJOMessage.AddPair('response_allow', ValidateValue(LWebResponse.Allow));
          LJOMessage.AddPair('response_content', ValidateValue(LWebResponse.Content));
          LJOMessage.AddPair('response_content_encoding', ValidateValue(LWebResponse.ContentEncoding));
          LJOMessage.AddPair('response_content_length', ValidateValue(LWebResponse.ContentLength));
          LJOMessage.AddPair('response_content_type', ValidateValue(LWebResponse.ContentType));
          LJOMessage.AddPair('response_content_version', ValidateValue(LWebResponse.ContentVersion));
          LJOMessage.AddPair('response_custom_headers', ValidateValue(LWebResponse.CustomHeaders.Text));
          LJOMessage.AddPair('response_date', ValidateValue(LWebResponse.Date));
          LJOMessage.AddPair('response_derived_from', ValidateValue(LWebResponse.DerivedFrom));
          LJOMessage.AddPair('response_expires', ValidateValue(LWebResponse.Expires));
          LJOMessage.AddPair('response_last_modified', ValidateValue(LWebResponse.LastModified));
          LJOMessage.AddPair('response_location', ValidateValue(LWebResponse.Location));
          LJOMessage.AddPair('response_log_message', ValidateValue(LWebResponse.LogMessage));
          LJOMessage.AddPair('response_realm', ValidateValue(LWebResponse.Realm));
          LJOMessage.AddPair('response_reason', ValidateValue(LWebResponse.ReasonString));
          LJOMessage.AddPair('response_server', ValidateValue(LWebResponse.Server));
          LJOMessage.AddPair('response_status_code', ValidateValue(LWebResponse.StatusCode));
          LJOMessage.AddPair('response_title', ValidateValue(LWebResponse.Title));
          LJOMessage.AddPair('response_version', ValidateValue(LWebResponse.Version));
          LJOMessage.AddPair('response_wwwauthenticate', ValidateValue(LWebResponse.WWWAuthenticate));

          case AResponse.Status of
            0 .. 299:
              FDataLogger.Success(LJOMessage, ClassName);

            300 .. 399:
              FDataLogger.Info(LJOMessage, ClassName);

            400 .. 499:
              FDataLogger.Warn(LJOMessage, ClassName);
          else
            FDataLogger.Error(LJOMessage, ClassName);
          end;
        end;
      finally
        LJOMessage.Free;
      end;
    end;
end;

class function THorseDataLogger.ValidateValue(AValue: Int64): string;
begin
  Result := AValue.ToString;
end;

class function THorseDataLogger.ValidateValue(AValue: string): string;
var
  LMessage: string;
begin
  LMessage := String(UTF8Encode(AValue));

  if LMessage.IsEmpty then
    Result := '-'
  else
    Result := LMessage;
end;

class function THorseDataLogger.ValidateValue(AValue: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', AValue);
end;

end.