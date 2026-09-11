unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  PrintersDlgs, Printers;

type

  TfMain = class(TForm)
    btnOpen: TButton;
    btnPrint: TButton;
    btnClose: TButton;
    btnAbout: TButton;
    imgPhoto1: TImage;
    imgPhoto2: TImage;
    imgPhoto3: TImage;
    imgPhoto4: TImage;
    OD: TOpenDialog;
    PaintBox1: TPaintBox;
    PD: TPrintDialog;
    procedure btnAboutClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Click(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
  private
    function GetPhotoCount: integer;
    function GetPhoto(Index: integer): TGraphic;
    function GetPhotoIndex(PosIdx, PhotoCount: integer): integer;
    procedure BuildSheet;
  public
    destructor Destroy; override;
  end;

var
  fMain: TfMain;

implementation

uses
  uAbout;

  {$R *.lfm}

var
  LSheet: TBitmap;

const
  CColumns = 4;
  CRows = 5;
  CSheetWidth = 1480;
  CSheetHeight = 2100;
  CPhotoWidth = 300;
  CPhotoHeight = 400;

function TfMain.GetPhotoCount: integer;
begin
  Result := 0;

  if Assigned(imgPhoto1.Picture.Graphic) then
    Inc(Result);

  if Assigned(imgPhoto2.Picture.Graphic) then
    Inc(Result);

  if Assigned(imgPhoto3.Picture.Graphic) then
    Inc(Result);

  if Assigned(imgPhoto4.Picture.Graphic) then
    Inc(Result);
end;

function TfMain.GetPhoto(Index: integer): TGraphic;
begin
  Result := nil;

  case Index of
    1:
      Result := imgPhoto1.Picture.Graphic;
    2:
      Result := imgPhoto2.Picture.Graphic;
    3:
      Result := imgPhoto3.Picture.Graphic;
    4:
      Result := imgPhoto4.Picture.Graphic;
  end;
end;

function TfMain.GetPhotoIndex(PosIdx, PhotoCount: integer): integer;
begin
  case PhotoCount of
    1:
      Result := 1;
    2:
      if PosIdx < 10 then
        Result := 1
      else
        Result := 2;
    3:
      if PosIdx < 7 then
        Result := 1
      else if PosIdx < 14 then
        Result := 2
      else
        Result := 3;
    4:
      Result := (PosIdx div 5) + 1;
    else
      Result := 0;
  end;
end;

procedure TfMain.BuildSheet;
var
  LX, LY: integer;
  LPosIdx: integer;
  LPhotoIndex: integer;
  LPhotoCount: integer;
  LLeftMargin, LTopMargin: integer;
  LGraphic: TGraphic;
begin
  LPhotoCount := GetPhotoCount;

  if LPhotoCount = 0 then
  begin
    PaintBox1.Invalidate;
    Exit;
  end;

  if not Assigned(LSheet) then
    LSheet := TBitmap.Create;

  LSheet.SetSize(CSheetWidth, CSheetHeight);
  LSheet.PixelFormat := pf24bit;

  LSheet.Canvas.Brush.Style := bsSolid;
  LSheet.Canvas.Brush.Color := clWhite;
  LSheet.Canvas.FillRect(0, 0, LSheet.Width, LSheet.Height);

  LLeftMargin := (LSheet.Width - CColumns * CPhotoWidth) div 2;
  LTopMargin := (LSheet.Height - CRows * CPhotoHeight) div 2;

  for LPosIdx := 0 to CColumns * CRows - 1 do
  begin
    LX := LPosIdx mod CColumns;
    LY := LPosIdx div CColumns;
    LPhotoIndex := GetPhotoIndex(LPosIdx, LPhotoCount);
    LGraphic := GetPhoto(LPhotoIndex);

    if Assigned(LGraphic) then
      LSheet.Canvas.StretchDraw(
        Rect(LLeftMargin + LX * CPhotoWidth, LTopMargin + LY *
        CPhotoHeight, LLeftMargin + (LX + 1) * CPhotoWidth, LTopMargin +
        (LY + 1) * CPhotoHeight),
        LGraphic
        );
  end;

  LSheet.Canvas.Pen.Color := clBlack;
  LSheet.Canvas.Pen.Width := 3;
  LSheet.Canvas.Brush.Style := bsClear;

  for LX := 0 to CColumns do
    LSheet.Canvas.Line(
      LLeftMargin + LX * CPhotoWidth,
      LTopMargin,
      LLeftMargin + LX * CPhotoWidth,
      LTopMargin + CRows * CPhotoHeight
      );

  for LY := 0 to CRows do
    LSheet.Canvas.Line(
      LLeftMargin,
      LTopMargin + LY * CPhotoHeight,
      LLeftMargin + CColumns * CPhotoWidth,
      LTopMargin + LY * CPhotoHeight
      );

  PaintBox1.Invalidate;
end;

procedure TfMain.btnOpenClick(Sender: TObject);
var
  LPhotoCount: integer;
begin
  LPhotoCount := GetPhotoCount;

  if LPhotoCount >= 4 then
  begin
    ShowMessage('Вже вибрано 4 фотографії. Максимум — 4.');
    Exit;
  end;

  if not OD.Execute then
    Exit;

  case LPhotoCount + 1 of
    1:
      imgPhoto1.Picture.LoadFromFile(OD.FileName);
    2:
      imgPhoto2.Picture.LoadFromFile(OD.FileName);
    3:
      imgPhoto3.Picture.LoadFromFile(OD.FileName);
    4:
      imgPhoto4.Picture.LoadFromFile(OD.FileName);
  end;

  BuildSheet;
end;

procedure TfMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.btnAboutClick(Sender: TObject);
begin
  fAbout.ShowModal;
end;

procedure TfMain.btnPrintClick(Sender: TObject);
var
  LX, LY: integer;
  LPosIdx: integer;
  LPhotoWidth, LPhotoHeight: integer;
  LLeftMargin, LTopMargin: integer;
  LPhotoCount: integer;
  LPhotoIndex: integer;
  LGraphic: TGraphic;

  function MmToDots(Mm: double; DPI: integer): integer;
  begin
    Result := Round(Mm * DPI / 25.4);
  end;

begin
  LPhotoCount := GetPhotoCount;

  if LPhotoCount = 0 then
  begin
    ShowMessage('Спочатку виберіть хоча б одну фотографію.');
    Exit;
  end;

  if not PD.Execute then
    Exit;

  Printer.BeginDoc;
  try
    LPhotoWidth := MmToDots(30, Printer.XDPI);
    LPhotoHeight := MmToDots(40, Printer.YDPI);

    LLeftMargin := (Printer.PageWidth - CColumns * LPhotoWidth) div 2;
    LTopMargin := (Printer.PageHeight - CRows * LPhotoHeight) div 2;

    for LPosIdx := 0 to CColumns * CRows - 1 do
    begin
      LX := LPosIdx mod CColumns;
      LY := LPosIdx div CColumns;
      LPhotoIndex := GetPhotoIndex(LPosIdx, LPhotoCount);
      LGraphic := GetPhoto(LPhotoIndex);

      if Assigned(LGraphic) then
        Printer.Canvas.StretchDraw(
          Rect(LLeftMargin + LX * LPhotoWidth, LTopMargin + LY *
          LPhotoHeight, LLeftMargin + (LX + 1) * LPhotoWidth, LTopMargin +
          (LY + 1) * LPhotoHeight),
          LGraphic
          );
    end;

    Printer.Canvas.Pen.Color := clBlack;
    Printer.Canvas.Pen.Width := 1;
    Printer.Canvas.Brush.Style := bsClear;

    for LX := 0 to CColumns do
      Printer.Canvas.Line(
        LLeftMargin + LX * LPhotoWidth,
        LTopMargin,
        LLeftMargin + LX * LPhotoWidth,
        LTopMargin + CRows * LPhotoHeight
        );

    for LY := 0 to CRows do
      Printer.Canvas.Line(
        LLeftMargin,
        LTopMargin + LY * LPhotoHeight,
        LLeftMargin + CColumns * LPhotoWidth,
        LTopMargin + LY * LPhotoHeight
        );

    Printer.EndDoc;
  except
    Printer.Abort;
    raise;
  end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  LSheet := nil;
  imgPhoto1.Picture.Clear;
  imgPhoto2.Picture.Clear;
  imgPhoto3.Picture.Clear;
  imgPhoto4.Picture.Clear;
end;

procedure TfMain.PaintBox1Click(Sender: TObject);
begin
end;

procedure TfMain.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Brush.Color := clWhite;
  PaintBox1.Canvas.FillRect(PaintBox1.ClientRect);

  if Assigned(LSheet) then
    PaintBox1.Canvas.StretchDraw(PaintBox1.ClientRect, LSheet);
end;

destructor TfMain.Destroy;
begin
  FreeAndNil(LSheet);
  inherited Destroy;
end;

end.
