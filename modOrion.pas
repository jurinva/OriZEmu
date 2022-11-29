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


unit modOrion;

{$MODE Delphi}

{ *******************************************************************************

  O R I O N     S P E C I F I C

  *******************************************************************************}

interface


{$I 'OrionZEm.inc'}


uses windows, classes, sysutils, modAY8912, EthThrd;

const
  TSTATES_2M5=49920;       SPEED_2M5=0; SIZE_128=0;
  TSTATES_3M5=69888;       SPEED_3M5=1; SIZE_256=1;
  TSTATES_5M0=99840;       SPEED_5M0=2; SIZE_512=2;
  TSTATES_7M0=139776;      SPEED_7M0=3; SIZE_1024=3;
  TSTATES_10M=199680;      SPEED_10M=4; SIZE_2048=4;
  TSTATES_20M=199680*2;    SPEED_20M=5; SIZE_4096=5;
  TSTATES_inf=TSTATES_20M; SPEED_INF=6;

  Z80CARD_MOSCOW=0;
  Z80CARD_MINIMAL=1;
  Z80CARD_USUAL=2;
  Z80CARD_MAXIMAL=3;
  Z80_ORIONPRO_v2=4;
  Z80_ORIONPRO_v3=5;
  Z80_ORIONPRO_v320=6;

  ORION_ROMBIOS_ADDR = $F800;
  ORIONPRO_ROM1BIOS_ADDR = $0;
  ORIONPRO_ROM2BIOS_ADDR = $2000;
  RAM_PAGES_CNT    = 64;                               // êîëè÷åñòâî 64ê-ñòðàíèö ÎÇÓ â ïðåäåëå
  RAM_PAGE_SIZE      = 65536;

  pFB_disp_off = $80;     // äèñïåò÷åð 16ê âûêëþ÷åí  (D7=1)
  pFB_int50_off = 0;      // ïðåðûâàíèÿ âûêëþ÷åíû    (D6=0)
  pFB_TopRam_off = 0;     // F400..FFFF - ïîðòû+ÏÇÓ  (D5=0)

  pFB_disp_on = 0;        // äèñïåò÷åð 16ê âêëþ÷åí  (D7=1)
  pFB_int50_on = $40;     // ïðåðûâàíèÿ âêëþ÷åíû    (D6=0)
  pFB_TopRam_on = $20;    // F400..FFFF - OÇÓ       (D5=0)

  pFB_disp_mask = $80;    // D7
  pFB_int50_mask = $40;   // D6
  pFB_TopRam_mask = $20;  // D5

  p0A_RAM0_MASK = $01;    // RAM window 0000..3FFF
  p0A_RAM1_MASK = $02;    // RAM window 4000..7FFF
  p0A_RAM2_MASK = $04;    // RAM window 8000..BFFF
  p0A_ROM2_MASK = $08;    // ROM window 2000..3FFF
  p0A_ROM1_MASK = $10;    // ROM window 0000..1FFF
  p0A_FIX_F000  = $40;    // if  p0A_FIX_F000 (D6) = 1  then RAM  F000..FFFF = 1F segment 4k part always (with any pF9 combinations)
  p0A_ORION_128 = $80;    // if  p0A_ORION_128 (D7=1) then RAM  F000..FFFF = 1F segment 4k part always (with any p0A_FIX_F000, pF9 combinations)

  F_C = 1;
  F_N = 2;
  F_PV = 4;
  F_3 = 8;
  F_H = 16;
  F_5 = 32;
  F_Z = 64;
  F_S = 128;
  Z80RUNNING=1;       //Normally
  Z80PAUSED=2;        //When in setting screens
  Z80STOPPED=3;       //When losing focus

  CPUTstates: array [0..6] of integer =
    (TSTATES_2M5, TSTATES_3M5, TSTATES_5M0, TSTATES_7M0, TSTATES_10M, TSTATES_20M, TSTATES_inf);

  ScrBase: array [0..3] of integer = ($C000, $8000, $4000, 0);

  SCR_WIDTH_384 = 0;
  SCR_WIDTH_400 = 1;
  SCR_WIDTH_480 = 2;
  SCR_WIDTH_512 = 3;   { Orion-Pro wide screen }

  SCR_ZOOM_X1  = 0;
  SCR_ZOOM_X2  = 1;
  SCR_ZOOM_X25 = 2;
  SCR_ZOOM_X3  = 3;

  ScrWidthArr: array [0..3, 0..3] of integer = ((384, 384*2, 960, 384*3),
                                                (400, 400*2, 1000, 400*3),
                                                (480, 480*2, 1200, 480*3),
                   { Orion-Pro wide screen }    (512, 512*2, 1280, 512*3));
  ScrHeightArr: array [0..3] of integer = (256, 256*2, 640, 256*3);
  SzRAMarr: array [SIZE_128..SIZE_4096] of integer = (65536*2, 65536*4, 65536*8, 65536*16, 65536*32, 65536*64);
type
  TScrWidth = (w384, w400, w480);

  WordPointer=^Word;
  TMainPort = array [0..$FF] of byte;
  TROMF800  = array [$F800..$10000] of byte;
  TROM1BIOS = array [$0..$10000] of byte;
  TROM2BIOS = array [$0..$200000] of byte;
  TRamArr   = array [0..RAM_PAGES_CNT-1, 0..RAM_PAGE_SIZE] of byte;

  TOriHeader = packed record                        // snapshot header
                 _tag: array[0..22] of char;
                 _regA: integer;
                 _regHL: integer;
                 _regB: integer;
                 _regC: integer;
                 _regDE: integer;
  // Z80 Flags
                 _fS: Boolean;
                 _fZ: Boolean;
                 _f5: Boolean;
                 _fH: Boolean;
                 _f3: Boolean;
                 _fPV: Boolean;
                 _fN: Boolean;
                 _fC: Boolean;
  // Alternate registers
                 _regAF_: integer;
                 _regHL_: integer;
                 _regBC_: integer;
                 _regDE_: integer;
  // Index registers  - ID used as temp for ix/iy
                 _regIX: integer;
                 _regIY: integer;
                 _regID: integer;
  // Stack pointer and program counter
                 _regSP: integer;
                 _regPC: integer;
  // Interrupt registers and flip-flops, and refresh registers
                 _intI: integer;
                 _intR: integer;
                 _intRTemp: integer;
                 _intIFF1: Boolean;
                 _intIFF2: Boolean;
                 _intIM: integer;
  // 512âè1
                 _DeltaDate: TDateTime;
                 _DeltaTime: TDateTime;
  // keyboard
                 _KeyDelay: integer;
                 _KeyRusLat: integer;
// sound
                 _SoundEnabled: boolean;
                 _AyEnabled: boolean;
                 _Global_TStates: integer;
                 _glWavePtr: integer;
                 _glWaveAddTStates: integer;
                 _AYPSG: AY8912;
                 _AY_OutNoise: integer;
                 _VolA: integer;
                 _VolB: integer;
                 _VolC: integer;
                 _lOut1: integer;
                 _lOut2: integer;
                 _lOut3: integer;
                 _AY_Left: integer;
                 _AY_NextEvent: integer;
// other
                 _CPUSpeedMode: integer;
                 _MEMSizeMode: integer;
                 _Z80CardMode:integer;
                 _z80runstate: integer;
                 _glTstatesPerInterrupt: integer;
                 _KeybType: integer;                //sa
                 _KeyExtender: Boolean;
                 _FddHD: Boolean;
                 _HDDPort: integer;
                 _PFEEnabled:boolean;
                 _ROMBIOSfile: ShortString;
                 _ROMDISKfile: ShortString;
                 _ROMDISKlen: integer;          // ROM disk size in bytes
                 _NPages: integer;              // quantity of 64k RAM pages
                 _ScrZoom: integer;
                 _SDScheme: integer;
                 _Reserved: array[0..5] of integer;
               end;
// CRC: integer;                                // CRC32 of OriHeader
// _FDController.SaveToStream;
// _PortF400.SaveToStream;
// _PortF500.SaveToStream;
// _PortF600.SaveToStream;
// _F146818.SaveToStream;
// _Parity: array[0..256] of Boolean;
// _MainPort: TMainPort;
// _ROMF800: TROMF800;
// _ROMDISK: array of byte;        [0.._ROMDISKlen-1]
// _RAMARR:  array [0.._NPages-1, 0..65536] of byte


var
{$IFDEF DEBUG}
      PrevLocalTstates:integer = 0;
      TicksFromPrevSD:integer = 0;
{$ENDIF}
  DoNotUpdateScr:boolean = False;
  RAMPagesCount: integer = 8;
  RAMSegmCount: integer = 32;
  RAMarr: TRamArr;
  ROMF800: TROMF800;
  ROM1BIOS: TROM1BIOS;
  ROM2BIOS: TROM2BIOS;
  ROMBIOSlen, ROM1BIOSlen, ROM2BIOSlen: integer;
  ROMBIOSfile, ROM1BIOSfile, ROM2BIOSfile, ROMDISKfile: AnsiString;
  OrionPRO_DIP_SW: integer;

  MainPort: TMainPort;
  CheckPort: TMainPort;

  ScrWidth: integer = SCR_WIDTH_384;      // 0=SCR_WIDTH_384, 1=SCR_WIDTH_400, 2=SCR_WIDTH_480, 3=SCR_WIDTH_512
  ScrZoom: integer = SCR_ZOOM_X2;         // 0=SCR_ZOOM_X1,  1=SCR_ZOOM_X2,  3=SCR_ZOOM_X25,  4=SCR_ZOOM_X3
  PrevScrZoom: integer = SCR_ZOOM_X2;
  PrevScrWidth: integer = SCR_WIDTH_384;
  CpuPaused:boolean = False;
  DoShowReg:boolean = True;
  Do_Loop:boolean = False;

  BreakPointPF9:byte = $FF;
  BreakPointPF9mask: byte = 0;
  BreakPointAddr:integer = $FFFF;
  BreakPointAddrMask:integer = 0;
  BreakPointRetPF9:byte = $FF;
  BreakPointRetAddr:integer = $FFFF;

  AnalyzeConditions: boolean = False;

  ConditionSP:ShortString='';
  ConditionSPvalue:integer=0;
  ConditionSPmask:integer=0;

  ConditionAF:ShortString='';
  ConditionAFvalue:integer=0;
  ConditionAFmask:integer=0;
  ConditionBC:ShortString='';
  ConditionBCvalue:integer=0;
  ConditionBCmask:integer=0;
  ConditionDE:ShortString='';
  ConditionDEvalue:integer=0;
  ConditionDEmask:integer=0;
  ConditionHL:ShortString='';
  ConditionHLvalue:integer=0;
  ConditionHLmask:integer=0;

  ConditionAF_:ShortString='';
  ConditionAF_value:integer=0;
  ConditionAF_mask:integer=0;
  ConditionBC_:ShortString='';
  ConditionBC_value:integer=0;
  ConditionBC_mask:integer=0;
  ConditionDE_:ShortString='';
  ConditionDE_value:integer=0;
  ConditionDE_mask:integer=0;
  ConditionHL_:ShortString='';
  ConditionHL_value:integer=0;
  ConditionHL_mask:integer=0;

  ConditionIX:ShortString='';
  ConditionIXvalue:integer=0;
  ConditionIXmask:integer=0;
  ConditionIY:ShortString='';
  ConditionIYvalue:integer=0;
  ConditionIYmask:integer=0;
  ConditionIR:ShortString='';
  ConditionIRvalue:integer=0;
  ConditionIRmask:integer=0;

  Global_TStates: integer;
  z80runstate: integer;
  glTstatesPerInterrupt: integer;
  Parity: array[0..256] of Boolean;
  glInterruptTimer: integer;
  interruptCounter: integer = 0;
  glInterruptDelay: integer;
  glDelayOverage: integer;
  xSleep: integer = 0;            // ñêîëüêî ìèëèñåêóíä ïðîñïàëè â IDLE â òå÷åíèè ñåêóíäû
{$IFDEF USE_SOUND}
  glBeeperCounter: integer = 0;
  glBeeperVal: integer = 128;
  glSoundRegister: integer;       // Contains currently indexed AY-3-8912 sound register
  glBufNum: integer;              // ID of the last Wave buffer used
{$ENDIF}

  CPUSpeedMode:integer = SPEED_10M;  { 0=2M5, 1=3M5, 2=5M0, 3=7M0, 4=10M, 5=infinity }
  MEMSizeMode:integer = SIZE_512;
  Z80CardMode:integer = Z80CARD_MINIMAL;
  SoundEnabled: boolean = True;
  AyEnabled: boolean = True;
  RTCmode: integer=0;

  EthMode: integer;                  { 0=None, 1=RTL8019AS }
  EthConnName: string;               { TAP Connection name }
  EthConnGUID: string;               { TAP Connection GUID }
  EthMAC: TMacAddr;                  { Adapter MAC address }
  EthMAC0, EthMAC1, EthMAC2, EthMAC3, EthMAC4, EthMAC5: integer;

  // Main Z80 registers
  regA: integer;
  regHL: integer;
  regB: integer;
  regC: integer;
  regDE: integer;

  // Z80 Flags
  fS: Boolean;
  fZ: Boolean;
  f5: Boolean;
  fH: Boolean;
  f3: Boolean;
  fPV: Boolean;
  fN: Boolean;
  fC: Boolean;


  // Alternate registers
  regAF_: integer;
  regHL_: integer;
  regBC_: integer;
  regDE_: integer;

  // Index registers  - ID used as temp for ix/iy
  regIX: integer;
  regIY: integer;
  regID: integer;

  // Stack pointer and program counter
  regSP: integer;
  regPC: integer;
  prevPC:integer;

  // Interrupt registers and flip-flops, and refresh registers
  intI: integer;
  intR: integer;
  intRTemp: integer;
  intIFF1: Boolean;
  intIFF2: Boolean;
  intIM: integer;

procedure SetBeeper0;
procedure SetBeeper1;
function SetMemSize:string;
function LongAddressStr(page,addr:integer):string;
function LongAddressParse(ast:string; var page,addr:integer):integer;
function GetBeeper:integer;
function inb(port : integer) : integer;
procedure outb(port : integer; outbyte : integer);
function RAMPortGet(Index: Integer): byte;
procedure RAMPortSet(Index: Integer; const Value: byte);
function peekb(Index: Integer): byte;
function peekw(Index: Integer): word;
procedure pokew(Index: Integer; const Value: word);
procedure pokeb(Index: Integer; const Value: byte);
procedure DebugInfo(str: string; mode:integer);
function GetCPUTstates: integer;

implementation

uses mod1793, mod8255, mod146818, modHDD, modSD, mod232, mod8019as, MainWin;

{
   Ïîðò  F9 (F900) - Óïð.ñòðàíèöàìè ÎÇÓ äëÿ ðåæèìà "Îðèîí-128".

   Ïîðò  FB       - ÓÏÐÀÂËÅÍÈÅ  ÏÐÅÐÛÂÀÍÈßÌÈ  È  ÄÈÑÏÅÒ×ÅÐÎÌ:

   D7     D6     D5     D4     D3     D2     D1     D0
   !      !      !      !      !      !      !      !
   MZ    INT    XMEM   RZRV   BS1    BS0    SS1    SS0
   !      !      !      !      !      !      !      !
   !      !      !      !      !      !      !______!____ SEGMENT SELECT
   !      !      !      !      !______!__________________ BANK SELECT
   !      !      !      !
   !      !      !      !________ ÐÅÇÅÐÂ ÄËß BANK SELECT (ÂÑÅÃÄÀ = 0)
   !      !      !_______________ FULL RAM MEMORY (ÏÐÈ D5=1  0-FFFF - ÎÇÓ)
   !      !______________________ INT ENABLE (ÏÐÈ D6=0 ÇÀÏÐÅÙÅÍÛ)
   !_____________________________ DISPATCHER OFF (ÏÐÈ D7=1 ÎÒÊËÞ×ÅÍ !)


=================================== ORION - PRO ================================

Äëÿ âûáîðà íîìåðà ðàáî÷åé  (òåêóùåé)  ñòðàíèöû
èñïîëüçóåòñÿ  ïîðò  ñ  àäðåñîì  08H  (äëÿ  ðåæèìà "Îðèîí-128" -
0F900H). Âñå ñòðàíèöû ðàâíîñèëüíû, è íåò íåîáõîäèìîñòè ðàáîòàòü
èìåííî â íóëåâîé (òîëüêî äëÿ ðåæèìà Pro).  Â ðåæèìå "Îðèîí-128"
äëÿ ïåðåêëþ÷åíèÿ ñòðàíèö ÎÇÓ ìîæíî èñïîëüçîâàòü ïîðò ñ  àäðåñîì
0F9H.

        Ðàñïðåäåëåíèå ñåãìåíòîâ ïî ñòðàíèöàì îñíîâíîãî ÎÇÓ:

        Ñòð.0  Ñòð.1  Ñòð.2  Ñòð.3  Ñòð.4  Ñòð.5  Ñòð.6  Ñòð.7
FFFFH -------T------T------T------T------T------T------T------¬
      ¦   3  ¦   7  ¦  11  ¦  15  ¦  19  ¦  23  ¦  27  ¦  31  ¦
C000H +------+------+------+------+------+------+------+------+
      ¦   2  ¦   6  ¦  10  ¦  14  ¦  18  ¦  22  ¦  26  ¦  30  ¦
8000H +------+------+------+------+------+------+------+------+
      ¦   1  ¦   5  ¦   9  ¦  13  ¦  17  ¦  21  ¦  25  ¦  29  ¦
4000H +------+------+------+------+------+------+------+------+
      ¦   0  ¦   4  ¦   8  ¦  12  ¦  16  ¦  20  ¦  24  ¦  28  ¦
0000H L------¦------¦------¦------¦------¦------¦------¦-------


     Äîñòóï ê  ñåãìåíòàì ÎÇÓ îñóùåñòâëÿåòñÿ ÷åðåç òðè íåçàâèñè-
ìûõ îêíà,  êîòîðûå ìîæíî "îòêðûòü" â àäðåñíîì ïðîñòðàíñòâå ïðî-
öåññîðà â ïðåäåëàõ ðàáî÷åé ñòðàíèöû ÎÇÓ:

     Îêíî ÎÇÓ "RAM2"  - 8000-BFFFH
     Îêíî ÎÇÓ "RAM1"  - 4000-7FFFH
     Îêíî ÎÇÓ "RAM0"  - 0000-3FFFH

     Íàçíà÷åíèå ðàçðÿäîâ ïîðòà 0AH ñëåäóþùåå:

     D0 - 1 = âêëþ÷èòü îêíî ÎÇÓ "RAM0"
     D1 - 1 = âêëþ÷èòü îêíî ÎÇÓ "RAM1"
     D2 - 1 = âêëþ÷èòü îêíî ÎÇÓ "RAM2"
     D3 - âêëþ÷èòü îêíî ÏÇÓ "ROM2-BIOS"
     D4 - âêëþ÷èòü îêíî ÏÇÓ "ROM1-BIOS"
     D5 - âêëþ÷èòü òàêòîâóþ ÷àñòîòó ïðîöåññîðà 2.5 ÌÃö
     D6 - îòêëþ÷èòü  ïåðåêëþ÷åíèå ÎÇÓ 0F000H..0FFFFH  (â ðåæèìå
          "Orion-128" èãíîðèðóåòñÿ)
     D7 - âêëþ÷èòü ðåæèì "Orion-128" (îáëàñòü 0F000H..0FFFFH
          íåäîñòóïíà äëÿ çàïèñè).

     Äëÿ âûáîðà ñåãìåíòîâ â  êàæäîì  èç  îêîí  "RAM0",  "RAM1",
"RAM2"  â  êîìïüþòåðå  ïðåäóñìîòðåíû òðè ïîðòà ñ àäðåñàìè ñîîò-
âåòñòâåííî 04H,  05H, 06H, â êîòîðûå ìîãóò áûòü çàïèñàíû íîìåðà
ñåãìåíòîâ ÎÇÓ. Ïîðòû äèñïåò÷åðà 04H, 05H, 06H, 08H, 0AH äîñòóïíû
êàê äëÿ çàïèñè, òàê è äëÿ ÷òåíèÿ.

   Îáëàñòü ïàìÿòè 0F000H..0FFFFH â ðåæèìå  "Orion-Pro"  (ðàçðÿä
D7 ïîðòà 0AH óñòàíîâëåí â 0) äîñòóïíà êàê äëÿ ÷òåíèÿ, òàê è äëÿ çàïèñè.
Êðîìå òîãî, ïðîãðàììíî ìîæíî óñòàíîâèòü ðåæèì, ïðè êîòîðîì óêàçàííàÿ îáëàñòü
èëè ïåðåêëþ÷àåòñÿ âìåñòå ñ ïåðåêëþ÷åíèåì ñòðàíèö  (D6=0),  èëè  íå  ïåðåêëþ÷àåòñÿ
(D6=1) è ïðîåöèðóåò "âåðõíèå" 4ê ñåãìåíòà 31 (1Fh).
     Â ðåæèìå  "Orion-128" (ðàçðÿä D7 ïîðòà 0AH óñòàíîâëåí â 1)
óêàçàííàÿ îáëàñòü ïàìÿòè ÿâëÿåòñÿ íå  ïåðåêëþ÷àåìîé  íåçàâèñèìî
îò   çíà÷åíèÿ   ðàçðÿäà   D6,  ê  òîìó  æå  ÿ÷åéêè  ñ  àäðåñàìè
0F400H..0FA00H äîñòóïíû êàê ïîðòû (ïðè÷åì ïîðòû  0F800H..0FA00H
äîñòóïíû  òîëüêî  íà  çàïèñü,  òàê  êàê  ïðè  ÷òåíèè ïî àäðåñàì
0F800H..0FFFFH âêëþ÷àåòñÿ ÎÇÓ).

    Ïîñòîÿííàÿ ïàìÿòü, ðàñïîëîæåííàÿ íà îñíîâíîé ïëàòå, ñîñòîèò
èç äâóõ ÷àñòåé:

     "ROM1-BIOS" - ñòàðòîâîå ÏÇÓ îáúåìîì 8 Êáàéò;
     "ROM2-BIOS" - ÏÇÓ ïîëüçîâàòåëÿ îáúåìîì 8-64 Êáàéò.

     Äëÿ äîñòóïà  ê  ïîñòîÿííîé  ïàìÿòè â àäðåñíîì ïðîñòðàíñòâå
ïðîöåññîðà ïðåäóñìîòðåíî âêëþ÷åíèå ñîîòâåòñòâåííî äâóõ ROM-îêîí
ÏÇÓ.
     Îêíî äëÿ "ROM1-BIOS" âêëþ÷àåòñÿ  ïî  àäðåñàì  0000H..1FFFH
ïðè àïïàðàòíîì ñáðîñå êîìïüþòåðà,  òåì ñàìûì îáåñïå÷èâàÿ äîñòóï
ê ñòàðòîâûì è äðóãèì ïîäïðîãðàììàì.
     Äëÿ óïðàâëåíèÿ  âêëþ÷åíèåì  è âûêëþ÷åíèåì îêíà "ROM1-BIOS"
ïðåäíàçíà÷åí áèò D4 ïîðòà äèñïåò÷åðà 0AH.
     Âêëþ÷åíèåì îêíà "ROM2-BIOS" ïî àäðåñàì 2000H..3FFFH óïðàâ-
ëÿåò áèò D3 ïîðòà 0AH (íåçàâèñèìî îò îêíà "ROM1-BIOS"),  ïðè÷åì
äîñòóï  ê  ÏÇÓ â ýòîì îêíå îñóùåñòâëÿåòñÿ ïî ñåãìåíòàì ðàçìåðîì
8Êáàéò  (îòñþäà  è  ìèíèìàëüíûé  ðàçìåð  ÏÇÓ).  Íîìåð  ñåãìåíòà
"ROM2-BIOS" çàïèñûâàåòñÿ â ñïåöèàëüíûé ïîðò ñ àäðåñîì 09H,
äîïóñêàþùèé êàê çàïèñü, òàê è ÷òåíèå èíôîðìàöèè.
     Îêíà ÏÇÓ   èìåþò   ñàìûé   âûñîêèé  ïðèîðèòåò:  åñëè  îêíî
"ROM1-BIOS" è/èëè "ROM2-BIOS" âêëþ÷åíî,  òî äîñòóï ê íåìó îáåñ-
ïå÷èâàåòñÿ  èç ëþáîé òåêóùåé ñòðàíèöû,  â òîì ÷èñëå ïðè "îòêðû-
òîì" îêíå ÎÇÓ "RAM0".

                     3. ÏÎÐÒÛ ÂÂÎÄÀ-ÂÛÂÎÄÀ
                     ---------------------

     Â ðåæèìå  "Orion-128"  (áèò  D7  ïîðòà 0AH óñòàíîâëåí â 1)
ðàçðåøåí äîñòóï ê ïîðòàì 0F400H..0FA00H,  àäðåñóåìûì ÷åðåç  îá-
ëàñòü ïàìÿòè, è ê ïîðòàì 10H..14H, 18H..1BH, 0F8H..0FFH, à òàê-
æå ïîðòàì ïåðèôåðèè - ñ ïîìîùüþ êîìàíä ïðîöåññîðà IN, OUT.
     Â ðåæèìå  "Orion-Pro"  (áèò  D7  ïîðòà 0AH óñòàíîâëåí â 0)
äîñòóï ê ïîðòàì êàê ê ÿ÷åéêàì ÎÇÓ çàïðåùåí.

     Íàçíà÷åíèå ïîðòîâ:

     00H      - ñîñòîÿíèå DIP-ïåðåêëþ÷àòåëåé (SW), îïðåäåëÿþùèõ
                êîíôèãóðàöèþ ñèñòåìû;
     01H      - äàííûå ïðèíòåðà "Centronics";
     02H      - ñèãíàëû óïðàâëåíèÿ ïðèíòåðîì;
     03H      - ðåãèñòð íàñòðîéêè ïîðòîâ 00H..02H;
     04H      - ðåãèñòð ñåãìåíòîâ äëÿ îêíà "RAM0";
     05H      - ðåãèñòð ñåãìåíòîâ äëÿ îêíà "RAM1";
     06H      - ðåãèñòð ñåãìåíòîâ äëÿ îêíà "RAM2";
     07H      - ðåãèñòð íàñòðîéêè ïîðòîâ 04H..06H;
     08H      - ðåãèñòð ñòðàíèö ÎÇÓ;
     09H      - ðåãèñòð ñåãìåíòîâ "ROM2-BIOS";
     0AH      - äèñïåò÷åð óïðàâëåíèÿ êîíôèãóðàöèåé ïàìÿòè;
     0BH      - ðåãèñòð íàñòðîéêè ïîðòîâ 08H..0AH;
     0CH..0FH - ñèñòåìíûé ðåçåðâ;
     10H..13H - ïîðòû êîíòðîëëåðà äèñêîâîäà ÊÐ1818ÂÃ93 (â ðåæè-
                ìå  "Orion-128" äîñòóïíû òàêæå ÷åðåç ÿ÷åéêè ïà-
                ìÿòè 0F700H..0F703H, 0F710H..0F714H, 0F720H):
         10H  - ðåãèñòð êîìàíä;
         11H  - ðåãèñòð äîðîæåê;
         12H  - ðåãèñòð ñåêòîðîâ;
         13H  - ðåãèñòð äàííûõ;
         14H  - ðåãèñòð óïðàâëåíèÿ êîíòðîëëåðîì äèñêîâîäà;
                â ðåæèìå "Orion-128" äîñòóïåí òàêæå ÷åðåç ÿ÷åé-
                êè 0F704H, 0F714H, 0F720H;
     18H..1BH - óíèâåðñàëüíûé ïîðò,  èñïîëüçóåìûé êàê ïîðò êëà-
                âèàòóðû; â ðåæèìå "Orion-128" ìîæåò áûòü ïåðåê-
                ëþ÷åí (ïàðàëëåëüíî ñ îáðàùåíèåì 18-1BH) íà  àä-
                ðåñà îäíîãî èç ïîðòîâ 0F4XXH, 0F5XXH, 0F6XXH ïî
                âûáîðó ïîëüçîâàòåëÿ;

     0F8H     - ðåãèñòð óïðàâëåíèÿ öâåòîâûì  ðåæèìîì  äèñïëåÿ;
                â ðåæèìå  "Orion-128" äîñòóïåí òàêæå êàê ÿ÷åéêà
                0F800H;
     0F9H     - ðåãèñòð ñòðàíèö;  äëÿ ðåæèìà "Orion-128" äîñòó-
                ïåí òàêæå êàê ÿ÷åéêà 0F900H;
     0FAH     - ðåãèñòð  íîìåðà  è  ðàçìåðà  ýêðàíà;  â  ðåæèìå
                "Orion-128" äîñòóïåí òàêæå êàê ÿ÷åéêà 0FA00H;
     0FBH     - ðåãèñòð âêëþ÷åíèÿ ïðåðûâàíèé îò òàéìåðà (D6);
     0FCH     - ðåãèñòð öâåòà äëÿ ïñåâäîöâåòíîãî ðåæèìà;
     0FFH     - ïîðò çâóêà.
}

{
  p0A_RAM0_MASK = $01;    // RAM window 0000..3FFF
  p0A_RAM1_MASK = $02;    // RAM window 4000..7FFF
  p0A_RAM2_MASK = $04;    // RAM window 8000..BFFF
  p0A_ROM2_MASK = $08;    // ROM window 2000..3FFF
  p0A_ROM1_MASK = $10;    // ROM window 0000..1FFF
  p0A_FIX_F000  = $40;    // if  p0A_FIX_F000 (D6) = 1  then RAM  F000..FFFF = 1F segment 4k part always (with any pF9 combinations)
  p0A_ORION_128 = $80;    // if  p0A_ORION_128 (D7=1) then RAM  F000..FFFF = 1F segment 4k part always (with any p0A_FIX_F000, pF9 combinations)
}

{$IFDEF DEBUG}
const  tmpRet:integer=$FFFF;
       tmpStart:boolean=False;
       tmpStop:integer=$FFFF;

function ByteToStrBin(bb:byte):string;
 var i: integer;
begin
  Result:='';
  for i:=1 to 8 do
  begin
    if (bb mod 2)=0
      then Result:='0'+Result
      else Result:='1'+Result;
    bb:=bb div 2;
  end;
end;

{$ENDIF}

procedure DebugInfo(str: string; mode:integer);
{$IFDEF DEBUG}
var ff: system.text;
    st, stt: string;
    ii: integer;
    bb: byte;
    cc: array[0..20] of char;
{$ENDIF}
begin
{$IFDEF DEBUG}
  cc[19]:=#0;
  AssignFile(ff, 'c:\OrionZEm.debug');
  if FileExists('c:\OrionZEm.debug') then
    Append(ff)
  else
    Rewrite(ff);
  stt:='';
  st:='';
  if mode=1 then
      for ii:=1 to 11 do
      begin
        bb:=RAMArr[MainPort[$F9], regDE+ii];
        if (bb<32)or(bb>126) then bb:=ord('.');
        stt:=stt+chr(bb);
      end;
  case mode of
  0,1:
    begin
      st:=Format(' - A=%d,B=%d,C=%d,DE=%d(%s),HL=%d(%s), fZ=%d,fC=%d, PC=%d(%s), (DE)=`%s`',
                 [regA, regB, regC, regDE, inttohex(regDE,4), regHL, inttohex(regHL,4), integer(fZ), integer(fC), regPC, inttohex(regPC,4), stt]);
    end;
  2:begin
      st:=IntToStr(TicksFromPrevSD);
    end;
  end;
  writeln(ff, str+' '+st);
  CloseFile(ff);
{$ENDIF}
end;

procedure SetBeeper0;
begin
  glBeeperVal:=128;
end;

procedure SetBeeper1;
begin
  glBeeperVal:=159;
  glBeeperCounter:=Global_TStates;  //  interruptCounter;
end;

function SetMemSize:string;
begin
  RAMPagesCount:=SzRAMarr[MEMSizeMode] div 65536;
  RAMSegmCount:=RAMPagesCount * 4;
  case MEMSizeMode of
    SIZE_4096, SIZE_2048: Result:='9A:AAAA;1;_';
    SIZE_1024: Result:='A:AAAA;1;_'
    else Result:='9:AAAA;1;_';
  end;
end;

function LongAddressStr(page,addr:integer):string;
begin
  Result:=padl(IntToHex(page, 2), 2, '0')+':'+padl(IntToHex(addr, 4), 4, '0');
end;

function LongAddressParse(ast:string; var page,addr:integer):integer;
begin
  Result:=pos(':',ast)-1;
  page:=HexToInt(padl(copy(ast, 1, Result),2,'0'));
  addr:=HexToInt(copy(ast, Result+2, 4));
end;

function GetBeeper:integer;
begin
  if glBeeperVal=128 then Result:=0 else Result:=1;
end;

function peekb(Index: Integer): byte;    // ÷èòàåì áàéò
var pFB, p0A, pPage, fPage: byte;
    addr: integer;
    o128: boolean;                       // true if Orion-128 mode of PRO
begin
  pFB:=MainPort[$FB];
  if Z80CardMode>=Z80_ORIONPRO_v2 then begin                    // Orion-PRO
    p0A:=MainPort[$0A];
    o128:=p0A and p0A_ORION_128 <> 0;
    if Z80CardMode=Z80_ORIONPRO_v2 then fPage:=0 else fPage:=7; // segment 3 or 31
    if o128 then pPage:=MainPort[$F9] mod RAMPagesCount
            else pPage:=MainPort[$08] mod RAMPagesCount;
    if (Index<$4000) then begin
      if (o128 and ((Z80CardMode>Z80_ORIONPRO_v3)and(pFB and $80 = 0))) then begin // if V3.20.pFB.Disp16k
        addr:=(pFB and 3);
        Result:=RAMarr[(pFB and $0C) shr 2, (addr shl 14) or (Index and $3FFF)];  // $OC or $1C ?
      end
      else begin
        if p0A and p0A_RAM0_MASK = 0 then
          Result:=RAMarr[pPage, Index]
        else begin
          addr:=(MainPort[$04] and 3);
          Result:=RAMarr[(MainPort[$04] mod RAMSegmCount) shr 2, (addr shl 14) or (Index and $3FFF)];
        end;
      end;
      if (Index<$2000) then begin               // 0000...1FFF
        if p0A and p0A_ROM1_MASK <> 0 then
          Result:=ROM1BIOS[Index];              // TODO: ROM1BIOS of 64kb size 
      end
      else                                      // 2000...3FFF
        if p0A and p0A_ROM2_MASK <> 0 then
          Result:=ROM2BIOS[MainPort[$09]*$2000+(Index-$2000)];
    end
    else if (Index<$8000) then begin
      if p0A and p0A_RAM1_MASK = 0 then
        Result:=RAMarr[pPage, Index]
      else begin
        addr:=(MainPort[$05] and 3);
        Result:=RAMarr[(MainPort[$05] mod RAMSegmCount) shr 2, (addr shl 14) or (Index and $3FFF)];
      end;
    end
    else if (Index<$C000) then begin
      if p0A and p0A_RAM2_MASK = 0 then
        Result:=RAMarr[pPage, Index]
      else begin
        addr:=(MainPort[$06] and 3);
        Result:=RAMarr[(MainPort[$06] mod RAMSegmCount) shr 2, (addr shl 14) or (Index and $3FFF)];
      end;
    end
    else begin
      Result:=RAMarr[pPage, Index];
      if o128 and(Index>=$F400)and(Index<$F800) then
        Result:=RAMPORTGet(Index)
      else if (Index>=$F000)and((o128 and ((Z80CardMode<Z80_ORIONPRO_v320)or(pFB and $20 = 0))) // if not V3.20.pFB.FullRam
                                 or((not o128)and(p0A and p0A_FIX_F000<>0))) then
        Result:=RAMarr[fPage, Index]
    end;
  end
  else begin                                                          // Orion-128
    if (Index<$F000) or
       ((Z80CardMode>Z80CARD_MINIMAL) and (pFB and $20 <> 0)) then    // "íåñêëååííîå" ÎÇÓ
    begin
      if (Index<$4000) and
         (Z80CardMode>Z80CARD_MINIMAL) and
         (pFB and $80 = 0)  then
      begin                                                           // äèñïåò÷åð 16ê
        addr:=(pFB and 3);
        Result:=RAMarr[(pFB and $0C) shr 2, (addr shl 14) or (Index and $3FFF)];  // $OC or $1C ?
      end
      else if MainPort[$F9]<RAMPagesCount
             then Result:=RAMarr[MainPort[$F9], Index]
             else Result:=$FF;
    end
    else if Index>=$F800 then        // â ñòàíäàðòíîì Îðèîíå - RomBIOS
      Result:=ROMF800[Index]
    else if Index<$F400 then    // "ñêëååííîå" ÎÇÓ
      Result:=RAMarr[0, Index]
    else                        // âíåøíèå ïîðòû (ìàïïèðîâàííûå íà ÎÇÓ)
      Result:=RAMPORTGet(Index);
  end;
end;

function peekw(Index: Integer): word;   //÷èòàåì ñëîâî
begin
  Result := peekb(Index) Or (peekb(Index + 1) shl 8);
end;

procedure pokeb(Index: Integer; const Value: byte);    // ïèøåì áàéò
var pF9, pFB: byte;
    p0A, pPage, fPage: byte;
    addr: integer;
    o128: boolean;                       // true if Orion-128 mode of PRO
begin
  pFB:=MainPort[$FB];
  if Z80CardMode>=Z80_ORIONPRO_v2 then begin                    // Orion-PRO
    p0A:=MainPort[$0A];
    o128:=p0A and p0A_ORION_128 <> 0;
    if Z80CardMode=Z80_ORIONPRO_v2 then fPage:=0 else fPage:=7; // segment 3 or 31
    if o128 then pPage:=MainPort[$F9]mod RAMPagesCount
            else pPage:=MainPort[$08]mod RAMPagesCount;
    if (Index<$4000) then begin
      if ((Index<$2000)and(p0A and p0A_ROM1_MASK <> 0))or   // 0000...1FFF  ROM1
         ((Index>=$2000)and(p0A and p0A_ROM2_MASK <> 0))    // 2000...3FFF  ROM2
        then exit;                                          // read only
      if (o128 and ((Z80CardMode>Z80_ORIONPRO_v3)and(pFB and $80 = 0))) then begin // if V3.20.pFB.Disp16k
        addr:=(pFB and 3);
        RAMarr[(pFB and $0C) shr 2, (addr shl 14) or (Index and $3FFF)]:=Value;
      end
      else begin
        if p0A and p0A_RAM0_MASK = 0 then
          RAMarr[pPage, Index]:=Value
        else begin
          addr:=(MainPort[$04] and 3);
          RAMarr[(MainPort[$04] mod RAMSegmCount) shr 2, (addr shl 14) or (Index and $3FFF)]:=Value;
        end;
      end;
    end
    else if (Index<$8000) then begin
      if p0A and p0A_RAM1_MASK = 0 then
        RAMarr[pPage, Index]:=Value
      else begin
        addr:=(MainPort[$05] and 3);
        RAMarr[(MainPort[$05] mod RAMSegmCount) shr 2, (addr shl 14) or (Index and $3FFF)]:=Value;
      end;
    end
    else if (Index<$C000) then begin
      if p0A and p0A_RAM2_MASK = 0 then
        RAMarr[pPage, Index]:=Value
      else begin
        addr:=(MainPort[$06] and 3);
        RAMarr[(MainPort[$06] mod RAMSegmCount) shr 2, (addr shl 14) or (Index and $3FFF)]:=Value;
      end;
    end
    else if (Index<$F000) then
      RAMarr[pPage, Index]:=Value
    else begin
      if o128 then begin
        if (Index>=$F400) then
          RAMPORTSet(Index, Value)
        else
          if (Z80CardMode<Z80_ORIONPRO_v320)or(pFB and $20 = 0) then // if not V3.20.pFB.FullRam
            RAMarr[fPage, Index]:=Value
          else
            RAMarr[pPage, Index]:=Value;
      end
      else if (p0A and p0A_FIX_F000<>0) then
        RAMarr[fPage, Index]:=Value
      else
        RAMarr[pPage, Index]:=Value;
    end;
  end
  else begin                                                          // Orion-128
    if (Index<$F000) or
       ((Z80CardMode>Z80CARD_MINIMAL) and (pFB and $20 <> 0)) then    // "íåñêëååííîå" ÎÇÓ
    begin
      pF9:=MainPort[$F9];
      if (Index<$4000) and
         (Z80CardMode>Z80CARD_MINIMAL) and
         (pFB and $80 = 0)  then
      begin                                                           // äèñïåò÷åð 16ê
        addr:=(pFB and 3) shl 6;
        RAMarr[(pFB and $0C) shr 2, (addr shl 8) or (Index and $3FFF)]:=Value;   // $OC or $1C ?
      end
      else if (pF9<RAMPagesCount) {and (RAMarr[pF9, Index] <> Value)} then
             RAMarr[pF9, Index] := Value;
    end
    else if Index<$F400 then         // "ñêëååííîå" ÎÇÓ
    begin
      RAMarr[0, Index] := Value;
    end
    else                             // ïîðòû
    begin
      if Z80CardMode<>Z80CARD_MAXIMAL then
        RAMArr[0, Index] := Value;   // â ñòàíäàðòíîì Îðèîíå ïîðòèòñÿ ÎÇÓ ïîä ïîðòàìè
      RAMPortSet(Index, Value);
    end;
  end;
end;

procedure pokew(Index: Integer; const Value: word);      // ïèøåì ñëîâî
begin
    pokeb(Index, Value And $FF);
    pokeb(Index + 1, (Value And $FF00) shr 8);
end;

{ TPORTS }

function RAMPORTGet(Index: Integer): byte;
var addr: byte;
begin
  Result:=$FF;
  case hi(Index) of
    $F8..$FA: Result:=InB(Index);
    $F4: Result:=PortF400[lo(Index) and 3];           // BB55 (i8255) - keyboard
    $F5: if HDDPort=HDDPortF500 then
           Result:=IdeController[lo(Index) and 3]     // BB55 (i8255) - IDE
         else
           Result:=PortF500[lo(Index) and 3];         // BB55 (i8255) - ROMDISK
    $F6: if HDDPort=HDDPortF600 then
           Result:=IdeController[lo(Index) and 3]     // BB55 (i8255) - IDE
         else
           Result:=PortF600[lo(Index) and 3];         // BB55 (i8255) - Printer
    $F7: begin                                        // expansion ports
           addr:=lo(Index);
           if (addr>=$70) then                        // F770..F77F mapped to rtl8019as[reg0...reg15], F780..F7FF mapped to rtl8019as[reg16]
           begin
             if Assigned(FNE2kDevice) then
             begin
               if (addr>=$80) then
                 Result:=FNE2kDevice[16]
               else
                 Result:=FNE2kDevice[addr and $0F];
             end;
           end
           else
           case (addr and $FC) of                                               // íåïîëíàÿ äåøèôðàöèÿ
             lo(FDC_ADDR1), lo(FDC_ADDR2): Result:=FDController[Index and 3];
             lo(RGU_ADDR1), lo(RGU_ADDR2): Result:=FDController.RGU;
             lo(FMC_ADDR60), lo(SD_ADDR0), lo(SD_ADDR1), lo(UART_ADDR0), lo(UART_ADDR1):
             if (Z80CardMode<Z80_ORIONPRO_v2)or(Z80CardMode>=Z80_ORIONPRO_v320) then
               case Index of
                 FMC_ADDR60: case RTCmode of
                               K512viF760: Result:=F146818.Addr;
                               DS1307: ;
                             end;
                 FMC_DATA61: case RTCmode of
                               K512viF760: Result:=F146818[F146818.Addr];
                               DS1307: ;
                             end;
                 SD_ADDR0: Result:=SDController.Port0;
                 SD_ADDR1: Result:=SDController.Port1;
                 UART_ADDR0: Result:=FUART.Port0;
                 UART_ADDR1: Result:=FUART.Port1;
               end;
             end;
         end;
  end;
end;

procedure RAMPORTSet(Index: Integer; const Value: byte);
var addr: byte;
begin
  case hi(Index) of
    $F8..$FA: OutB((word(regA) shl 8) or hi(Index), Value);
    $F4: PortF400[lo(Index) and 3]:=Value;           // BB55 (i8255) - keyboard
    $F5: if HDDPort=HDDPortF500 then
           IdeController[lo(Index) and 3]:=Value     // BB55 (i8255) - IDE
         else
           PortF500[lo(Index) and 3]:=Value;         // BB55 (i8255) - ROMDISK
    $F6: if HDDPort=HDDPortF600 then
           IdeController[lo(Index) and 3]:=Value     // BB55 (i8255) - IDE
         else
           PortF600[lo(Index) and 3]:=Value;         // BB55 (i8255) - Printer
    $F7: begin                                 // extension ports
           addr:=lo(Index);
           if (addr>=$70) then                        // F770..F77F mapped to rtl8019as[reg0...reg15], F780..F7FF mapped to rtl8019as[reg16]
           begin
             if Assigned(FNE2kDevice) then
             begin
               if (addr>=$80) then                              // F780..F7FF - data register (BASE+10h)
                 FNE2kDevice[16]:=Value
               else begin                                       // F770..F77F
                 if (addr=$70)and(Value=ETHERDEV_RESET) then
                   FNE2kDevice.Reset                            // pulse down on reset pin (pin 33 for rtl8019)
                 else
                   FNE2kDevice[addr and $0F]:=Value;
               end;
             end;
           end
           else
           case (addr and $FC) of
             lo(FDC_ADDR1), lo(FDC_ADDR2): FDController.Reg[Index and 3]:=Value;
             lo(RGU_ADDR1), lo(RGU_ADDR2): FDController.RGU:=Value;
             lo(FMC_ADDR60), lo(SD_ADDR0), lo(SD_ADDR1), lo(UART_ADDR0), lo(UART_ADDR1):
             if (Z80CardMode<Z80_ORIONPRO_v2)or(Z80CardMode>=Z80_ORIONPRO_v320) then
               case Index of
                 FMC_ADDR60: case RTCmode of
                               K512viF760: F146818.Addr:=Value;
                               DS1307: ;
                             end;
                 FMC_DATA61: case RTCmode of
                               K512viF760:  F146818[F146818.Addr]:=Value;
                               DS1307: ;
                             end;
                 SD_ADDR0: SDController.Port0:=Value;
                 SD_ADDR1: SDController.Port1:=Value;
                 UART_ADDR0: FUART.Port0:=Value;
                 UART_ADDR1: FUART.Port1:=Value;
               end;
           end;
         end;
  end;
end;

{ Ïîðòû ïî OUT }

procedure outb(port : integer; outbyte : integer);
var bb, pF9: byte;
    dopause:boolean;
    loport:integer;
begin
  loport:=Lo(port);
  if (Z80CardMode>=Z80CARD_MAXIMAL) then begin   // Orion-PRO IDE-RTC card also available for advanced O-128 configuration
    if (Z80CardMode>=Z80_ORIONPRO_v2) then begin                   // Orion-PRO
     case LoPort of
      $08: if outbyte>=RAMPagesCount then outbyte:=outbyte mod RAMPagesCount;
      $10..$14: RAMPORTSet(FDC_ADDR1+LoPort, outbyte);       // FDD
      $18..$1B: RAMPORTSet(KBD_ADDR0+LoPort-$18, outbyte);   // BB55 (i8255) - keyboard
      $28..$2B: RAMPORTSet(ROMD_ADDR0+LoPort-$28, outbyte);  // BB55 (i8255) - Rom-Disk
      $3E: AYWriteReg(glSoundRegister, outbyte);               // çàïèñü äàííûõ ìóç. ïðîöåññîðà
      $3F: glSoundRegister := outbyte And $F;                  // çàïèñü íîìåðà ðåãèñòðà ìóç. ïðîöåññîðà
     end;
    end;
    case LoPort of
      FMC_DATA50: case RTCmode of
                    K512vi50:  F146818[F146818.Addr]:=outbyte;
                    DS1307: ;
                  end;
      FMC_ADDR51: case RTCmode of
                    K512vi50: F146818.Addr:=outbyte;
                    DS1307: ;
                  end;
      pro_control,    // registr uprawleniq         - W
      pro_data_h,     // st.bajt registra dannyh    - WR
      pro_data_l,     // ml.bajt registra dannyh    - WR                   // adr=0
      pro_err,        // registr oshibok            -  R                   // adr=1
      pro_sec_cnt,    // s4et4ik seektorow          - W                    // adr=2
      pro_sector,     // registr sektora            - W                    // adr=3
      pro_cyl_lsb,    // ml.bajt nom.cilindra       - W                    // adr=4
      pro_cyl_msb,    // st.bajt nom.cilindra       - W                    // adr=5
      pro_head,       // registr golowki/ustrojstwa - W                    // adr=6
      pro_command:    // registr komand             - W                    // adr=7
                   IdeProController.IdeReg[LoPort]:=outbyte;
    end;
  end
  else if Z80CardMode=Z80CARD_MOSCOW then
  begin
    if loport>=$F0 then pF9:=0
    else pF9:=MainPort[$F9];
    RAMArr[pF9, loport*256+loport] := outbyte;   // â ñòàíäàðòíîì Îðèîíå ïîðòèòñÿ ÎÇÓ ïîä ïîðòàìè
  end;                                                         // Orion-128, Orion-PRO
  case LoPort of
    $F8: begin
           bb:=MainPort[$F8];
           if bb<>outbyte then
           begin
             DoNotUpdateScr:=False;
             if (bb and $80<>outbyte and $80) then Scr480(outbyte);
           end;
         end;
    $F9: if outbyte>=RAMPagesCount then outbyte:=outbyte mod RAMPagesCount;
    $FA: if (MainPort[$FA] and $80<>outbyte and $80) then Scr480(outbyte);
{$IFDEF USE_SOUND}
    $FE: if Z80CardMode<>Z80CARD_MOSCOW then
         begin
           if (outbyte and 16 = 0)
             then SetBeeper0
             else SetBeeper1;
         end;
    $FF: if Z80CardMode<>Z80CARD_MOSCOW then
         begin
           if GetBeeper=1
             then SetBeeper0
             else SetBeeper1;
         end;
{$ENDIF}
  end;
  dopause:=(CheckPort[LoPort]=1) or                                           // port write
          ((CheckPort[LoPort]=2)and(MainPort[LoPort]<>outbyte));              // port modify
  MainPort[LoPort]:=outbyte;
{$IFDEF USE_SOUND}
  case port of
    $FFFD:  glSoundRegister := outbyte And $F;
    $BFFD:  AYWriteReg(glSoundRegister, outbyte);
    $BEFD:  AYWriteReg(glSoundRegister, outbyte);
  end;
{$ENDIF}
  if dopause then
    frmMain.ActPauseExecute(frmMain);
End;

Function inb(port : integer) : integer;
var loport, pF9: integer;
begin
  Result := $FF;
  loport:=Lo(port);
  if (Z80CardMode>=Z80CARD_MAXIMAL) then begin   // Orion-PRO IDE-RTC card also available for advanced O-128 configuration
    if Z80CardMode>=Z80_ORIONPRO_v2 then begin                    // Orion-PRO
     case LoPort of
      $0:       Result:=lo(OrionPRO_DIP_SW);
      $01..$0B: Result:=MainPort[LoPort];
      $10..$14: Result:=RAMPORTGet(FDC_ADDR1+LoPort);   // FDD
      $18..$1B: Result:=RAMPORTGet(KBD_ADDR0+LoPort);   // BB55 (i8255) - keyboard
      $28..$2B: Result:=RAMPORTGet(ROMD_ADDR0+LoPort);  // BB55 (i8255) - Rom-Disk
      $3F: Result := AYPSG.Regs[glSoundRegister];         // ÷òåíèå äàííûõ ìóç. ïðîöåññîðà
     end;
    end;
    case LoPort of
      FMC_DATA50: case RTCmode of
                    K512vi50:  Result:=F146818[F146818.Addr];
                    DS1307: ;
                  end;
      FMC_ADDR51: case RTCmode of
                    K512vi50: Result:=F146818.Addr;
                    DS1307: ;
                  end;
      pro_astatus,    // alxt.registr sostoqniq     -  R
      pro_data_h,     // st.bajt registra dannyh    - WR
      pro_data_l,     // ml.bajt registra dannyh    - WR                   // adr=0
      pro_err,        // registr oshibok            -  R                   // adr=1
      pro_sec_cnt,    // s4et4ik seektorow          - W                    // adr=2
      pro_sector,     // registr sektora            - W                    // adr=3
      pro_cyl_lsb,    // ml.bajt nom.cilindra       - W                    // adr=4
      pro_cyl_msb,    // st.bajt nom.cilindra       - W                    // adr=5
      pro_head,       // registr golowki/ustrojstwa - W                    // adr=6
      pro_status:     // registr sostoqniq          -  R                   // adr=7
                   Result:=IdeProController.IdeReg[LoPort];
    end;
  end
  else if Z80CardMode=Z80CARD_MOSCOW then
  begin
    if loport>=$F0 then pF9:=0
    else pF9:=MainPort[$F9];
    Result:=RAMArr[pF9, loport*256+loport];   // â ñòàíäàðòíîì Îðèîíå ïîðòèòñÿ ÎÇÓ ïîä ïîðòàìè
  end;                                                         // Orion-128, Orion-PRO
                                                            // Orion-128, Orion-PRO
{$IFDEF USE_SOUND}
  If port = $FFFD Then
    Result := AYPSG.Regs[glSoundRegister]
{$ENDIF}
End;

function GetCPUTstates: integer;
begin
  if (Z80CardMode>=Z80_ORIONPRO_v2) and ((MainPort[$0A] and $20)<>0) then
    Result:=TSTATES_2M5
  else
    Result:=CPUTstates[MIN(CPUSpeedMode, SPEED_INF)];
end;

end.
