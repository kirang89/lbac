
{ Constant Declarations }

const TAB = ^I;
   CR	  = #10;
   LF	  = #13;

{ Type Declarations  }

type Symbol = string[8];
   SymTab   = array[1..1000] of Symbol;
   TabPtr   = ^SymTab;
   SymType  = (IfSym, ElseSym, EndifSym,
	       EndSym, Ident, Number, Op);

{ Variable Declarations }

var Look : char;              { Lookahead Character }
   Token : SymType;	       { Current Token}
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

procedure Scan;
var k : integer;
begin
   { Ensure that CR/LF are skipped }
   while Look = CR do
      Fin;

   if IsAlpha(Look) then
   begin
      Value := GetName;
      k := Lookup(Addr(KWlist), Value, 4);
      if k = 0 then
	 Token := Ident
      else
	 Token := SymType(k - 1);
   end
   else if IsDigit(Look) then
   begin
      Value := GetNum;
      Token := Number;
   end
   else if IsOp(Look) then
   begin
      Value := GetOp;
      Token := Op;
   end
   else begin
      Value := Look;
      Token := Op;
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
	Ident				 : write('Ident ');
	Number				 : write('Number ');
	Op				 : write('Operator ');
	IfSym, ElseSym, Endifsym, EndSym : write('Keyword ');
      end;
      WriteLn(Value);
   until Token = EndSym;
end.
