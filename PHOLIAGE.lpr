program PHOLIAGE;

uses
  Forms, Interfaces, laz_fpspreadsheet,
  DataRW in 'DataRW.pas',
  Ellipsoid_Integration in 'Ellipsoid_Integration.pas',
  Model_Absorption in 'Model_Absorption.pas',
  Paths in 'Paths.pas',
  GaussInt in 'GaussInt.pas',
  //Plane in 'Plane.pas',
  Quadratic in 'Quadratic.pas',
  UExcel in 'UExcel.pas',
  Vector in 'Vector.pas',
  uMainForm in 'uMainForm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

