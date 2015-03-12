
{ Constant Declarations }

const TAB	     = ^I;
   CR		     = #10;
   LF		     = #13;
   KWcode: string[5] = 'xilee';	{ Keyword Codes }

{ Type Declarations  }

type Symbol = string[8];
   SymTab   = array[1..1000] of Symbol;
   TabPtr   = ^SymTab;

{ Variable Declarations }

var Look : char;              { Lookahead Character }
   Token : char;	       { Current Token}
   Value : String[16];	       { String Token of 'Look'}

{ Definition of Keywords and Token Types }

const KWlist: array [1..4] of Symbol =
              ('IF', 'ELSE', 'ENDIF', 'END');

{ Table Lookup }

{ If the input string matches a table entry, return the entry
  index.  If not, return a zero.  }

function Lookup(T: TabPtr; s: string; n: integer): integer;
var i: integer;
    found: boolean;
begin
   found := false;
   i := n;
   while (i > 0) and not found do
      if s = T^[i] then
         found := true
      else
         dec(i);
   Lookup := i;
end;

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

procedure GetName;
begin
   Value := '';
   if not IsAlpha(Look) then Expected('Name');
   while IsAlNum(Look) do begin
     Value := Value + UpCase(Look);
     GetChar;
   end;
   Token := KWcode[Lookup(Addr(KWlist), Value, 4) + 1]
end;

{ Get a Number }

procedure GetNum;
begin
   Value := '';
   if not IsDigit(Look) then Expected('Integer');
   while IsDigit(Look) do begin
     Value := Value + Look;
     GetChar;
   end;
   Token := '#'
end;

{ Get an Operator }
procedure GetOp;
begin
   Value := '';
   if not IsOp(Look) then Expected('Operator');
   while IsOp(Look) do begin
      Value := Value + Look;
      GetChar;
   end;
   if Length(Value) = 1 then
      Token := Value[1]
   else
      Token := '?';
end;

{ A Lexical Scanner }

procedure Scan;
var k : integer;
begin
   { Ensure that CR/LF are skipped }
   while Look = CR do
      Fin;

   if IsAlpha(Look) then
      GetName
   else if IsDigit(Look) then
      GetNum
   else if IsOp(Look) then
      GetOp
   else begin
      Value := Look;
      Token := '?';
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
      Scan;
      case Token of
	'x'	      : write('Ident ');
	'#'	      : Write('Number ');
	'i', 'l', 'e' : Write('Keyword ');
        else Write('Operator ');
      end;
      Writeln(Value);
   until Value = 'END';
end.
