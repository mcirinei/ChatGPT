﻿unit ChatGPT.FrameMessage;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Memo.Types, FMX.Layouts, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, System.Generics.Collections, FMX.BehaviorManager;

type
  TFrameMessage = class(TFrame)
    RectangleBG: TRectangle;
    MemoText: TMemo;
    LayoutInfo: TLayout;
    RectangleUser: TRectangle;
    Path1: TPath;
    RectangleBot: TRectangle;
    Path2: TPath;
    LayoutContent: TLayout;
    LayoutContentText: TLayout;
    LayoutAudio: TLayout;
    Rectangle1: TRectangle;
    Path3: TPath;
    procedure MemoTextChange(Sender: TObject);
    procedure FrameResize(Sender: TObject);
  private
    FIsUser: Boolean;
    FText: string;
    FIsError: Boolean;
    FIsAudio: Boolean;
    procedure SetIsUser(const Value: Boolean);
    procedure SetText(const Value: string);
    procedure SetIsError(const Value: Boolean);
    procedure ParseText(const Value: string);
    procedure SetIsAudio(const Value: Boolean);
  public
    procedure UpdateContentSize;
    property Text: string read FText write SetText;
    property IsUser: Boolean read FIsUser write SetIsUser;
    property IsAudio: Boolean read FIsAudio write SetIsAudio;
    property IsError: Boolean read FIsError write SetIsError;
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.Math, FMX.Memo.Style;

{$R *.fmx}

procedure TFrameMessage.UpdateContentSize;
begin
  var H := Padding.Top + Padding.Bottom;
  for var Control in LayoutContentText.Controls do
    if Control is TMemo then
    begin
      ((Control as TMemo).Presentation as TStyledMemo).InvalidateContentSize;
      ((Control as TMemo).Presentation as TStyledMemo).PrepareForPaint;
      (Control as TMemo).Height := Max((Control as TMemo).ContentBounds.Height + (Control as TMemo).TagFloat * 2, 30);
      H := H + Max((Control as TMemo).Height, 30);
      H := H + Control.Margins.Top + Control.Margins.Bottom;
    end;
  if Height <> H then
    Height := H;
end;

constructor TFrameMessage.Create(AOwner: TComponent);
begin
  inherited;
  Name := '';
  {$IFDEF ANDROID}
  MemoText.HitTest := False;
  {$ENDIF}
  IsAudio := False;
end;

procedure TFrameMessage.FrameResize(Sender: TObject);
begin
  LayoutContent.Width := Min(Width - (Padding.Left + Padding.Right), 650);
  UpdateContentSize;
end;

procedure TFrameMessage.MemoTextChange(Sender: TObject);
begin
  UpdateContentSize;
end;

procedure TFrameMessage.SetIsAudio(const Value: Boolean);
begin
  FIsAudio := Value;
  LayoutAudio.Visible := FIsAudio;
end;

procedure TFrameMessage.SetIsError(const Value: Boolean);
begin
  FIsError := Value;
  MemoText.FontColor := $FFEF4444;
end;

procedure TFrameMessage.SetIsUser(const Value: Boolean);
begin
  FIsUser := Value;
  RectangleUser.Visible := FIsUser;
  RectangleBot.Visible := not FIsUser;

  if FIsUser then
  begin
    RectangleBG.Fill.Color := $00FFFFFF;
    MemoText.FontColor := $FFECECF1;
  end
  else
  begin
    RectangleBG.Fill.Color := $14FFFFFF;
    MemoText.FontColor := $FFD1D5E3;
  end;
end;

procedure TFrameMessage.ParseText(const Value: string);
type
  TPartType = (ptText, ptCode);

  TPart = record
    PartType: TPartType;
    Content: string;
  end;

  function CreatePart(AType: TPartType; AContent: string): TPart;
  begin
    Result.PartType := AType;
    Result.Content := AContent.Trim([#13, #10, ' ']);
  end;

var
  Parts: TList<TPart>;
  CodePairs: Integer;
  IsCode: Boolean;
  Buf: string;
begin
  if Value.Contains('```') then
  begin
    Parts := TList<TPart>.Create;
    try
      CodePairs := 0;
      Buf := '';
      IsCode := False;
      for var C in Value do
      begin
        if C = '`' then
        begin
          Inc(CodePairs);
          if CodePairs = 3 then
          begin
            if IsCode then
            begin
              if not Buf.IsEmpty then
                Parts.Add(CreatePart(ptCode, Buf));
              IsCode := False;
            end
            else
            begin
              if not Buf.IsEmpty then
                Parts.Add(CreatePart(ptText, Buf));
              IsCode := True;
            end;
            Buf := '';
            CodePairs := 0;
          end;
        end
        else
        begin
          CodePairs := 0;
          Buf := Buf + C;
        end;
      end;
      if IsCode then
      begin
        if not Buf.IsEmpty then
          Parts.Add(CreatePart(ptCode, Buf));
      end
      else
      begin
        if not Buf.IsEmpty then
          Parts.Add(CreatePart(ptText, Buf));
      end;

      var IsFirstText: Boolean := True;
      for var Part in Parts do
      begin
        begin
          var Memo: TMemo;
          if IsFirstText then
          begin
            Memo := MemoText;
            IsFirstText := False;
          end
          else
          begin
            Memo := TMemo.Create(LayoutContentText);
            with Memo do
            begin
              Parent := LayoutContentText;
              Caret.Color := $00FFFFFF;
              DisableMouseWheel := True;
              ReadOnly := True;
              ShowScrollBars := False;
              StyledSettings := [TStyledSetting.Style];
              TextSettings.Font.Size := 16;
              TextSettings.FontColor := $FFECECF1;
              TextSettings.WordWrap := True;
              CanParentFocus := True;
              Cursor := crDefault;
              DisableFocusEffect := True;
              EnableDragHighlight := False;
              StyleLookup := 'memostyle_clear';
              OnChange := MemoTextChange;
              OnChangeTracking := MemoTextChange;
              TagFloat := 2;
              if Part.PartType = ptCode then
              begin
                Margins.Rect := TRectF.Create(0, 5, 0, 5);
                TagFloat := 5;
                StyleLookup := 'memostyle_code';
                TextSettings.Font.Family := 'Consolas';
                TextSettings.FontColor := $FFC6C6C6;
                ShowScrollBars := True;
                AutoHide := TBehaviorBoolean.True;
              end;
              ApplyStyleLookup;
            end;
          end;
          Memo.Text := Part.Content;
          (Memo.Presentation as TStyledMemo).InvalidateContentSize;
          (Memo.Presentation as TStyledMemo).PrepareForPaint;
          Memo.Align := TAlignLayout.None;
          Memo.Position.Y := 10000;
          Memo.Align := TAlignLayout.Top;
        end;
      end;
    finally
      Parts.Free;
    end;
  end
  else
  begin
    MemoText.Text := Value;
    (MemoText.Presentation as TStyledMemo).InvalidateContentSize;
    (MemoText.Presentation as TStyledMemo).PrepareForPaint;
  end;
  UpdateContentSize;
end;

procedure TFrameMessage.SetText(const Value: string);
begin
  if not Value.IsEmpty then
    FText := Value
  else
    FText := 'пусто';
  FText := FText.Trim([' ', #13, #10]);
  ParseText(FText);
end;

end.

