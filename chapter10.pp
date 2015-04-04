uses sysutils;

{ Constant Declarations }

const TAB = ^I;
   CR	  = #10;
   LF	  = #13;

{ Variable Declarations }

var Look  : char;              { Lookahead Character }
   sp	  : integer;
   LCount : integer;
   ST	  : array['A'..'Z'] of char;

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

{ Look for Symbol in Table }

function InTable(n: char): Boolean;
begin
   InTable := ST[n] <> ' ';
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
   if InTable(N) then Abort('Duplicate Variable Name ' + N);
   ST[N] := 'v';

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

{ Recognize and Translate an Add }
procedure Term; forward;
procedure Add;
begin
   Match('+');
   Term;
   EmitLn('addl '+ IntToStr(sp) +'(%esp), %eax');
end;

{ Recognize and Translate a Subtract }

procedure Subtract;
begin
   Match('-');
   Term;
   EmitLn('subl '+ IntToStr(sp) +'(%esp), %eax');
   EmitLn('negl %eax')
end;

{ Recognize and Translate a Multiply }
procedure Factor; forward;
procedure Multiply;
begin
   Match('*');
   Factor;
   EmitLn('imul ' + IntToStr(sp) + '(%esp)' + ', %eax');
   sp := sp + 4;
end;

{ Recognize and Translate a Divide }

procedure Divide;
begin
   Match('/');
   Factor;
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
   EmitLn('movl ' + IntToStr(sp + 4) + '(%esp)' + ', %eax');
   EmitLn('idivl ' + IntToStr(sp) + '(%esp)');
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
   EmitLn('movl ' + IntToStr(sp + 8) + '(%esp), %eax');
end;

{ Recognize a term }

procedure Term;
begin
   Factor;
   while Look in ['*', '/'] do begin
      sp := sp - 4;
      EmitLn('movl %eax ' + IntToStr(sp) + '(%esp)');
      case Look of
	'*' : Multiply;
	'/' : Divide;
	else Expected('Mulop')
      end;
   end;
end;

{ Parse and Translate a Math Expression }

procedure Expression;
begin
   if Look in ['+', '-'] then
      EmitLn('movl $0 %eax')
   else
      Term;

   while Look in ['+', '-'] do begin
      sp := sp - 4;
      EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
      case LOOK of
	'+' : Add;
	'-' : Subtract;
      else Expected('Addop');
      end;
   end;
end;

{ Parse and Translate a Math Factor }
{ <factor> ::= <number> | (<expression>) | <variable>}
procedure Ident; forward;
procedure Factor;
begin
   if Look='(' then begin
      Match('(');
      Expression;
      Match(')');
      end
   else if isAlpha(Look) then
      Ident
   else
      EmitLn('movl $' + IntToStr(GetNum) + ', %eax');
end;

{ Parse and Translate an Assignment Statement }

procedure Assignment;
var Name : char;
begin
   Name := GetName;
   Match('=');
   Expression;
end;

{ Parse and Translate a Block of Statements }
{  <block> ::= (Assignment)* }

procedure Block;
begin
   while Look <> 'e' do
      Assignment;
end;

{ Parse and Translate a Main Program }
{ <main> := BEGIN <block> END }

procedure Main;
begin
   Match('b');
   Prolog;
   Block;
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

{ Parse and Translate an Identifier }

Procedure Ident;
var Name : string;
begin
   Name := GetName;
   if Look = '(' then begin
      Match('(');
      Match(')');
      EmitLn('call ' + Name);
      end
   else begin
      { Store content of variable into edx }
      EmitLn('movl $' + Name + ', %%edx');

      { Store value of variable into eax }
      EmitLn('movl (%edx), %eax');
   end;
end;

{ Initialize }

procedure Init;
var i: char;
begin
   LCount := 0;
   for i := 'A' to 'Z' do
      ST[i] := ' ';
   GetChar;
end;

{ Main Program }

begin
   Init;
   Prog;
   if Look <> CR then Abort('Unexpected data after ''.''');
end.
