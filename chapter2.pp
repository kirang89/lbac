
program Cradle;

Uses sysutils;

{ Constant Declarations }

const TAB = ^I;

{ Variable Declarations }

var Look: char;              { Lookahead Character }
var sp : Integer;

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
   if Look = x then GetChar
   else Expected('''' + x + '''');
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

{ Get an Identifier }

function GetName: char;
begin
   if not IsAlpha(Look) then Expected('Name');
   GetName := UpCase(Look);
   GetChar;
end;

{ Get a Number }

function GetNum: char;
begin
   if not IsDigit(Look) then Expected('Integer');
   GetNum := Look;
   GetChar;
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
end;

{ Parse and Translate a Math Factor }

procedure Factor;
begin
   EmitLn('movl $' + GetNum + ', %eax')
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

{ Main Program }

begin
   sp := 0;
   Init;
   Expression;
end.
