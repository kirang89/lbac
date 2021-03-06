
program Cradle;

Uses sysutils;

{ Constant Declarations }

const TAB = ^I;
CR = #10;

{ Variable Declarations }

var Look: char;              { Lookahead Character }
var sp : Integer;            { Tracking the stack pointer }

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

procedure SkipSpace; forward;

{ Match a Specific Input Character }

procedure Match(x: char);
begin
   if Look <> x then Expected('''' + x + '''')
   else begin
      GetChar;
      SkipSpace;
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

{ Recognize an alphanumeric character }

function IsAlNum(c : char): boolean;
begin
   IsAlNum := IsAlpha(c) or IsDigit(c)
end;

{ Recognize a whitespace character }

function IsSpace(c :char): boolean;
begin
   IsSpace := c in[' ', TAB]
end;

{ Skips whitespace characters in input }

procedure SkipSpace;
begin
   while IsSpace(Look) do
      GetChar;
end;

{ Get an Identifier }

function GetName: string;
var Token : string;
begin
   if not IsAlpha(Look) then Expected('Name');

   Token := '';
   while IsAlNum(Look) do begin
      Token := Token + UpCase(Look);
      GetChar;
   end;
   GetName := Token;
   SkipSpace;
end;

{ Get a Number }

function GetNum: string;
var Value : string;
begin
   if not IsDigit(Look) then Expected('Integer');

   Value := '';
   while IsDigit(Look) do begin
      Value := Value + Look;
      GetChar;
   end;
   GetNum := Value;
   SkipSpace;
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

{ Initialize }

procedure Init;
begin
   GetChar;
   SkipSpace;
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

{ Forward Declaration }
Procedure Expression; forward;

{ Parse and Translate a Math Factor }
{ <factor> ::= <number> | (<expression>) | <variable>}

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
      EmitLn('movl $' + GetNum + ', %eax');
end;

{ Recognize and Translate a Multiply }

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

{ Recognize and Translate an Add }

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

{ Read and Translate an Assignment }

procedure Assignment;
var Name : string;
begin
   Name := GetName;
   Match('=');
   Expression;
   EmitLn('movl $' + Name + ', %%edx');
   { Point edx to the content in eax }
   EmitLn('movl %eax, (%edx)')
end;

{ Main Program }

begin
   sp := 0;
   Init;
   Assignment;
   if Look <> CR then Expected('Newline');
end.
