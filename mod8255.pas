/////////////////////////////////////////////////////////////////////////
//                                                                     //
//      Orion/Z (Orion-128 + Z80-CARD-II) emulator, version 1.9        //
//                                                                     //
//   Author: Sergey A.  <a-s-m@km.ru>                                  //
//                                                                     //
//   Copyright (C) 2006-2016 Sergey A.                                 //
//                                                                     //
//   This program is free software; you can redistribute it and/or     //
//                  modify it in any ways.                             //
//   This program is distributed "AS IS" in the hope that it will be   //
//   useful, but WITHOUT ANY WARRANTY; without even the implied        //
//   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


unit mod8255;

{$MODE Delphi}

{***********************************************

    i8255 (580ÂB55) emulation

 ***********************************************}

interface

{$I 'OrionZEm.inc'}

Uses Windows, SysUtils, classes, modF600, Forms, mainwin;

type
  TKbdType = (RK86, MS7007spb, MS7007msk);
// RK86:      PA(0)=out, PB(1)=in,  hi(PC(2))=in: CC=D5, ÓÑ=D6, Ð/Ë=D7;  D3=out=èíä.Ð/Ë
// MS7007spb: PA(0)=out, PB(1)=in,  hi(PC(2))=in
// MS7007msk: PA(0)=in,  PB(1)=out, lo(PC(2))=out

const
// PC scan codes are in WinAPI GetKeyboardState routine format

KeyMatrixMCspb: array[0..7, 0..10] of byte =
{s D0} (( ord('0'),ord('9'),VK_NUMPAD6,VK_INSERT,   VK_END,  {?} $BF,  {-} $BD, {:} $BA, VK_NUMPAD9,VK_RETURN,VK_NUMPAD3),
{c D1}  ( ord('7'),ord('8'),     VK_F1,    VK_F2,    VK_F3,    VK_F4,    VK_F5,ord('4'), {num*}$6A, VK_ESCAPE, {+} $BB ),
{a D2}  ( {[}  $DB, {]} $DD,  ord('1'), ord('2'), ord('3'), ord('5'), ord('6'),ord('E'),VK_SUBTRACT,   VK_TAB, ord('J')),
{n D3}  ( ord('L'),ord('D'),  ord('C'), ord('U'), ord('K'), ord('N'), ord('G'),ord('P'),         0, VK_CAPITAL,ord('F')),
{c D4}  ( ord('B'),{Þ@} $C0,  ord('Y'), ord('W'), ord('A'), ord('R'), ord('O'),ord('I'),         0,         0, ord('Q')),
{o D5}  (  VK_LEFT, {<} $BC,   {'} $DE, ord('S'), ord('M'), ord('T'), ord('X'),VK_SPACE,  VK_SHIFT,VK_CONTROL,{ôèêñ=ÐóñLat}0),
{d D6}  (  {\} $DC,ord('V'),VK_NUMPAD4,   VK_ADD,  VK_BACK,  VK_DOWN,  {>}$BE, VK_RIGHT,VK_NUMPAD7,VK_NUMPAD0,VK_NUMPAD1),
{e D7}  ( ord('H'),ord('Z'),VK_NUMPAD5,{ÈÑÏ}VK_F6, VK_HOME,  VK_UP, VK_DIVIDE,VK_RETURN,VK_NUMPAD8, {num.}$6E,VK_NUMPAD2));
{result        D0      D1        D2         D3        D4        D5        D6       D7        CD5       CD6       CD7 }

KeyMatrixMCmsk: array[0..7, 0..10] of byte =  // true MC7007 layout
{r D0} ((  {num*}$6A,  VK_ESCAPE, {+} $BB  ,     VK_F1,    VK_F2,    VK_F3, ord('4'),    VK_F4,    VK_F5, ord('7'),ord('8')),
{e D1}  (VK_SUBTRACT,     VK_TAB, ord('J') ,  ord('1'), ord('2'), ord('3'), ord('E'), ord('5'), ord('6'), {[}  $DB, {]} $DD),
{s D2}  (          0, VK_CAPITAL, ord('F') ,  ord('C'), ord('U'), ord('K'), ord('P'), ord('N'), ord('G'), ord('L'),ord('D')),
{u D3}  (          0,          0, ord('Q') ,  ord('Y'), ord('W'), ord('A'), ord('I'), ord('R'), ord('O'), ord('B'),{Þ@} $C0),
{l D4}  (   VK_SHIFT, VK_CONTROL,{ôèêñ=RL}0,   {'} $DE, ord('S'), ord('M'), VK_SPACE, ord('T'), ord('X'),  VK_LEFT, {<} $BC),
{t D5}  ( VK_NUMPAD7, VK_NUMPAD0,VK_NUMPAD1,VK_NUMPAD4,   VK_ADD,  VK_BACK, VK_RIGHT,  VK_DOWN,   {>}$BE,  {\} $DC,ord('V')),
{  D6}  ( VK_NUMPAD8,  {num.}$6E,VK_NUMPAD2,VK_NUMPAD5,{ÈÑÏ}VK_F6, VK_HOME,VK_RETURN,    VK_UP,VK_DIVIDE, ord('H'),ord('Z')),
{  D7}  ( VK_NUMPAD9,  VK_RETURN,VK_NUMPAD3,VK_NUMPAD6,VK_INSERT,   VK_END,  {:} $BA,  {?} $BF,  {-} $BD, ord('0'),ord('9')));
{scancode      D0          D1        D2         D3        D4         D5        D6       D7        CD0       CD1       CD2 }

  KeyMatrixRK86: array [0..1, 0..7, 0..7] of byte =
      (((VK_HOME,VK_INSERT,  VK_ESCAPE,    VK_F1,    VK_F2,    VK_F3,    VK_F4,    VK_F5),  // D0  -
        (VK_TAB,    VK_END,  VK_RETURN,  VK_BACK,  VK_LEFT,    VK_UP, VK_RIGHT,  VK_DOWN),  // D1   \
        (ord('0'), ord('1'),  ord('2'), ord('3'), ord('4'), ord('5'), ord('6'), ord('7')),  // D2    \
        (ord('8'), ord('9'),   {:} $BA,  {+} $BB,  {<} $BC,  {-} $BD,  {>} $BE,  {?} $BF),  // D3     \
        ({Þ@} $C0, ord('A'),  ord('B'), ord('C'), ord('D'), ord('E'), ord('F'), ord('G')),  // D4     /  scan code
        (ord('H'), ord('I'),  ord('J'), ord('K'), ord('L'), ord('M'), ord('N'), ord('O')),  // D5    /
        (ord('P'), ord('Q'),  ord('R'), ord('S'), ord('T'), ord('U'), ord('V'), ord('W')),  // D6   /
        (ord('X'), ord('Y'),  ord('Z'),{ [ } $DB, {\} $DC, { ] } $DD, {'} $DE, VK_SPACE)),  // D7  -
//          D0        D1         D2        D3        D4        D5        D6        D7 -------------------> result
       ((       0,        0,         0,        0,       0,         0,   VK_NEXT,       0),
        (       0,        0,         0,        0,       0,         0,       0,         0),
        (VK_NUMPAD0,VK_NUMPAD1,VK_NUMPAD2,VK_NUMPAD3,VK_NUMPAD4,VK_NUMPAD5,VK_NUMPAD6,VK_NUMPAD7),
        (VK_NUMPAD8,VK_NUMPAD9,VK_MULTIPLY,VK_ADD, 0, VK_SUBTRACT, 0, VK_DIVIDE),
        (       0,        0,         0,        0,       0,         0,       0,         0),
        (       0,        0,         0,        0,       0,         0,       0,         0),
        (       0,        0,         0,        0,       0,         0,       0,         0),
        (       0,        0,         0,        0,       0,         0,       0,         0)));

type
  TRusLat = packed record
              name: string;
              code: integer;
            end;

const
  KBD_ADDR0  = $F400;
  ROMD_ADDR0 = $F500;
  ROM_PAGES_PORT = $FE;                                 // $FC  d0..d3 bits selects 16 ROM pages  
  MaxRusLat  = 2;
  KeyRusLatArr: array [0..MaxRusLat] of TRusLat =
       ((name: 'VK_F8';      code: VK_F8),
        (name: 'VK_F9';      code: VK_F9),
        (name: 'VK_SCROLL';  code: VK_SCROLL));

type
  T8255 = class(TObject)
    R: array [0..3] of byte;                                                 // Registers
    function GetData(Index: Integer): byte;               // emulate CPU reading from internal registers
    procedure SetData(Index: Integer; const Value: byte); // emulate CPU writing to internal registers
  protected
    function GetPort(Index: Integer): byte; virtual; abstract;               // interface with device
    procedure SetPort(Index: Integer; const Value: byte); virtual; abstract; // interface with device
    property Port[Index: Integer]:byte read GetPort write SetPort;
  public
    constructor Create; virtual;
    procedure Reset;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure ReadFromStream(Stream: TStream); virtual;
    property Registers[Index: Integer]:byte read GetData write SetData; default; // interface with CPU
  end;

  TPortF400 = class(T8255)                          // keyboard
    FPA, FPB, FPC: byte;
  private
    FKbdType: TKbdType;
    FLcdRusLat: boolean;
    procedure SetKbdType(const Value: TKbdType);
  protected
    function GetPort(Index: Integer): byte; override;                // interface with device
    procedure SetPort(Index: Integer; const Value: byte); override;  // interface with device
  public
    constructor Create; override;
    procedure SaveToStream(Stream: TStream);   override;
    procedure ReadFromStream(Stream: TStream); override;
    property KbdType:TKbdType read FKbdType write SetKbdType;
    property LcdRusLat:boolean read FLcdRusLat;
  end;

  TPortF500 = class(T8255)
    FAddrLo, FAddrHi: byte;                                          // PB, PC - address in ROMDISK
  protected
    function GetPort(Index: Integer): byte; override;                // interface with device
    procedure SetPort(Index: Integer; const Value: byte); override;  // interface with device
  public
    constructor Create; override;
    procedure SaveToStream(Stream: TStream);   override;
    procedure ReadFromStream(Stream: TStream); override;
  end;

  TPortF600 = class(T8255)
  private
    function GetPluginStr: string;
    procedure SetPluginStr(St: string);
  protected
    FIndex: integer;
    FPluginName: string;
    FPluginFunc: TF600Function;
    FDll: HMODULE;
    FAppParams: TApplicationParams;
    PAppParams: PApplicationParams;
    function GetPort(Index: Integer): byte; override;                // interface with device
    procedure SetPort(Index: Integer; const Value: byte); override;  // interface with device
    procedure FreePluginLibrary;
    function  MyAppParams:PApplicationParams;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure ConfigurePlugin;
    procedure Flush;
    property Plugin: string read GetPluginStr write SetPluginStr; // '"Plugin_full_file_name","Plugin_Function_Index"
    property FuncIdx: integer read FIndex write FIndex;
  end;

var
  PortF400: TPortF400;
  PortF500: TPortF500;
  PortF600: TPortF600;

  KEYBRD: TKeyboardState;  // array[0..255] of byte
  KeyDelay: integer;
  ROMDISK: array of byte;
  ROMDISKlen: integer;
  PFEEnabled: boolean = False;  // ROM-disk paging register
  KeyRusLat: integer  = VK_F8;
  KeybType: integer = 0;
  KeyExtender: Boolean = False;
  F600Plugin: String;           // '"Plugin_full_file_name","Plugin_Function_Index"
  F600Index: integer;

  InkeyQueue: string;

implementation

Uses modOrion;

{ T8255 }

function T8255.GetData(Index: Integer): byte;
var b1, b2: byte;
begin
  case Index of
    0: if (R[3] and $10 <>0)
         then Result:=Port[0]
         else Result:=R[0];
    1: if (R[3] and 2 <>0)
         then Result:=Port[1]
         else Result:=R[1];
    2: begin
         if (R[3] and 1 <>0)
           then b1:=Port[2] and $0F
           else b1:=R[2] and $0F;
         if (R[3] and 8 <>0)
           then b2:=Port[2] and $F0
           else b2:=R[2] and $F0;
         Result:=b1 or b2;
       end;
    3: Result:=R[3];
    else Result:=0;          // Invalid address
  end;
end;

procedure T8255.Reset;       // Initialize all registers and ports
begin
  R[0]:=0; Port[0]:=0;
  R[1]:=0; Port[1]:=0;
  R[2]:=0; Port[2]:=0;
  R[3]:=$9B;
end;

procedure T8255.SetData(Index: Integer; const Value: byte);
var b1, b2, V: byte;
begin
  case Index of
    0, 1, 2: R[Index]:=Value;        // Data registers
    3: if (Value and $80 <>0)        // Control register
       then R[Index]:=Value          // mode2
       else begin                    // mode1
         b1 := 1 shl ((Value and $0E) shr 1);
         if (Value and $01 <>0)
           then R[2] := R[2] or b1
           else R[2] := R[2] and (not b1);
       end
    else raise Exception.CreateFmt('Wrong i8255 register address: %d', [Index]);
  end;
{ Set output ports }
  V:=R[3];
  if (V and $10 <>0)
    then Port[0]:=0
    else Port[0]:=R[0];
  if (V and 2 <>0)
    then Port[1]:=0
    else Port[1]:=R[1];
  if (V and 1 <>0) then b1:=0 else b1:=R[2] and $0F;
  if (V and 8 <>0) then b2:=0 else b2:=R[2] and $F0;
  Port[2] := b1 or b2;
end;

constructor T8255.Create;
begin
  inherited;
end;

procedure T8255.ReadFromStream(Stream: TStream);
begin
  Stream.Read(R, sizeof(R));
end;

procedure T8255.SaveToStream(Stream: TStream);
begin
  Stream.Write(R, sizeof(R));
end;

{ TPortF400 }

constructor TPortF400.Create;   // PA(0)=out, PB(1)=in, hi(PC(2))=in
begin
  inherited;
  Reset;
  FKbdType := RK86;
end;

function TPortF400.GetPort(Index: Integer): byte;
var i, j: integer;
    xPA: byte;
    xPB: word;
    ctrl: byte;
 procedure KeyOn(scan: byte);
 begin
   KEYBRD[scan]:=(KEYBRD[scan] xor 1) or $80;
 end;
 procedure KeyOff(scan: byte);
 begin
   KEYBRD[scan]:=(KEYBRD[scan] {xor 1}) and 1;
 end;
 procedure CtrlQ(scan: byte; key: char);
 begin
//   KeyOff(scan); KeyOn(ord('Q')); KeyOn(VK_CONTROL);
//   insert(#31, InkeyQueue, 1);                         // delay
//   insert(key, InkeyQueue, 1);
//   insert(#31, InkeyQueue, 1);                         // delay
 end;
begin
  Result:=0;
  ctrl:=KEYBRD[VK_CONTROL];
  if Length(InkeyQueue)>0 then
  begin
    for i:=0 to sizeof(KEYBRD)-1 do KeyOff(KEYBRD[i]);
    if InkeyQueue[1]>=' ' then
      KeyOn(ord(InkeyQueue[1]))
    else
      if InkeyQueue[1]<#31 then begin
        KeyOn(VK_CONTROL);
        KeyOn(ord(InkeyQueue[1])+$40);
      end;
    delete(InkeyQueue, 1, 1);
    exit;
  end;
  if (KEYBRD[VK_PRIOR] and $80 <>0) then
  begin
    KeyOn(VK_CONTROL);
    KeyOn(ord('R'));                                  {PgUp=^R - for TurboPascal-style editors}
  end;
  if (KEYBRD[VK_DELETE] and $80 <>0) then
  begin
    KeyOn(VK_CONTROL);
    KeyOn(ord('G'));                                  {^G - delete symbol for TurboPascal-style editors}
  end;
  if KeyExtender then begin
    if (ctrl and $80 <>0) then begin                 // CTRL pressed
      if (KEYBRD[VK_LEFT] and $80 <>0) then begin       // ÊÓÐÑÎÐ ÍÀ ÑËÎÂÎ ÂËÅÂÎ:  CTRL-À
        KeyOff(VK_LEFT);  KeyOn(ord('A'));
      end;
      if (KEYBRD[VK_RIGHT] and $80 <>0) then begin      // ÊÓÐÑÎÐ ÍÀ ÑËÎÂÎ ÂÏÐÀÂÎ: CTRL-F
        KeyOff(VK_RIGHT); KeyOn(ord('F'));
      end;
      if (KEYBRD[VK_UP] and $80 <>0) then begin         // ÒÅÊÑÒ ÍÀ ÑÒÐÎÊÓ ÂÂÅÐÕ:  CTRL-Z
        KeyOff(VK_UP);    KeyOn(ord('Z'));
      end;
      if (KEYBRD[VK_DOWN] and $80 <>0) then begin       // ÒÅÊÑÒ ÍÀ ÑÒÐÎÊÓ ÂÍÈÇ:   CTRL-W
        KeyOff(VK_DOWN);  KeyOn(ord('W'));
      end;
      if (KEYBRD[VK_PRIOR] and $80 <>0) then            // ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÑÒÐÀÍÈÖÛ: CTRL-Q-E
        CtrlQ(VK_PRIOR, 'E');
      if (KEYBRD[VK_NEXT] and $80 <>0) then             // ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÑÒÐÀÍÈÖÛ:  CTRL-Q-Õ
        CtrlQ(VK_NEXT, 'X');
      if (KEYBRD[VK_HOME] and $80 <>0) then             // ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÔÀÉËÀ:    CTRL-Q-R
        CtrlQ(VK_HOME, 'R');
      if (KEYBRD[VK_END] and $80 <>0) then              // ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÔÀÉËÀ:     CTRL-Q-Ñ
        CtrlQ(VK_END, 'C');
    end
    else
    begin
      if (KEYBRD[VK_INSERT] and $80 <>0) then begin     // ÐÅÆÈÌ ÂÑÒÀÂÊÈ (âêë./âûêë.): CTRL-V
        KeyOff(VK_INSERT); KeyOn(ord('V'));
        KeyOn(VK_CONTROL);
      end;
      if (KEYBRD[VK_HOME] and $80 <>0) then             // ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÑÒÐÎÊÈ: CTRL-Q-S
        CtrlQ(VK_HOME, 'S');
      if (KEYBRD[VK_END] and $80 <>0) then              // ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÑÒÐÎÊÈ:  CTRL-Q-D
        CtrlQ(VK_END, 'D');
    end;
  end;  {KeyExtender}
  case FKbdType of
   RK86: begin
          case Index of
           1: begin
                Result:=$FF;
                xPA:=FPA;
                for i:=0 to 7 do
                  if (xPA and (1 shl i) =0) then
                    for j:=0 to 7 do
                      if (KEYBRD[KeyMatrixRK86[0, i, j]] and $80 <>0) or    // if main key pressed
                         (KEYBRD[KeyMatrixRK86[1, i, j]] and $80 <>0) then  // or numpad key pressed
                      begin
                        Result:=Result and (not (1 shl j));
                        if (KeyDelay>0) then sleep(KeyDelay);
                      end;
              end;
           2: begin  //CC=D5=0, ÓÑ=D6=0, Ð/Ë=D7=0 ; Ð/Ë=F12(tunable)
                Result:=$FF;
                if (KEYBRD[KeyRusLat] and $80 <>0) then
                  Result:=Result and $7F;                                         // 01111111
                if (KEYBRD[VK_SHIFT] and $80 <>0)
                  then Result:=Result and $DF;                                    // 11011111
                if (ctrl and $80 <>0)
                  then Result:=Result and $BF;                                    // 10111111
              end;
         end;
        end;
   MS7007spb:
     begin
          KeyMatrixMCspb[5,10]:=KeyRusLat;                          {"ÔÈÊÑ"=ÐóñLat}
          if (KEYBRD[VK_NEXT] and $80 <>0) then KEYBRD[VK_F4]:=$81; {PgDn=^C - for TurboPascal-style editors}
          Result:=$FF;
          xPA:=FPA;
          for i:=0 to 7 do
            if (xPA and (1 shl i) =0) then
            begin
              if Index=1 then
              begin
                for j:=0 to 7 do
                  if (KEYBRD[KeyMatrixMCspb[i, j]] and $80 <>0) then         // key pressed
                  begin
                    Result:=Result and (not (1 shl j));
                    if (KeyDelay>0) then sleep(KeyDelay);
                  end;
              end
              else if Index=2 then
                     for j:=5 to 7 do
                       if (KEYBRD[KeyMatrixMCspb[i, j+3]] and $80 <>0) then  // key pressed
                       begin
                         Result:=Result and (not (1 shl j));
                         if (KeyDelay>0) then sleep(KeyDelay);
                       end

            end;
     end;
   MS7007msk:
     if Index=0 then
     begin
          KeyMatrixMCmsk[4,2]:=KeyRusLat;                          {"ÔÈÊÑ"=ÐóñLat}
          Result:=$FF;
          xPB:=word(FPB) or (word(FPC and 7)shl 8);
          for j:=0 to 10 do
            if (xPB and (1 shl j) =0) then
            begin
              for i:=0 to 7 do
                if (KEYBRD[KeyMatrixMCmsk[i, j]] and $80 <>0) then  // key pressed
                begin
                  Result:=Result and (not (1 shl i));
                  if (KeyDelay>0) then sleep(KeyDelay);
                end;
            end;
     end;
  end;
//  KEYBRD[VK_CONTROL]:=ctrl;
end;

procedure TPortF400.ReadFromStream(Stream: TStream);
begin
  inherited;
  Stream.Read(FPA, sizeof(FPA));
  Stream.Read(FPB, sizeof(FPB));
  Stream.Read(FPC, sizeof(FPC));
  Stream.Read(FKbdType, sizeof(FKbdType));
  Stream.Read(FLcdRusLat, sizeof(FLcdRusLat));
end;

procedure TPortF400.SaveToStream(Stream: TStream);
begin
  inherited;
  Stream.Write(FPA, sizeof(FPA));
  Stream.Write(FPB, sizeof(FPB));
  Stream.Write(FPC, sizeof(FPC));
  Stream.Write(FKbdType, sizeof(FKbdType));
  Stream.Write(FLcdRusLat, sizeof(FLcdRusLat));
end;

procedure TPortF400.SetKbdType(const Value: TKbdType);
begin
  FKbdType := Value;
end;

procedure TPortF400.SetPort(Index: Integer; const Value: byte);
begin
  case Index of
    0: FPA:=Value;
    1: FPB:=Value;
    2: begin
         FLcdRusLat:=(Value and 8)<>0;
         FPC:=Value;
       end;
  end;
end;

{ TPortF500 }

constructor TPortF500.Create;  // PB(1), PC(2) - out (address:lo,hi), PA(0) - in (data)
begin
  inherited;
  Reset;
end;

function TPortF500.GetPort(Index: Integer): byte;
var Addr: integer;
begin
  case Index of
    0: begin
         Addr:=FAddrHi * $100 + FAddrLo;
         if PFEEnabled and (Z80CardMode<>Z80_ORIONPRO_v2) and (Z80CardMode<>Z80_ORIONPRO_v3) then
           Addr:=Addr + ($10000 * MainPort[ROM_PAGES_PORT]);
         if (Addr>=Length(ROMDISK)-1) then Result:=$FF
         else Result:=ROMDISK[Addr];
       end;
    else Result:=0;
  end;
end;

procedure TPortF500.ReadFromStream(Stream: TStream);
begin
  inherited;
  Stream.Read(FAddrLo, sizeof(FAddrLo));
  Stream.Read(FAddrHi, sizeof(FAddrHi));
end;

procedure TPortF500.SaveToStream(Stream: TStream);
begin
  inherited;
  Stream.Write(FAddrLo, sizeof(FAddrLo));
  Stream.Write(FAddrHi, sizeof(FAddrHi));
end;

procedure TPortF500.SetPort(Index: Integer; const Value: byte);
begin
  case Index of
    1: FAddrLo:=Value;
    2: FAddrHi:=Value;
  end;
end;

{ TPortF600 }                  // customized port (based on plugin selected by user )

constructor TPortF600.Create;
begin
  inherited;
  Reset;
  FDll:=0;
  FIndex:=-1;
  FPluginName:='';
  FPluginFunc:=nil;
end;

destructor TPortF600.Destroy;
begin
  inherited;
  FPluginFunc:=nil;
  FreePluginLibrary;
end;

procedure TPortF600.FreePluginLibrary;
begin
  If FDll=0 then exit;
  if Assigned(FPluginFunc) then begin
    MyAppParams;
    FPluginFunc(FIndex, F600Func_UnLoad, pointer(PAppParams));
  end;
  FreeLibrary(FDll);
  FDll:=0;
  FIndex:=-1;
  FPluginName:='';
  FPluginFunc:=nil;
end;

function TPortF600.GetPort(Index: Integer): byte;
begin
  if not Assigned(FPluginFunc) then
    Result:=0
  else begin
    MyAppParams;
    case Index of
      0: Result:=lo(FPluginFunc(FIndex, F600Func_PA_in, pointer(PAppParams)));
      1: Result:=lo(FPluginFunc(FIndex, F600Func_PB_in, pointer(PAppParams)));
      2: Result:=lo(FPluginFunc(FIndex, F600Func_PC_in, pointer(PAppParams)));
      else Result:=0;
    end;
  end;
end;

function TPortF600.MyAppParams: PApplicationParams;
begin
  with FAppParams do begin
    AppHandle:=Application.Handle;
    aIcon:=Application.Icon.Handle;
    MainInstance:=hInstance;
    Wnd:=frmMain.Handle;
  end;
  PAppParams:=@FAppParams;
end;

procedure TPortF600.ConfigurePlugin;
begin
  MyAppParams;
  if Assigned(FPluginFunc) and (FIndex>=0) then
    FPluginFunc(FIndex, F600Func_Configure, pointer(PAppParams));
end;

procedure TPortF600.SetPluginStr(St: string);               // '"Plugin_full_file_name","Plugin_Function_Index"
var
  xDll: HMODULE;
  xPluginFunc: TF600Function;
begin
  st:=AnsiUpperCase(trim(st));
  if st=FPluginName then
      exit
  else if st='' then
       begin
         FreePluginLibrary;
         exit;
       end;
  if not FileExists(st) then
    raise Exception.CreateFmt('Plugin file not found:'#13#10#10'`%s`', [st])
  else begin
    xDll:=LoadLibrary(PChar(st));
    if xDll=0 then
      raise Exception.CreateFmt('Error during loading Plugin:'#13#10#10'`%s`', [st])
    else begin
      xPluginFunc:=GetProcAddress(xDll, F600FuncName);
      if not Assigned(xPluginFunc) then begin
        FreeLibrary(xDll);
        raise Exception.CreateFmt('Error obtainig entry point `%s` in Plugin:'#13#10#10'`%s`', [F600FuncName, st])
      end
      else begin
        FreePluginLibrary;
        FDll:=xDll;
        FPluginFunc:=xPluginFunc;
        FPluginName:=st;
        MyAppParams;
        FPluginFunc(FIndex, F600Func_Load, pointer(PAppParams));
      end;
    end;
  end;
end;

procedure TPortF600.SetPort(Index: Integer; const Value: byte);
var pch: PChar;
begin
  if not Assigned(FPluginFunc) then
    exit
  else begin
    pch:=@Value;
    case Index of
      0: FPluginFunc(FIndex, F600Func_PA_out, pointer(pch));
      1: FPluginFunc(FIndex, F600Func_PB_out, pointer(pch));
      2: FPluginFunc(FIndex, F600Func_PC_out, pointer(pch));
      3: FPluginFunc(FIndex, F600Func_PD_out, pointer(pch));
    end;
  end;
end;

function TPortF600.GetPluginStr: string;
begin
  Result:=FPluginName;
end;

procedure TPortF600.Flush;
begin
  if Assigned(FPluginFunc) then begin
    MyAppParams;
    FPluginFunc(FIndex, F600Func_Flush, pointer(PAppParams));
  end;
end;

initialization
  InkeyQueue:='';
  PortF400:=TPortF400.Create;
  PortF500:=TPortF500.Create;
  PortF600:=TPortF600.Create;

finalization
  PortF400.Free;
  PortF500.Free;
  PortF600.Free;

end.


{
   TURBO PASCAL KEYSTROKES
   -----------------------

   ÊÓÐÑÎÐ ÍÀ ÑÈÌÂÎË ÂËÅÂÎ                 <--                 CTRL-S
         Ïåðåìåùàåò êóðñîð íà ñèìâîë âëåâî â ïðåäåëàõ ñòðîêè.
   ÊÓÐÑÎÐ ÍÀ ÑÈÌÂÎË ÂÏÐÀÂÎ                -->                 CTRL-D
         Ïåðåìåùàåò êóðñîð íà ñèìâîë âïðàâî â ïðåäåëàõ ñòðîêè.
   ÊÓÐÑÎÐ ÍÀ ÑËÎÂÎ ÂËÅÂÎ                  ESC <--             CTRL-À
         Ïåðåìåùàåò êóðñîð âëåâî ê íà÷àëó ïðåäûäóùåãî ñëîâà. Ïîä ñëîâîì
       ïîíèìàåòñÿ  ïîñëåäîâàòåëüíîñòü  ñèìâîëîâ,  îãðàíè÷åííàÿ ïðîáåëîì
       èëè ëþáûì èç ñëåäóþùèõ ñèìâîëîâ: < > , ; . ( ) ^ ' * + - / $
       è ïðîáåëîì.
   ÊÓÐÑÎÐ ÍÀ ÑËÎÂÎ ÂÏÐÀÂÎ                 ESC -->             CTRL-F
         Ïåðåìåùàåò  êóðñîð  âïðàâî  ê  íà÷àëó ñëåäóþùåãî ñëîâà (ñìîòðè
       ïðåäûäóùóþ êîìàíäó).
   ÊÓÐÑÎÐ ÍÀ ÑÒÐÎÊÓ ÂÂÅÐÕ                 |                   CTRL-Å
         Ïåðåìåùàåò  êóðñîð íà îäíó ñòðîêó ââåðõ. Åñëè êóðñîð íàõîäèòñÿ
       â  âåðõíåé  ñòðîêå  ýêðàíà,  âåñü  òåêñò ñäâèãàåòñÿ âíèç íà îäíó
       ñòðîêó.
   ÊÓÐÑÎÐ ÍÀ ÑÒÐÎÊÓ ÂÍÈÇ                  |                   CTRL-Õ
         Ïåðåìåùàåò êóðñîð íà îäíó ñòðîêó âíèç. Åñëè êóðñîð íàõîäèòñÿ â
       íèæíåé  ñòðîêå  ýêðàíà,  âåñü  òåêñò  ñäâèãàåòñÿ  ââåðõ  íà îäíó
       ñòðîêó.
  ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÑÒÐÎÊÈ                                     CTRL-Q-S
         Ïåðåìåùàåò êóðñîð â ïåðâóþ ïîçèöèþ òåêóùåé ñòðîêè.
  ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÑÒÐÎÊÈ                                      CTRL-Q-D
         Ïåðåìåùàåò  êóðñîð  â ïîçèöèþ, ñëåäóþùóþ çà ïîñëåäíèì çíà÷àùèì
       ñèìâîëîì  â  ñòðîêå (ïðîáåëû â êîíöå ñòðîêè âñåãäà óäàëÿþòñÿ äëÿ
       ýêîíîìèè ïàìÿòè).
  ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÑÒÐÀÍÈÖÛ                                   CTRL-Q-E
         Ïåðåìåùàåò êóðñîð â âåðõíþþ ñòðîêó ýêðàíà.
  ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÑÒÐÀÍÈÖÛ                                    CTRL-Q-Õ
         Ïåðåìåùàåò êóðñîð â íèæíþþ ñòðîêó ýêðàíà.
  ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÔÀÉËÀ                  ESC - |             CTRL-Q-R
         Ïåðåìåùàåò êóðñîð ê ïåðâîìó ñèìâîëó òåêñòà.
  ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÔÀÉËÀ                   ESC - |             CTRL-Q-Ñ

         Ïåðåìåùàåò êóðñîð ê ïîñëåäíåìó ñèìâîëó òåêñòà.
  ÊÓÐÑÎÐ Â ÍÀ×ÀËÎ ÁËÎÊÀ                                      CTRL-Q-B
         Ïåðåìåùàåò  êóðñîð  â  ïîçèöèþ,  îòìå÷åííóþ êàê "íà÷àëî áëîêà"
       êîìàíäîé  ÎÒÌÅÒÈÒÜ  ÍÀ×ÀËÎ  ÁËÎÊÀ.  Êîìàíäà  âûïîëíÿåòñÿ è â òîì
       ñëó÷àå,  êîãäà èíäèêàöèÿ áëîêà îòêëþ÷åíà èëè êîãäà íå îïðåäåëåíà
       ïîçèöèÿ "êîíåö áëîêà".
  ÊÓÐÑÎÐ Â ÊÎÍÅÖ ÁËÎÊÀ                                       CTRL-Q-K
         Ïåðåìåùàåò  êóðñîð  â  ïîçèöèþ,  îòìå÷åííóþ  êàê "êîíåö áëîêà"
       êîìàíäîé  ÎÒÌÅÒÈÒÜ  ÊÎÍÅÖ  ÁËÎÊÀ.  Êîìàíäà  âûïîëíÿåòñÿ  è â òîì
       ñëó÷àå, êîãäà èíäèêàöèÿ áëîêà îòêëþ÷åíà, èëè êîãäà íå îïðåäåëåíà
       ïîçèöèÿ "íà÷àëî áëîêà".
  ÊÓÐÑÎÐ Â ÏÐÅÄÛÄÓÙÓÞ ÏÎÇÈÖÈÞ                                CTRL-Q-Ð
         Ïåðåìåùàåò  êóðñîð  â  ïîçèöèþ,  çàíèìàåìóþ  èì  äî âûïîëíåíèÿ
       ïðåäûäóùåé   îïåðàöèè.   Ýòîé   êîìàíäîé   â  ÷àñòíîñòè,  óäîáíî
       ïîëüçîâàòüñÿ ïîñëå âûïîëíåíèÿ êîìàíäû ÍÀÉÒÈ, (ÍÀÉÒÈ È ÇÀÌÅÍÈÒÜ),
       êîìàíäû ÇÀÏÈÑÜ ÍÀ ÄÈÑÊ îñíîâíîãî ìåíþ è ò.ä.
  ÒÅÊÑÒ ÍÀ ÑÒÐÎÊÓ ÂÂÅÐÕ                                      CTRL-Z
         Òåêñò  íà  ýêðàíå  ñäâèãàåòñÿ  íà  îäíó  ñòðîêó  ââåðõ. Êóðñîð
       îñòàåòñÿ íà òîé æå ñòðîêå òåêñòà.
  ÒÅÊÑÒ ÍÀ ÑÒÐÎÊÓ ÂÍÈÇ                                       CTRL-W
         Òåêñò  íà  ýêðàíå  ñäâèãàåòñÿ  íà  îäíó  ñòðîêó  âíèç.  Êóðñîð
       îñòàåòñÿ íà òîé æå ñòðîêå òåêñòà.
  ÒÅÊÑÒ ÍÀ ÑÒÐÀÍÈÖÓ ÂÂÅÐÕ                                    CTRL-C
         Òåêñò   ôàéëà   ñäâèãàåòñÿ   íà  ñòðàíèöó  ââåðõ  îòíîñèòåëüíî
       ôðàãìåíòà,  îòîáðàæåííîãî  íà ýêðàíå. Ðàçìåð ñòðàíèöû íà åäèíèöó
       ìåíüøå,  ÷åì  êîëè÷åñòâî  èíôîðìàöèîííûõ  ñòðîê íà ýêðàíå. Òàêèì
       îáðàçîì, ïîñëå âûïîëíåíèÿ êîìàíäû íà ýêðàíå îñòàåòñÿ îäíà ñòðîêà
       îò ïðåäûäóùåãî ôðàãìåíòà òåêñòà.
  ÒÅÊÑÒ ÍÀ ÑÒÐÀÍÈÖÓ ÂÍÈÇ                                     CTRL-R
         Òåêñò   ôàéëà   ñäâèãàåòñÿ   íà   ñòðàíèöó  âíèç  îòíîñèòåëüíî
       ôðàãìåíòà,  îòîáðàæåííîãî  íà ýêðàíå. Ðàçìåð ñòðàíèöû íà åäèíèöó
       ìåíüøå,  ÷åì  êîëè÷åñòâî  èíôîðìàöèîííûõ  ñòðîê íà ýêðàíå. Òàêèì
       îáðàçîì, ïîñëå âûïîëíåíèÿ êîìàíäû íà ýêðàíå îñòàåòñÿ îäíà ñòðîêà
       îò ïðåäûäóùåãî ôðàãìåíòà òåêñòà.

                        2. ÊÎÌÀÍÄÛ ÂÑÒÀÂÊÈ È ÓÄÀËÅÍÈß

         2.1  Â  ýòó  ãðóïïó  âõîäÿò  êîìàíäû, îáåñïå÷èâàþùèå âñòàâêó è
       óäàëåíèå  ñèìâîëîâ,  ñëîâ  è  ñòðîê.  Êðîìå  òîãî, ñþäà îòíåñåíà
       êîìàíäà   óïðàâëåíèÿ  ðåæèìîì  âñòàâêè  è  êîìàíäà,  ïîçâîëÿþùàÿ
       âîññòàíîâèòü  ñêîððåêòèðîâàííóþ  ñòðîêó, îòìåíèâ ñäåëàííûå â íåé
       èçìåíåíèÿ.

   ÐÅÆÈÌ ÂÑÒÀÂÊÈ (âêë./âûêä.)             INS                 CTRL-V
         Ââîä  òåêñòà  ïðè  ðàáîòå  ñ ðåäàêòîðîì ìîæåò îñóùåñòâëÿòüñÿ â
       îäíîì  èç  äâóõ  ðåæèìîâ:  ðåæèìå  âñòàâêè  èëè ðåæèìå çàìåùåíèÿ
       òåêñòà. Åñëè óñòàíîâëåí ðåæèì âñòàâêè, î÷åðåäíîé ââîäèìûé ñèìâîë
       ïîìåùàåòñÿ  â  ïîçèöèþ,  íà  êîòîðóþ óêàçûâàåò êóðñîð, à ñèìâîë,
       êîòîðûé  íàõîäèëñÿ â ýòîé ïîçèöèè, è âñå ñèìâîëû â ñòðîêå ñïðàâà
       îò  íåãî  ñäâèãàþòñÿ  íà îäíó ïîçèöèþ âïðàâî. Â ðåæèìå çàìåùåíèÿ
       î÷åðåäíîé  ââîäèìûé ñèìâîë çàìåùàåò ñèìâîë, íàõîäÿùèéñÿ â òîé æå
       ïîçèöèè, íà êîòîðóþ óêàçûâàåò êóðñîð.
       Â ñòðîêå ñîñòîÿíèÿ ïðèñóòñòâóåò èíäèêàöèÿ óñòàíîâëåííîãî ðåæèìà.
       Ïðè   âûçîâå   ðåäàêòîðà   ïî  óìîë÷àíèþ  óñòàíàâëèâàåòñÿ  ðåæèì
       âñòàâêè.
}
