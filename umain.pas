unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  PrintersDlgs, Printers;

type

  { TfMain }

  TfMain = class(TForm)
    btnOpen: TButton;
    btnPrint: TButton;
    btnClose: TButton;
    btnAbout: TButton;
    imgPhoto: TImage;
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

  public

  end;

var
  fMain: TfMain;

implementation

uses uAbout;

{$R *.lfm}

var
  Sheet: TBitmap;

  { TfMain }

procedure TfMain.btnOpenClick(Sender: TObject);
var
  X, Y: integer;
  LeftMargin, TopMargin: integer;
begin
  if OD.Execute then
  begin
    imgPhoto.Picture.LoadFromFile(OD.FileName);

    if not Assigned(Sheet) then
      Sheet := TBitmap.Create;

    // A5: 148 × 210 мм
    // Масштаб: 10 px = 1 мм
    Sheet.SetSize(1480, 2100);

    // Білий аркуш
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(0, 0, Sheet.Width, Sheet.Height);

    // Перевіряємо, чи вибране фото
    if imgPhoto.Picture.Graphic = nil then
      Exit;

    LeftMargin := (Sheet.Width - 4 * 300) div 2;
    TopMargin := (Sheet.Height - 5 * 400) div 2;

    // 20 фотографій: 4 в ширину × 5 у висоту
    for Y := 0 to 4 do
      for X := 0 to 3 do
        Sheet.Canvas.StretchDraw(
          Rect(LeftMargin + X * 300, TopMargin + Y * 400, LeftMargin +
          X * 300 + 300, TopMargin + Y * 400 + 400),
          imgPhoto.Picture.Graphic
          );

    // Тонка чорна сітка поверх фотографій
    Sheet.Canvas.Pen.Color := clBlack;
    Sheet.Canvas.Pen.Width := 3;
    Sheet.Canvas.Brush.Style := bsClear;

    // Вертикальні лінії
    for X := 0 to 4 do
      Sheet.Canvas.Line(LeftMargin + X * 300, TopMargin, LeftMargin +
        X * 300, TopMargin + 5 * 400);

    // Горизонтальні лінії
    for Y := 0 to 5 do
      Sheet.Canvas.Line(LeftMargin, TopMargin + Y * 400,
        LeftMargin + 4 * 300, TopMargin + Y * 400);

    PaintBox1.Invalidate;
  end;
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
  X, Y: Integer;
  PhotoWidth, PhotoHeight: Integer;
  LeftMargin, TopMargin: Integer;
  StepX, StepY: Integer;

  function MmToDots(Mm: Double; DPI: Integer): Integer;
  begin
    Result := Round(Mm * DPI / 25.4);
  end;

begin
  if imgPhoto.Picture.Graphic = nil then
    Exit;

  if not PD.Execute then
    Exit;

  Printer.BeginDoc;
  try
    // Фото 30 × 40 мм
    PhotoWidth := MmToDots(30, Printer.XDPI);
    PhotoHeight := MmToDots(40, Printer.YDPI);

    // Відстань між фотографіями
    StepX := PhotoWidth;
    StepY := PhotoHeight;

    // 4 фото по ширині та 5 по висоті.
    // Центруємо розкладку на доступній області друку.
    LeftMargin :=
      (Printer.PageWidth - 4 * PhotoWidth) div 2;

    TopMargin :=
      (Printer.PageHeight - 5 * PhotoHeight) div 2;

    // Друкуємо ОРИГІНАЛЬНЕ фото напряму на принтер.
    // PaintBox1 та Sheet тут не використовуються.
    for Y := 0 to 4 do
      for X := 0 to 3 do
        Printer.Canvas.StretchDraw(
          Rect(
            LeftMargin + X * StepX,
            TopMargin + Y * StepY,
            LeftMargin + X * StepX + PhotoWidth,
            TopMargin + Y * StepY + PhotoHeight
          ),
          imgPhoto.Picture.Graphic
        );

    // Сітка між фотографіями
    Printer.Canvas.Pen.Color := clBlack;
    Printer.Canvas.Pen.Width := 1;
    Printer.Canvas.Brush.Style := bsClear;

    // Вертикальні лінії
    for X := 0 to 4 do
      Printer.Canvas.Line(
        LeftMargin + X * PhotoWidth,
        TopMargin,
        LeftMargin + X * PhotoWidth,
        TopMargin + 5 * PhotoHeight
      );

    // Горизонтальні лінії
    for Y := 0 to 5 do
      Printer.Canvas.Line(
        LeftMargin,
        TopMargin + Y * PhotoHeight,
        LeftMargin + 4 * PhotoWidth,
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

end;

procedure TfMain.PaintBox1Click(Sender: TObject);
begin

end;

procedure TfMain.PaintBox1Paint(Sender: TObject);
begin
  if Assigned(Sheet) then
    PaintBox1.Canvas.StretchDraw(PaintBox1.ClientRect, Sheet);
end;

end.
