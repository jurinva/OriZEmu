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


unit ScrThrd;

{$MODE Delphi}

interface

{
               1.2. ÎÐÃÀÍÈÇÀÖÈß ÝÊÐÀÍÍÎÉ ÏÀÌßÒÈ
               --------------------------------

     Ýêðàííàÿ ïàìÿòü ðàñïîëàãàåòñÿ â 0 è 1 ñòðàíèöàõ ÎÇÓ,  ïðè-
÷åì êîëè÷åñòâî ýêðàíîâ è ðàñïðåäåëåíèå ñåãìåíòîâ â íèõ  çàâèñèò
îò òåêóùåãî öâåòîâîãî ðåæèìà, çàäàâàåìîãî ðàçðÿäàìè ïîðòà 0F8H:

     D4  D3  D2  D1  D0
     ------------------
     0   x   0   0   0   - ìîíîõðîìíûé, ïàëèòðà 1
     0   x   0   0   1   - ìîíîõðîìíûé, ïàëèòðà 2
     0   x   0   1   x   - çàïðåò âèäåîñèãíàëà
     0   x   1   0   0   - 2-áèòíûé (4-öâåòíûé), ïàëèòðà 1
     0   x   1   0   1   - 2-áèòíûé (4-öâåòíûé), ïàëèòðà 2
     0   x   1   1   x   - 16-öâåòíûé ñ ãðóïïîâûì êîäèðîâàíèåì
     0   1   1   1   x   - ïñåâäîöâåòíîé (öâåò -  â ïîðò 0FCH)
     1   x   0   x   x   - 3-áèòíûé (8-öâåòíûé RGB)
     1   x   1   x   x   - 4-áèòíûé (16-öâåòíûé RGBI)

     Â ìîíîõðîìíîì  ðåæèìå  ïàëèòðå  1 ñîîòâåòñòâóåò êîìáèíàöèÿ
öâåòîâ - (÷åðíûé,  çåëåíûé),  ïàëèòðå 2 - (áåëûé,  çåëåíûé).  Â
4-öâåòíîì  (2-õ áèòîâîì) ðåæèìå ïàëèòðå 1 ñîîòâåòñòâóþò öâåòà -
(÷åðíûé,  ñèíèé,  çåëåíûé, êðàñíûé), ïàëèòðå 2 - (áåëûé, ñèíèé,
çåëåíûé, êðàñíûé).
     Êîä ïàëèòðû äëÿ ïñåâäîöâåòíîãî ðåæèìà çàïèñûâàåòñÿ â  ïîðò
ñ àäðåñîì 0FCH.
     Âûáîð íà îòîáðàæåíèå îäíîãî èç 4-õ ýêðàíîâ âûïîëíÿåòñÿ ïó-
òåì çàïèñè íîìåðà ýêðàíà â ïîðò 0FAH:

     D0 \ íîìåð ýêðàíà
     D1 /
     D6 - âûêëþ÷åíèå ðåãåíåðàöèè ÎÇÓ
     D7 - âêëþ÷åíèå øèðîêîãî ýêðàíà

     Ðàçðÿäû D2-D5 ÿâëÿþòñÿ ðåçåðâíûìè.

     Åñëè ðàçðÿä D7 óñòàíîâëåí â åäèíèöó, òî øèðèíà ýêðàíà ñîñ-
òàâëÿåò 512 òî÷åê (64 áàéòà), ÷òî ïðè âûñîòå 256 áàéò ñîîòâåòñ-
òâóåò îáúåìó ïàìÿòè 16 Êáàéò. Â ïðîòèâíîì ñëó÷àå ýêðàííàÿ ïëîñ-
êîñòü  ÎÇÓ èìååò øèðèíó 384 òî÷êè (48 áàéò) è çàíèìàåò îáúåì 12
Êáàéò.
     Â 3-õ áèòíîì è 4-õ áèòíîì (EGA-ðåæèì) öâåòîâûõ ðåæèìàõ äî-
ïóñêàåòñÿ èñïîëüçîâàíèå òîëüêî äâóõ ýêðàíîâ,  ïîýòîìó ðàçðÿä D0
ïîðòà 0FAH èãíîðèðóåòñÿ.
     Ðàññìîòðèì ðàñïðåäåëåíèå ñåãìåíòîâ ýêðàííîãî ÎÇÓ â ðàçëè÷-
íûõ öâåòîâûõ ðåæèìàõ.

           1.2.3 ÌÎÍÎÕÐÎÌÍÛÉ È ÏÑÅÂÄÎÖÂÅÒÍÎÉ ÐÅÆÈÌÛ
           ----------------------------------------

     Â ìîíîõðîìíîì è ïñåâäîöâåòíîì ðåæèìàõ âîçìîæíî èñïîëüçîâà-
íèå  äî  4-õ  ýêðàíîâ,  çàíèìàþùèõ òîëüêî ñåãìåíòû 0-é ñòðàíèöû
ÎÇÓ:

                 Ñòð.0         Ýêðàí 12 Ê      Ýêðàí 16 Ê
               --------¬      ------------    ------------
     Ýêðàí 0 ->¦   3   ¦      C000H..EFFFH    C000H..FFFFH
               ¦=======¦
     Ýêðàí 1 ->¦   2   ¦      8000H..AFFFH    8000H..BFFFH
               ¦=======¦
     Ýêðàí 2 ->¦   1   ¦      4000H..6FFFH    4000H..7FFFH
               ¦=======¦
     Ýêðàí 3 ->¦   0   ¦      0000H..2FFFH    0000H..3FFFH
               L--------

     Â ìîíîõðîìíîì  ðåæèìå  åäèíè÷íîìó çíà÷åíèþ íåêîòîðîãî áèòà
ýêðàííîãî ñåãìåíòà ÎÇÓ ñîîòâåòñòâóåò çàñâåòêà èçîáðàæàåìîé òî÷-
êè, íóëåâîìó - ãàøåíèå.
     Â ïñåâäîöâåòíîì  ðåæèìå öâåò îòîáðàæàåìûõ òî÷åê çàâèñèò îò
êîäà ïàëèòðû,  çàïèñàííîãî â ïîðò 0FCH. Ñòàðøèå 4 áèòà çíà÷åíèÿ
ýòîãî  ïîðòà  îïðåäåëÿþò îäèí èç 16 öâåòîâ ôîíà (äëÿ ïîãàøåííûõ
òî÷åê), ìëàäøèå 4 áèòà - îäèí èç 16 öâåòîâ ïåðåäíåãî ïëàíà (äëÿ
çàñâå÷åííûõ òî÷åê).
     Çàìåòèì, ÷òî ïðè øèðîêîì ýêðàíå-0  îáëàñòü  0F000H..0FFFFH
ýêðàíà (íå ïóòàòü ñ ñèñòåìíîé îáëàñòüþ 0F000H..0FFFFH) äîñòóïíà
òîëüêî ÷åðåç îêíî.  Ïðÿìîé äîñòóï ê ýêðàíó âîçìîæåí  òîëüêî  ïî
àäðåñàì  0C000-0EFFFH.  Ýòî îòíîñèòñÿ êî âñåì öâåòîâûì ðåæèìàì.


                    1.2.4.  4-ÖÂÅÒÍÛÉ ÐÅÆÈÌ
                    -----------------------

     Â 4-öâåòíîì  (2-áèòíîì)  ðåæèìå  öâåò  êàæäîé îòîáðàæàåìîé
òî÷êè çàâèñèò îò ñîîòâåòñòâóþùèõ áèòîâ äâóõ ýêðàííûõ ïëîñêîñòåé
(ñåãìåíòîâ), íàõîäÿùèõñÿ â ñòðàíèöàõ 0 è 1 ÎÇÓ:


                 Ñòð.0   Ñòð.1
               --------T-------¬
     Ýêðàí 0 ->¦   3   ¦   7   ¦
               ¦=======+=======¦
     Ýêðàí 1 ->¦   2   ¦   6   ¦
               ¦=======+=======¦
     Ýêðàí 2 ->¦   1   ¦   5   ¦
               ¦=======+=======¦
     Ýêðàí 3 ->¦   0   ¦   4   ¦
               L-------+--------
                   L--¬ ----

                      0 0  ->  ÷åðíûé (áåëûé)
                      0 1  ->  êðàñíûé
                      1 0  ->  çåëåíûé
                      1 1  ->  ñèíèé


             1.2.5.  8-ÖÂÅÒÍÛÉ è 16-ÖÂÅÒÍÛÉ ÐÅÆÈÌÛ
             -------------------------------------

     Ýòî íîâûé ãðàôè÷åñêèé ðåæèì.  Ôóíêöèîíàëüíî îí  òîæäåñòâåí
EGA  ðåæèìó íà IBM PC AT (áûë øèðîêî ðàñïðîñòðàíåí íà 286 ìîäå-
ëÿõ).  Â 8-öâåòíîì (3-áèòíîì) è 16-öâåòíîì  (4-áèòíîì)  ðåæèìàõ
äëÿ  ôîðìèðîâàíèÿ  îòîáðàæàåìîé  òî÷êè â êàæäîì èç äâóõ ýêðàíîâ
èñïîëüçóþòñÿ ñîîòâåòñòâåííî 3 è 4 ïëîñêîñòè ýêðàííîãî ÎÇÓ:

                 Ñòð.0   Ñòð.1
               --------T-------¬
               ¦  3 (G)¦  7 (I)¦
     Ýêðàí 0 ->+-------+-------+
               ¦  2 (R)¦  6 (B)¦
               ¦=======+=======¦
               ¦  1 (G)¦  5 (I)¦
     Ýêðàí 1 ->+-------+-------+
               ¦  0 (R)¦  4 (B)¦
               L-------+--------

     Ñåãìåíòàì 3  è  1 ñîîòâåòñòâóåò çåëåíûé öâåò (G),  2 è 0 -
êðàñíûé (R), 6 è 4 - ñèíèé (B), 7 è 5 (â 3-áèòíîì ðåæèìå íå èñ-
ïîëüçóþòñÿ) - óïðàâëåíèå ÿðêîñòüþ (I).

     Ïóòåì çàïèñè  êîìáèíàöèè  áèòîâ â ñîîòâåòñòâóþùèå ñåãìåíòû
ýêðàíà ìîæíî ïîëó÷èòü òî÷êó çàäàííîãî öâåòà.


          1.2.6. ÐÅÆÈÌ Ñ ÃÐÓÏÏÎÂÛÌ ÊÎÄÈÐÎÂÀÍÈÅÌ ÖÂÅÒÀ
          -------------------------------------------

     Â 16-öâåòíîì ðåæèìå ñ ãðóïïîâûì êîäèðîâàíèåì êàæäûé èç 4-õ
ýêðàíîâ  ôîðìèðóåòñÿ  èç ñîäåðæèìîãî äâóõ ñåãìåíòîâ ïàìÿòè:  èç
ïëîñêîñòè èçîáðàæåíèÿ (0 ñòðàíèöà ÎÇÓ) è ïëîñêîñòè öâåòîâûõ àò-
ðèáóòîâ  (1 ñòðàíèöà ÎÇÓ),  ïðè÷åì âîñüìè ñîñåäíèì òî÷êàì ïëîñ-
êîñòè èçîáðàæåíèÿ, ðàñïîëîæåííûì â ïðåäåëàõ îäíîãî áàéòà, ñîîò-
âåòñòâóåò îäèí áàéò èç ïëîñêîñòè öâåòîâûõ àòðèáóòîâ.

     Ñòàðøèå 4  áèòà â áàéòå öâåòîâîãî àòðèáóòà îïðåäåëÿþò öâåò
ôîíà (äëÿ ïîãàøåííûõ òî÷åê),  ìëàäøèå 4 áèòà -  öâåò  ïåðåäíåãî
ïëàíà  (äëÿ çàñâå÷åííûõ òî÷åê) â ïðåäåëàõ îäíîãî ýêðàííîãî áàé-
òà.

                 Ñòð.0    Ñòð.1
                (èçîáð)  (öâåò)
               --------T-------¬
     Ýêðàí 0 ->¦   3   ¦   7   ¦
               ¦=======+=======¦
     Ýêðàí 1 ->¦   2   ¦   6   ¦
               ¦=======+=======¦
     Ýêðàí 2 ->¦   1   ¦   5   ¦
               ¦=======+=======¦
     Ýêðàí 3 ->¦   0   ¦   4   ¦
               L-------+--------

     Äëÿ âñåõ öâåòîâûõ ðåæèìîâ äåéñòâóåò îãðàíè÷åíèå íà èñïîëü-
çîâàíèå øèðîêîãî ýêðàíà ñ íîìåðîì 0, îïèñàííîå â Ï.1.2.3.
     Ñëåäóåò ïîìíèòü, ÷òî ýêðàíû àïïàðàòíî ïðèâÿçàíû ê êîíêðåò-
íûì ñåãìåíòàì ÎÇÓ,  à íå ê îêíàì,  ò.å.  îòîáðàæåíèå èíôîðìàöèè
ýêðàíà íå çàâèñèò îò ðàáî÷åé ñòðàíèöû ÎÇÓ è âêëþ÷åíèÿ /  âûêëþ-
÷åíèÿ îêîí.

}

{$I 'OrionZEm.inc'}


uses
  Windows, Messages, SysUtils, Classes;

type
  TScrThread = class(TThread)
  private
    FScrMode, FScrAddr, FSX, FSY, FMX, FMode: Integer;
    procedure DrawScreen;
    procedure BlankScreen;
  protected
    procedure Execute; override;
  public
    constructor Create(SX, SY, MX, ScrMode: Integer);
    destructor Destroy; override;
  end;

implementation

Uses modOrion, MainWin;

constructor TScrThread.Create(SX, SY, MX, ScrMode: Integer);
begin
  FSX:=SX;
  FSY:=SY;
  FMX:=MX;
  FMode:=ScrMode;
  inherited Create(True);         // Create Suspended
end;

destructor TScrThread.Destroy;
begin
  inherited;
end;

procedure TScrThread.BlankScreen;
begin
  frmMain.BlankOrionScreen;
end;

procedure TScrThread.DrawScreen;
begin
  frmMain.DrawOrionScreen;
end;

procedure TScrThread.Execute;
var
  x, y, b, tmpx, x_3, ty1, ty2, ty3: integer;
  RamCell0, RamCell1, RamCell2, RamCell3, ci, cr, cg, cb: byte;
  Color, c0, c1, c2, c3: COLORREF;
begin
  repeat
    if not DoNotUpdateScr then
    begin
      if Z80CardMode>=Z80_ORIONPRO_v2 then tmpx:=31 else tmpx:=7;
      FScrMode:=MainPort[$F8] and tmpx;
      if FScrMode and 16 = 0 then
        FScrAddr:=ScrBase[(MainPort[$FA]) and 3]
      else
        FScrAddr:=ScrBase[(MainPort[$FA]) and 3 or 1];              // Orion-Pro mode
      case FScrMode of
        0:   begin c0:=RGB(0,0,0);      c1:=RGB(0,255,0);    end;
        1:   begin c0:=RGB(200,180,40); c1:=RGB(50,250,250); end;
        2,3: begin
               DoNotUpdateScr:=True;
               Synchronize(BlankScreen);
             end;
        4: begin c0:=RGB(0,0,0);       c1:=RGB(0,0,192); c2:=RGB(0,192,0); c3:=RGB(192,0,0); end;
        5: begin c0:=RGB(192,192,192); c1:=RGB(0,0,192); c2:=RGB(0,192,0); c3:=RGB(192,0,0); end;
      end;
      if not (FScrMode in [2,3]) then
        for x := 0 to (FSX div 8) - 1 do
        begin
          x_3:=x shl 3;                                             // âû÷èñëÿåì ëåâûé âåðõíèé óãîë òî÷êè
          for y := 0 to FSY - 1 do
          begin
            RamCell0:=RAMarr[0, FScrAddr];       // ñòðàíèöà 0
            if (FScrMode in [14,15]) and (Z80CardMode>=Z80_ORIONPRO_v2) then
              RamCell1:=MainPort[$FC]                               // Orion-Pro pseudocolor mode
            else
              RamCell1:=RAMarr[1, FScrAddr];     // ñòðàíèöà 1
            RamCell2:=RAMarr[0, FScrAddr+$4000]; // ñòðàíèöà 0
            RamCell3:=RAMarr[1, FScrAddr+$4000]; // ñòðàíèöà 1
            case FMode of                                           // âû÷èñëÿåì ëåâûé âåðõíèé óãîë òî÷êè
              SCR_ZOOM_X1:
                ty1:=y * FMX;
              SCR_ZOOM_X2:
                ty1:=y * FMX *2;                                    // (y*384) *4             ( *4 = horz*2 + vert*2 )
              SCR_ZOOM_X25: 
                ty1:=((y * 5) shr 1) * FMX ;
              SCR_ZOOM_X3:
                ty1:=y * FMX *3;
            end;
            ty2:=ty1 + FMX;                                         // (y*384)*4 + 384*2      ( shift to second row )
            ty3:=ty2 + FMX;                                         // shift to third row
            case FScrMode of
              6,7,14,15:
                   begin
                     cr:=0; cg:=0; cb:=0;
                     ci:=((RamCell1 and $80) shr 1) and $FE;        // ôîí - ñòàðøèé íèááë
                     if (RamCell1 and $40 <>0) then cr:=191+ci;
                     if (RamCell1 and $20 <>0) then cg:=191+ci;
                     if (RamCell1 and $10 <>0) then cb:=191+ci;
                     c0:=RGB(cb, cg, cr);
                     cr:=0; cg:=0; cb:=0;
                     ci:=((RamCell1 and 8) shl 3) and $FE;          // öâåò - ìëàäøèé íèááë
                     if (RamCell1 and 4 <>0) then cr:=191+ci;
                     if (RamCell1 and 2 <>0) then cg:=191+ci;
                     if (RamCell1 and 1 <>0) then cb:=191+ci;
                     c1:=RGB(cb, cg, cr);
                   end;
            end;
            for b:=7 downto 0 do
            begin
              case FScrMode of
                0,1,6,7,14,15: if (RamCell0 and 1)=0 then Color:=c0 else Color:=c1;
                4,5: begin
                       case ((RamCell0 and 1) shl 1) or (RamCell1 and 1) of
                         0: Color:=c0;
                         1: Color:=c1;
                         2: Color:=c2
                         else Color:=c3;
                       end;
                       RamCell1 := RamCell1 shr 1;
                     end
                else begin
                       case FScrMode and 20 of
                         16: begin                                   // Orion-Pro 3-bit color mode
                               if (RamCell0 and 1 = 0) then cr:=0 else cr:=191;
                               if (RamCell1 and 1 = 0) then cb:=0 else cb:=191;
                               if (RamCell2 and 1 = 0) then cg:=0 else cg:=191;
                               RamCell1 := RamCell1 shr 1;
                               RamCell2 := RamCell2 shr 1;
                               Color:=RGB(cb, cg, cr);
                             end;
                         20: begin                                   // Orion-Pro 4-bit color mode
                               if (RamCell3 and 1 = 0) then ci:=0 else ci:=63;
                               if (RamCell0 and 1 = 0) then cr:=0 else cr:=191+ci;
                               if (RamCell1 and 1 = 0) then cb:=0 else cb:=191+ci;
                               if (RamCell2 and 1 = 0) then cg:=0 else cg:=191+ci;
                               RamCell1 := RamCell1 shr 1;
                               RamCell2 := RamCell2 shr 1;
                               RamCell3 := RamCell3 shr 1;
                               Color:=RGB(cb, cg, cr);
                             end;
                       end;
                     end;
              end;
              RamCell0 := RamCell0 shr 1;
              case FMode of
                SCR_ZOOM_X1:
                   begin
                     TBig(Scr^)[x_3 + b + ty1] := Color;
                   end;
                SCR_ZOOM_X2:
                   begin                                           // x=0..384/8, y=0..255
                     tmpx:=(x_3 + b) shl 1;                        // (x*8 + 0..7) *2
                     TBig(Scr^)[tmpx +     ty1] := Color;          // left half point    (first row)
                     TBig(Scr^)[tmpx + 1 + ty1] := Color;          // right half point
                     TBig(Scr^)[tmpx +     ty2] := Color;          // left half point    (second row)
                     TBig(Scr^)[tmpx + 1 + ty2] := Color;          // right half point
                   end;
                SCR_ZOOM_X25:
                   begin
                     tmpx:=((x_3 + b) * 5) shr 1;                  //  0, 2, 5, 7, 10, 12, 15, ...
                     TBig(Scr^)[tmpx +     ty1] := Color;          // line 1
                     TBig(Scr^)[tmpx + 1 + ty1] := Color;
                     TBig(Scr^)[tmpx +     ty2] := Color;          // line 2
                     TBig(Scr^)[tmpx + 1 + ty2] := Color;
                     if boolean(b and 1) then
                     begin
                       TBig(Scr^)[tmpx + 2 + ty1] := Color;
                       TBig(Scr^)[tmpx + 2 + ty2] := Color;
                       if boolean(y and 1) then
                         TBig(Scr^)[tmpx + 2 + ty3] := Color;
                     end;
                     if boolean(y and 1) then
                     begin
                       TBig(Scr^)[tmpx +     ty3] := Color;        // line 3
                       TBig(Scr^)[tmpx + 1 + ty3] := Color;
                     end;
                   end;
                SCR_ZOOM_X3:
                   begin
                     tmpx:=(x_3 + b) *3 ;
                     TBig(Scr^)[tmpx +     ty1] := Color;          // line 1
                     TBig(Scr^)[tmpx + 1 + ty1] := Color;
                     TBig(Scr^)[tmpx + 2 + ty1] := Color;
                     TBig(Scr^)[tmpx +     ty2] := Color;          // line 2
                     TBig(Scr^)[tmpx + 1 + ty2] := Color;
                     TBig(Scr^)[tmpx + 2 + ty2] := Color;
                     TBig(Scr^)[tmpx +     ty3] := Color;          // line 3
                     TBig(Scr^)[tmpx + 1 + ty3] := Color;
                     TBig(Scr^)[tmpx + 2 + ty3] := Color;
                   end;
              end;
            end;
            inc(FScrAddr);
          end;
        end;
      Synchronize(DrawScreen);
    end;
    sleep(19);
  until Terminated;
end;

end.
