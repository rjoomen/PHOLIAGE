unit About;

interface

uses LCLIntf, LCLType, Forms, StdCtrls, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Copyright: TLabel;
    Comments: TLabel;
    OKButton: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.lfm}

uses uMainForm;

procedure TAboutBox.FormCreate(Sender: TObject);
begin
    ProgramIcon.Picture.Icon:=Application.Icon;
    ProductName.Caption:='PHOLIAGE - Photosynthesis and Light Absorption Model';
    Copyright.Caption:='Copyright: Utrecht University, Faculty of Bèta Sciences, Department of Plant Ecology and Roelof Oomen';
    Version.Caption:='Version '+MainForm.version;
    Comments.Caption:='Author:'+#13+'Roelof Oomen'+#13+
               'Utrecht University'+#13+
               'Department of Plant Ecology'+#13+
               'Sorbonnelaan 16'+#13+
               '3584CA Utrecht, The Netherlands'+#13+
               'http://www.bio.uu.nl/~boev/'+#13+
               'e-mail: rjoomen@yahoo.com';
{    MessageDlg('PHOLIAGE '+version+#13+
               'Light absorption model'+#13+#13+
               'Author:'+#13+'Roelof Oomen'+#13+
               'Utrecht University'+#13+
               'Department of Plant Ecology'+#13+
               'e-mail: rjoomen@yahoo.com'+#13+#13+
               'Address:'+#13+'Sorbonnelaan 16'+#13+
               '3584CA Utrecht'+#13+
               'The Netherlands'+#13+
               'http://www.bio.uu.nl/~boev/'+#13+#13+
               'Contact:'+#13+
               'Niels Anten'+#13+
               'e-mail: n.p.r.anten@bio.uu.nl', mtInformation, [mbOK], 0);  }
end;

end.
 
