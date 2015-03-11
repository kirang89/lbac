
{ Constant Declarations }

const TAB = ^I;
   CR	  = #10;
   LF	  = #13;

{ Variable Declarations }

var Look : char;              { Lookahead Character }
   sp	 : integer;	       { Stack Pointer }
   Token : string;

{ Read New Character From Input Stream }

procedure GetChar;
begin
   Read(Look);
end;

{ Report an Error }

procedure Error(s: string);
begin
   WriteLn;
   WriteLn(^G, 'Error: ', s, '.');
end;

{ Report Error and Halt }

procedure Abort(s: string);
begin
   Error(s);
   Halt;
end;

{ Report What Was Expected }

procedure Expected(s: string);
begin
   Abort(s + ' Expected');
end;

{ Match a Specific Input Character }

procedure Match(x: char);
begin
   if Look <> x then Expected('''' + x + '''')
   else begin
      GetChar;
   end;
end;

{ Recognize an Alpha Character }

function IsAlpha(c: char): boolean;
begin
   IsAlpha := upcase(c) in ['A'..'Z'];
end;

{ Recognize a Decimal Digit }

function IsDigit(c: char): boolean;
begin
   IsDigit := c in ['0'..'9'];
end;

{ Recognize an Alphanumeric Character }

function IsAlNum(c: char): boolean;
begin
   IsAlNum := IsAlpha(c) or IsDigit(c);
end;

{ Recognize a whitespace character }

function IsWhite(c :char): boolean;
begin
   IsWhite := c in[' ', TAB];
end;

{ Recognize Any Operator }

function IsOp(c: char): boolean;
begin
   IsOp := c in ['+', '-', '*', '/', '<', '>', ':', '='];
end;

{ Skips whitespace characters in input }

procedure SkipWhite;
begin
   while IsWhite(Look) do
      GetChar;
end;

{ Skip a CRLF }

procedure Fin;
begin
   if Look = CR then GetChar;
   if Look = LF then GetChar;
end;

{ Get an Identifier }

function GetName: string;
var x: string[8];
begin
   x := '';
   if not IsAlpha(Look) then Expected('Name');
   while IsAlNum(Look) do begin
     x := x + UpCase(Look);
     GetChar;
   end;
   GetName := x;
   SkipWhite;
end;

{ Get a Number }

function GetNum: string;
var x: string[16];
begin
   x := '';
   if not IsDigit(Look) then Expected('Integer');
   while IsDigit(Look) do begin
     x := x + Look;
     GetChar;
   end;
   GetNum := x;
   SkipWhite;
end;

{ Get an Operator }
function GetOp: char;
begin
   GetOp := Look;
   GetChar;
end;

{ A Lexical Scanner }

function Scan: string;
begin
   { Ensure that CR/LF are skipped }
   while Look = CR do
      Fin;

   if IsAlpha(Look) then
   begin
      Scan := GetName;
      WriteLn('Name => ' + Scan);
   end
   else if IsDigit(Look) then
   begin
      Scan := GetNum;
      WriteLn('Number => ' + Scan);
   end
   else if IsOp(Look) then
   begin
      Scan := GetOp;
      WriteLn('Op => ' + Scan);
   end
   else begin
      Scan := Look;
      WriteLn('Other => ' + Scan);
      GetChar;
   end;

   SkipWhite;
end;

{ Initialize }

procedure Init;
begin
   GetChar;
end;

{ Main Program }
begin
   Init;
   repeat
      Token := Scan;
      if Token = CR then Fin;
   until Token = '.';
end.
