uses sysutils;

{ Constant Declarations }

const TAB = ^I;
   CR	  = #10;
   LF	  = #13;

{ Variable Declarations }

var Look  : char;              { Lookahead Character }
   LCount : integer;

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

{ Read New Character From Input Stream }

procedure GetChar;
begin
   Read(Look);
end;

{ Get an Identifier }

function GetName: char;
begin
   if not IsAlpha(Look) then Expected('Name');
   GetName := UpCase(Look);
   GetChar;
end;

{ Get a Number }

function GetNum: integer;
var Val	: integer;
begin
   Val := 0;
   if not IsDigit(Look) then Expected('Integer');
   while IsDigit(Look) do begin
      Val := 10 * Val + Ord(Look) - Ord('0');
      GetChar;
   end;
   GetNum := Val;
end;

{ Match a Specific Input Character }

procedure Match(x: char);
begin
   if Look <> x then Expected('''' + x + '''')
   else begin
      GetChar;
   end;
end;

{ Write Header Info }

procedure Header;
begin
  EmitLn('.data');
end;

{ Write the Prolog }

procedure Prolog;
begin
   EmitLn('.global start');
   EmitLn('start:');
end;

{ Write the Epilog }

procedure Epilog;
begin
   EmitLn('movl %eax, %ebx    # Set return code');
   EmitLn('movl $1, %eax      # Linux kernel command to exit a program');
   EmitLn('int $0x80          # Wakes up kernel to run the exit command');
end;

{ Allocate Storage for a Variable }

procedure Alloc(N: char);
var Symbol : string;
   Val	   : string;
begin
   if Look = '=' then begin
      Match('=');

      if Look = '-' then begin
	 Match('-');
	 Val := '-' + IntToStr(GetNum);
	 end
      else
	 Val := IntToStr(GetNum);

      Symbol := N + ' = ' + Val;
      end
   else
      Symbol := N + ' = 0';

   WriteLn('<Add ' + Symbol  + ' to stack>');
end;

{ Process a Data Declaration }
{ <data declaration> ::= v <var-list> }
{ <var-list> ::= <ident> (, <ident>)* }
procedure Decl;
begin
   Match('v');
   Alloc(GetName);
   while Look = ',' do begin
      GetChar;
      Alloc(GetName);
   end
end;

{ Parse and Translate Global Declarations }
{ <top-level decls> ::= ( <data declaration> )* }
procedure TopDecls;
begin
   while Look <> 'b' do
      case Look of
        'v': Decl;
      else Abort('Unrecognized Keyword ''' + Look + '''');
	EmitLn('Look: ' +  Look);
      end;
end;

{ Parse and Translate a Main Program }
{ <main> := BEGIN <block> END }
procedure Main;
begin
   Match('b');
   Prolog;
   Match('e');
   Epilog;
end;

{ <program> ::= PROGRAM <top-level decl> <main> '.' }
{  Parse and Translate a Program }

procedure Prog;
begin
   Match('p');
   Header;
   TopDecls;
   Main;
   Match('.');
end;

{ Initialize }

procedure Init;
begin
   LCount := 0;
   GetChar;
end;

{ Main Program }

begin
   Init;
   Prog;
   if Look <> CR then Abort('Unexpected data after ''.''');
end.
