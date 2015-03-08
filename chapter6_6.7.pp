
program Cradle;

Uses sysutils;

{ Constant Declarations }

const TAB = ^I;
CR = #10;

{ Variable Declarations }

var Look  : char;              { Lookahead Character }
   sp	  : integer;	       { Stack Pointer }
   LCount : integer;	       { Label Counter }

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

{ Recognize a boolean literal }

function IsBoolean(c : char): Boolean;
begin
   IsBoolean := Upcase(c) in ['T', 'F'];
end;

{ Recognize an OR operation }

function IsOrOp(c : char): Boolean;
begin
   IsOrOp := c in ['|', '~'];
end;

{ Recognize a relational operator }

function IsRelop(c : char): Boolean;
begin
   IsRelop := c in ['=', '#', '<', '>'];
end;

{ Skips whitespace characters in input }

procedure SkipSpace;
begin
   while IsSpace(Look) do
      GetChar;
end;

{ Get a Name }

function GetName: char;
begin
   if not IsAlpha(Look) then Expected('Name');
   GetName := UpCase(Look);
   GetChar;
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

{ Get a boolean literal }

function GetBoolean: Boolean;
begin
   if not IsBoolean(Look) then Expected('Boolean Literal');
   GetBoolean := Upcase(Look) = 'T';
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
   LCount := 0;
   GetChar;
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

procedure SignedFactor;
begin
   if Look = '+' then
      GetChar;
   if Look = '-' then begin
      GetChar;
      if IsDigit(Look) then
	 EmitLn('movl $-' + GetNum + ', %eax')
      else begin
         Factor;
         EmitLn('neg %eax');
      end;
   end
   else Factor;
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

{ Recognize and Translate a Relational "Equals" }

procedure Equals;
begin
   Match('=');
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');

   Expression;

   EmitLn('cmp ' + IntToStr(sp) + '(%esp), %eax');
   sp := sp + 4;

   EmitLn('sete %cl');
   EmitLn('andb $1, %cl');
   EmitLn('movzbl %cl, %eax');

   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
end;

{ Recognize and Translate a Relational "Not Equals" }

procedure NotEquals;
begin
   Match('#');
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');

   Expression;

   EmitLn('cmp ' + IntToStr(sp) + '(%esp), %eax');
   sp := sp + 4;

   EmitLn('setne %cl');
   EmitLn('andb $1, %cl');
   EmitLn('movzbl %cl, %eax');

   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
end;


{---------------------------------------------------------------}
{ Recognize and Translate a Relational "Less Than" }

procedure Less;
begin
   Match('<');
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');

   Expression;

   EmitLn('cmp ' + IntToStr(sp) + '(%esp), %eax');
   sp := sp + 4;

   EmitLn('setl %cl');
   EmitLn('andb $1, %cl');
   EmitLn('movzbl %cl, %eax');

   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
end;


{---------------------------------------------------------------}
{ Recognize and Translate a Relational "Greater Than" }

procedure Greater;
begin
   Match('>');
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');

   Expression;

   EmitLn('cmp ' + IntToStr(sp) + '(%esp), %eax');
   sp := sp + 4;

   EmitLn('setg %cl');
   EmitLn('andb $1, %cl');
   EmitLn('movzbl %cl, %eax');

   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');
end;


procedure Relation; forward;

{ Recognize a Boolean Factor }

procedure BoolFactor;
begin
   if IsBoolean(Look) then
      begin
      sp := sp - 4;
      if GetBoolean then
	 EmitLn('movl $1, ' + IntToStr(sp) + '(%esp)')
      else
	 EmitLn('movl $0, ' + IntToStr(sp) + '(%esp)');
      end
   else
      Relation;
end;

{ Parse a boolean factor with NOT }

procedure NotFactor;
begin
   if Look = '!' then begin
      Match('!');
      BoolFactor;
      EmitLn('not ' + IntToStr(sp) + '(%esp)');
      end
   else
      BoolFactor;
end;

{ Parse and Translate a boolean term }

procedure BoolTerm;
begin
   NotFactor;
   while Look = '&' do begin
      Match('&');
      NotFactor;
      EmitLn('movl ' + IntToStr(sp) + '(%esp), %ecx');
      sp := sp + 4;
      EmitLn('andl ' + IntToStr(sp) + '(%esp), %ecx');
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

{ Recognize and Translate a Boolean OR }

procedure BoolOr;
begin
   Match('|');
   BoolTerm;
   EmitLn('movl ' + IntToStr(sp) +'(%esp), %ecx');
   sp := sp + 4;
   EmitLn('orl ' + IntToStr(sp) +'(%esp), %ecx');
   sp := sp + 4;
end;

{ Recognize and Translate a Boolean XOR }

procedure BoolXor;
begin
   Match('~');
   BoolTerm;
   EmitLn('movl ' + IntToStr(sp) +'(%esp), %ecx');
   sp := sp + 4;
   EmitLn('xorl ' + IntToStr(sp) +'(%esp), %ecx');
   sp := sp + 4;
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

{ Parse and Translate a boolean expression }

procedure BoolExpression;
begin
   BoolTerm;
   while IsOrOp(Look) do begin
      case Look of
	'|' : BoolOr;
	'~' : BoolXor;
      end;
   end;
end;

{ Parse and Translate a Relation }

procedure Relation;
begin
   Expression;
   if IsRelop(Look) then begin
      { EmitLn('MOVE D0,-(SP)'); }
      case Look of
       '=': Equals;
       '#': NotEquals;
       '<': Less;
       '>': Greater;
      end;
   EmitLn('cmp ' + IntToStr(sp) + '(%esp), $0');
   end;
end;

function NewLabel: string;
var S : string;
begin
   Str(LCount, S);
   NewLabel := 'L' + S;
   Inc(LCount);
end;

procedure PostLabel(L : string);
begin
   Write(L, ':');
end;

procedure Other;
begin
   EmitLn(GetName);
end;

procedure Block; Forward;

{ Parsing a Loop(with no condition) }
{ p -> loop }
{ e -> endloop }
procedure DoLoop;
var L1 : string;
begin
   Match('p');
   L1 := NewLabel;
   PostLabel(L1);
   Block;
   Match('e');
   EmitLn('jmp ' + L1);
end;

{ Parsing a 'while' construct }
{ w -> while }
{ e -> endwhile }
procedure DoWhile;
var L1 : string;
   L2  : string;
begin
   Match('w');
   L1 := NewLabel;
   PostLabel(L1);
   BoolExpression;
   L2 := NewLabel;
   EmitLn('jne ' + L2);
   Block;
   Match('e');
   EmitLn('jmp ' + L1);
   PostLabel(L2);
end;

{ Parsing a For loop construct }
{ f -> for }
{ e -> endfor }
{ Syntax: FOR <ident>:=<expr1> TO <expr2> <block> ENDFOR }
procedure DoFor;
var L1	: string;
   L2	: string;
begin
   Match('f');
   L1 := NewLabel;

   GetName;
   Match('=');

   Expression;
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');

   Expression;
   sp := sp - 4;
   EmitLn('movl %eax, ' + IntToStr(sp) + '(%esp)');

   PostLabel(L1);
   EmitLn('movl ' + IntToStr(sp + 4) + '(%esp), %eax');
   EmitLn('cmpl ' + IntToStr(sp) + '(%esp), %eax');
   L2 := NewLabel;
   EmitLn('jge ' + L2);

   Block;

   EmitLn('movl ' + IntToStr(sp + 4) + '(%esp), %eax');
   EmitLn('addl $1, %eax');
   EmitLn('movl %eax, ' + IntToStr(sp + 4) + '(%esp)');

   Match('e');
   EmitLn('jmp ' + L1);
   PostLabel(L2);

   { Cleanup }
   EmitLn('addl $8, (%esp)');
   sp := sp + 8;
end;

{ Parsing an 'if' construct }
{ i -> if }
{ l -> else }
{ e -> endif/end (depending on context) }
{ for example: }
{ aiblcede =>
               Statement a
               if <condition == true>
                    Statement b
               else
                    Statement c
               endif
               Statement d
               end
}
procedure DoIf;
var L1 : string;
   L2  : string;
begin
   Match('i');
   L1 := NewLabel;
   L2 := L1;
   BoolExpression;
   EmitLn('jne ' + L1);
   Block;

   if Look = 'l' then begin
      L2 := NewLabel;
      EmitLn('jmp ' + L2);

      Match('l');
      PostLabel(L1);
      Block;
   end;

   Match('e');
   PostLabel(L2);
end;


procedure Block;
begin
   while not(Look in ['e', 'l']) do begin
      case Look of
	'i' : DoIf;
	'w' : DoWhile;
	'p' : DoLoop;
	'f' : DoFor;
      else
	Other;
      end;
   end;
end;

procedure DoProgram;
begin
   Block;
   if Look <> 'e' then Expected('End');
   EmitLn('End')
end;

{ Main Program }

begin
   sp := 0;
   Init;
   DoProgram;
end.
