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
    function GetPhotoCount: Integer;
    function GetPhoto(Index: Integer): TGraphic;
    function GetPhotoIndex(PosIdx, PhotoCount: Integer): Integer;
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
  Sheet: TBitmap;

function TfMain.GetPhotoCount: Integer;
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

function TfMain.GetPhoto(Index: Integer): TGraphic;
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

function TfMain.GetPhotoIndex(PosIdx, PhotoCount: Integer): Integer;
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
const
  SheetWidth = 1480;
  SheetHeight = 2100;
  PhotoWidth = 300;
  PhotoHeight = 400;
  Columns = 4;
  Rows = 5;
var
  X, Y: Integer;
  PosIdx: Integer;
  PhotoIndex: Integer;
  PhotoCount: Integer;
  LeftMargin, TopMargin: Integer;
  Graphic: TGraphic;
begin
  PhotoCount := GetPhotoCount;

  if PhotoCount = 0 then
  begin
    PaintBox1.Invalidate;
    Exit;
  end;

  if not Assigned(Sheet) then
    Sheet := TBitmap.Create;

  Sheet.SetSize(SheetWidth, SheetHeight);
  Sheet.PixelFormat := pf24bit;

  Sheet.Canvas.Brush.Style := bsSolid;
  Sheet.Canvas.Brush.Color := clWhite;
  Sheet.Canvas.FillRect(0, 0, Sheet.Width, Sheet.Height);

  LeftMargin := (Sheet.Width - Columns * PhotoWidth) div 2;
  TopMargin := (Sheet.Height - Rows * PhotoHeight) div 2;

  for PosIdx := 0 to Columns * Rows - 1 do
  begin
    X := PosIdx mod Columns;
    Y := PosIdx div Columns;
    PhotoIndex := GetPhotoIndex(PosIdx, PhotoCount);
    Graphic := GetPhoto(PhotoIndex);

    if Assigned(Graphic) then
      Sheet.Canvas.StretchDraw(
        Rect(
          LeftMargin + X * PhotoWidth,
          TopMargin + Y * PhotoHeight,
          LeftMargin + (X + 1) * PhotoWidth,
          TopMargin + (Y + 1) * PhotoHeight
        ),
        Graphic
      );
  end;

  Sheet.Canvas.Pen.Color := clBlack;
  Sheet.Canvas.Pen.Width := 3;
  Sheet.Canvas.Brush.Style := bsClear;

  for X := 0 to Columns do
    Sheet.Canvas.Line(
      LeftMargin + X * PhotoWidth,
      TopMargin,
      LeftMargin + X * PhotoWidth,
      TopMargin + Rows * PhotoHeight
    );

  for Y := 0 to Rows do
    Sheet.Canvas.Line(
      LeftMargin,
      TopMargin + Y * PhotoHeight,
      LeftMargin + Columns * PhotoWidth,
      TopMargin + Y * PhotoHeight
    );

  PaintBox1.Invalidate;
end;

procedure TfMain.btnOpenClick(Sender: TObject);
var
  PhotoCount: Integer;
begin
  PhotoCount := GetPhotoCount;

  if PhotoCount >= 4 then
  begin
    ShowMessage('Вже вибрано 4 фотографії. Максимум — 4.');
    Exit;
  end;

  if not OD.Execute then
    Exit;

  case PhotoCount + 1 of
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
const
  Columns = 4;
  Rows = 5;
var
  X, Y: Integer;
  PosIdx: Integer;
  PhotoWidth, PhotoHeight: Integer;
  LeftMargin, TopMargin: Integer;
  PhotoCount: Integer;
  PhotoIndex: Integer;
  Graphic: TGraphic;

  function MmToDots(Mm: Double; DPI: Integer): Integer;
  begin
    Result := Round(Mm * DPI / 25.4);
  end;

begin
  PhotoCount := GetPhotoCount;

  if PhotoCount = 0 then
  begin
    ShowMessage('Спочатку виберіть хоча б одну фотографію.');
    Exit;
  end;

  if not PD.Execute then
    Exit;

  Printer.BeginDoc;
  try
    PhotoWidth := MmToDots(30, Printer.XDPI);
    PhotoHeight := MmToDots(40, Printer.YDPI);

    LeftMargin := (Printer.PageWidth - Columns * PhotoWidth) div 2;
    TopMargin := (Printer.PageHeight - Rows * PhotoHeight) div 2;

    for PosIdx := 0 to Columns * Rows - 1 do
    begin
      X := PosIdx mod Columns;
      Y := PosIdx div Columns;
      PhotoIndex := GetPhotoIndex(PosIdx, PhotoCount);
      Graphic := GetPhoto(PhotoIndex);

      if Assigned(Graphic) then
        Printer.Canvas.StretchDraw(
          Rect(
            LeftMargin + X * PhotoWidth,
            TopMargin + Y * PhotoHeight,
            LeftMargin + (X + 1) * PhotoWidth,
            TopMargin + (Y + 1) * PhotoHeight
          ),
          Graphic
        );
    end;

    Printer.Canvas.Pen.Color := clBlack;
    Printer.Canvas.Pen.Width := 1;
    Printer.Canvas.Brush.Style := bsClear;

    for X := 0 to Columns do
      Printer.Canvas.Line(
        LeftMargin + X * PhotoWidth,
        TopMargin,
        LeftMargin + X * PhotoWidth,
        TopMargin + Rows * PhotoHeight
      );

    for Y := 0 to Rows do
      Printer.Canvas.Line(
        LeftMargin,
        TopMargin + Y * PhotoHeight,
        LeftMargin + Columns * PhotoWidth,
        TopMargin + Y * PhotoHeight
      );

    Printer.EndDoc;
  except
    Printer.Abort;
    raise;
  end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Sheet := nil;
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

  if Assigned(Sheet) then
    PaintBox1.Canvas.StretchDraw(PaintBox1.ClientRect, Sheet);
end;

destructor TfMain.Destroy;
begin
  FreeAndNil(Sheet);
  inherited Destroy;
end;

end.
