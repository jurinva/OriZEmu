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

interface

{
               1.2. ����������� �������� ������
               --------------------------------

     �������� ������ ������������� � 0 � 1 ��������� ���,  ���-
��� ���������� ������� � ������������� ��������� � ���  �������
�� �������� ��������� ������, ����������� ��������� ����� 0F8H:

     D4  D3  D2  D1  D0
     ------------------
     0   x   0   0   0   - �����������, ������� 1
     0   x   0   0   1   - �����������, ������� 2
     0   x   0   1   x   - ������ ������������
     0   x   1   0   0   - 2-������ (4-�������), ������� 1
     0   x   1   0   1   - 2-������ (4-�������), ������� 2
     0   x   1   1   x   - 16-������� � ��������� ������������
     0   1   1   1   x   - ������������� (���� -  � ���� 0FCH)
     1   x   0   x   x   - 3-������ (8-������� RGB)
     1   x   1   x   x   - 4-������ (16-������� RGBI)

     � �����������  ������  �������  1 ������������� ����������
������ - (������,  �������),  ������� 2 - (�����,  �������).  �
4-�������  (2-� �������) ������ ������� 1 ������������� ����� -
(������,  �����,  �������, �������), ������� 2 - (�����, �����,
�������, �������).
     ��� ������� ��� �������������� ������ ������������ �  ����
� ������� 0FCH.
     ����� �� ����������� ������ �� 4-� ������� ����������� ��-
��� ������ ������ ������ � ���� 0FAH:

     D0 \ ����� ������
     D1 /
     D6 - ���������� ����������� ���
     D7 - ��������� �������� ������

     ������� D2-D5 �������� ����������.

     ���� ������ D7 ���������� � �������, �� ������ ������ ���-
������� 512 ����� (64 �����), ��� ��� ������ 256 ���� ��������-
����� ������ ������ 16 �����. � ��������� ������ �������� ����-
�����  ��� ����� ������ 384 ����� (48 ����) � �������� ����� 12
�����.
     � 3-� ������ � 4-� ������ (EGA-�����) �������� ������� ��-
��������� ������������� ������ ���� �������,  ������� ������ D0
����� 0FAH ������������.
     ���������� ������������� ��������� ��������� ��� � ������-
��� �������� �������.

           1.2.3 ����������� � ������������� ������
           ----------------------------------------

     � ����������� � ������������� ������� �������� ����������-
���  ��  4-�  �������,  ���������� ������ �������� 0-� ��������
���:

                 ���.0         ����� 12 �      ����� 16 �
               --------�      ------------    ------------
     ����� 0 ->�   3   �      C000H..EFFFH    C000H..FFFFH
               �=======�
     ����� 1 ->�   2   �      8000H..AFFFH    8000H..BFFFH
               �=======�
     ����� 2 ->�   1   �      4000H..6FFFH    4000H..7FFFH
               �=======�
     ����� 3 ->�   0   �      0000H..2FFFH    0000H..3FFFH
               L--------

     � �����������  ������  ���������� �������� ���������� ����
��������� �������� ��� ������������� �������� ������������ ���-
��, �������� - �������.
     � �������������  ������ ���� ������������ ����� ������� ��
���� �������,  ����������� � ���� 0FCH. ������� 4 ���� ��������
�����  �����  ���������� ���� �� 16 ������ ���� (��� ����������
�����), ������� 4 ���� - ���� �� 16 ������ ��������� ����� (���
����������� �����).
     �������, ��� ��� ������� ������-0  �������  0F000H..0FFFFH
������ (�� ������ � ��������� �������� 0F000H..0FFFFH) ��������
������ ����� ����.  ������ ������ � ������ ��������  ������  ��
�������  0C000-0EFFFH.  ��� ��������� �� ���� �������� �������.


                    1.2.4.  4-������� �����
                    -----------------------

     � 4-�������  (2-������)  ������  ����  ������ ������������
����� ������� �� ��������������� ����� ���� �������� ����������
(���������), ����������� � ��������� 0 � 1 ���:


                 ���.0   ���.1
               --------T-------�
     ����� 0 ->�   3   �   7   �
               �=======+=======�
     ����� 1 ->�   2   �   6   �
               �=======+=======�
     ����� 2 ->�   1   �   5   �
               �=======+=======�
     ����� 3 ->�   0   �   4   �
               L-------+--------
                   L--� ----

                      0 0  ->  ������ (�����)
                      0 1  ->  �������
                      1 0  ->  �������
                      1 1  ->  �����


             1.2.5.  8-������� � 16-������� ������
             -------------------------------------

     ��� ����� ����������� �����.  ������������� ��  ����������
EGA  ������ �� IBM PC AT (��� ������ ������������� �� 286 ����-
���).  � 8-������� (3-������) � 16-�������  (4-������)  �������
���  ������������  ������������  ����� � ������ �� ���� �������
������������ �������������� 3 � 4 ��������� ��������� ���:

                 ���.0   ���.1
               --------T-------�
               �  3 (G)�  7 (I)�
     ����� 0 ->+-------+-------+
               �  2 (R)�  6 (B)�
               �=======+=======�
               �  1 (G)�  5 (I)�
     ����� 1 ->+-------+-------+
               �  0 (R)�  4 (B)�
               L-------+--------

     ��������� 3  �  1 ������������� ������� ���� (G),  2 � 0 -
������� (R), 6 � 4 - ����� (B), 7 � 5 (� 3-������ ������ �� ��-
����������) - ���������� �������� (I).

     ����� ������  ����������  ����� � ��������������� ��������
������ ����� �������� ����� ��������� �����.


          1.2.6. ����� � ��������� ������������ �����
          -------------------------------------------

     � 16-������� ������ � ��������� ������������ ������ �� 4-�
�������  �����������  �� ����������� ���� ��������� ������:  ��
��������� ����������� (0 �������� ���) � ��������� �������� ��-
�������  (1 �������� ���),  ������ ������ �������� ������ ����-
����� �����������, ������������� � �������� ������ �����, ����-
��������� ���� ���� �� ��������� �������� ���������.

     ������� 4  ���� � ����� ��������� �������� ���������� ����
���� (��� ���������� �����),  ������� 4 ���� -  ����  ���������
�����  (��� ����������� �����) � �������� ������ ��������� ���-
��.

                 ���.0    ���.1
                (�����)  (����)
               --------T-------�
     ����� 0 ->�   3   �   7   �
               �=======+=======�
     ����� 1 ->�   2   �   6   �
               �=======+=======�
     ����� 2 ->�   1   �   5   �
               �=======+=======�
     ����� 3 ->�   0   �   4   �
               L-------+--------

     ��� ���� �������� ������� ��������� ����������� �� ������-
������� �������� ������ � ������� 0, ��������� � �.1.2.3.
     ������� �������, ��� ������ ��������� ��������� � �������-
��� ��������� ���,  � �� � �����,  �.�.  ����������� ����������
������ �� ������� �� ������� �������� ��� � ��������� /  �����-
����� ����.

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
          x_3:=x shl 3;                                             // ��������� ����� ������� ���� �����
          for y := 0 to FSY - 1 do
          begin
            RamCell0:=RAMarr[0, FScrAddr];       // �������� 0
            if (FScrMode in [14,15]) and (Z80CardMode>=Z80_ORIONPRO_v2) then
              RamCell1:=MainPort[$FC]                               // Orion-Pro pseudocolor mode
            else
              RamCell1:=RAMarr[1, FScrAddr];     // �������� 1
            RamCell2:=RAMarr[0, FScrAddr+$4000]; // �������� 0
            RamCell3:=RAMarr[1, FScrAddr+$4000]; // �������� 1
            case FMode of                                           // ��������� ����� ������� ���� �����
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
                     ci:=((RamCell1 and $80) shr 1) and $FE;        // ��� - ������� �����
                     if (RamCell1 and $40 <>0) then cr:=191+ci;
                     if (RamCell1 and $20 <>0) then cg:=191+ci;
                     if (RamCell1 and $10 <>0) then cb:=191+ci;
                     c0:=RGB(cb, cg, cr);
                     cr:=0; cg:=0; cb:=0;
                     ci:=((RamCell1 and 8) shl 3) and $FE;          // ���� - ������� �����
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
