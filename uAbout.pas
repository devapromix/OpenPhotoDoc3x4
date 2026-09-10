unit uAbout;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfAbout }

  TfAbout = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  fAbout: TfAbout;

implementation

{$R *.lfm}

{ TfAbout }

procedure TfAbout.FormCreate(Sender: TObject);
begin

end;

end.

