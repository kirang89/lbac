program Cradle;

Uses sysutils;

{ Constant Declarations }

const TAB = ^I;
   CR	  = #10;
   LF	  = #13;

{ Variable Declarations }

var Look  : char;              { Lookahead Character }
   LCount : integer;

{ Read New Character From Input Stream }

procedure GetChar;
begin
   Read(Look);
end;

{ Output a String with Tab }

procedure Emit(s: string);
begin
   Write(TAB, s);
end;

{ Output a String with Tab and CRLF }

procedure EmitLn(s: string);
begin
   Emit(s);
   WriteLn;
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

{ Get an Identifier }

function GetName: char;
begin
   if not IsAlpha(Look) then Expected('Name');
   GetName := UpCase(Look);
   GetChar;
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

{ Write the Prolog }

procedure Prolog;
begin
   EmitLn('.text');
   EmitLn('.global _start');
   EmitLn('_start:');
end;


{ Write the Epilog }

procedure Epilog;
begin
   EmitLn('movl %eax, %ebx  # Set return code');
   EmitLn('movl $1, %eax    # Linux kernel command to exit a program');
   EmitLn('int $0x80        # Wakes up kernel to run the exit command');
end;

{ Parse and Translate A Program }

procedure Prog;
var  Name: char;
begin
   Match('p');            { Handles program header part }
   Name := GetName;
   Prolog;
   EmitLn('');
   EmitLn(UpCase(Name));
   EmitLn('');
   Match('.');
   Epilog;
end;

{ Initialize }

procedure Init;
begin
   LCount := 0;
   GetChar;
end;

begin
   Init;
   Prog;
end.
