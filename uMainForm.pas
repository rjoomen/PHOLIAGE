unit uMainForm;

//
// PHOLIAGE Model, (c) Roelof Oomen, 2006-2007
//
// Main user interface handling
//

interface

uses
    // Own units
    Ellipsoid_Integration,
    // Delphi Units
    LCLIntf, LCLType, Controls, Forms, StdCtrls, ExtCtrls,
    ValEdit, Dialogs, ComCtrls, Classes;

const
    PROCTHREADS = 3;

type

    { TMainForm }

    TMainForm = class(TForm)
        private
        fVersion: string;
        function getVersion : string;
    published
        GPValueListEditor: TValueListEditor;
        PageControl1: TPageControl;
        Model: TTabSheet;
        TabSheet2: TTabSheet;
        IntervalValueListEditor: TValueListEditor;
        ModelValueListEditor: TValueListEditor;
        ParamLabel: TLabel;
        Label17: TLabel;
        Label13: TLabel;
        AbsLightEdit: TEdit;
        Edit7: TEdit;
        Label3: TLabel;
        IndTreeRunButton: TButton;
        RuntimeLabeledEdit: TLabeledEdit;
        OpenDialog: TOpenDialog;
        SelectFileButton: TButton;
        FilenameEdit: TEdit;
        CountLabeledEdit: TLabeledEdit;
        MainRunButton: TButton;
        ProgressBar1: TProgressBar;
        TimeLabeledEdit: TLabeledEdit;
        SaveButton: TButton;
        SaveOpenDialog: TOpenDialog;
        SaveOpenCheckBox: TCheckBox;
        LADistComboBox: TComboBox;
        LADistLabel: TLabel;
        ExitButton: TButton;
        AboutButton: TButton;
        PhotoSynthEdit: TEdit;
        Label1: TLabel;
        PhotValueListEditor: TValueListEditor;
        HorLeafCheckBox: TCheckBox;
        Label2: TLabel;
        procedure IndTreeRunButtonClick(Sender: TObject);
        procedure FormDestroy(Sender: TObject);
        procedure DoGP(Ellipsoid : TEllipsoid);
        procedure DoIntervals(Ellipsoid : TEllipsoid);
        procedure SelectFileButtonClick(Sender: TObject);
        procedure MainRunButtonClick(Sender: TObject);
        procedure SaveButtonClick(Sender: TObject);
        procedure FormCreate(Sender: TObject);
        procedure ExitButtonClick(Sender: TObject);
        procedure AboutButtonClick(Sender: TObject);
    public
        property version: string read fVersion;
    end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  Model_Absorption, GaussInt, About, DataRW,
  strutils, sysutils,
  fileinfo, // fileinfo reads exe resources as long as you register the appropriate units
  winpeimagereader, {need this for reading exe info}
  elfreader, {needed for reading ELF executables}
  machoreader; {needed for reading MACH-O executables}

var
    Plot       : TPlot;

procedure TMainForm.AboutButtonClick(Sender: TObject);
begin
    AboutBox.ShowModal;
end;

procedure TMainForm.DoGP(Ellipsoid  : TEllipsoid);
// Initialise the gaussion integration points
begin
    Ellipsoid.gpPsi:=StrToInt(GPValueListEditor.Cells[1,3]);
    Ellipsoid.gpR:=  StrToInt(GPValueListEditor.Cells[1,2]);
    Ellipsoid.gpZ:=  StrToInt(GPValueListEditor.Cells[1,1]);
    Ellipsoid.Ring.Ellipse.Env.Absorption.GP:=         StrToInt(GPValueListEditor.Cells[1,4]);
    Ellipsoid.Ring.Ellipse.Env.Absorption.AbsorptionAz.GP:=StrToInt(GPValueListEditor.Cells[1,5]);
    Ellipsoid.Ring.Ellipse.Env.Light.GP:=StrToInt(GPValueListEditor.Cells[1,6]);
    Ellipsoid.Ring.Ellipse.Env.Light.Extinction.GP:=StrToInt(GPValueListEditor.Cells[1,7]);
    Ellipsoid.Ring.Ellipse.Env.Light.Extinction.ExtinctionAz.GP:=StrToInt(GPValueListEditor.Cells[1,8]);
    Ellipsoid.Ring.Ellipse.Env.Assimilation.AssimilationAz.IncidentL.GP:=StrToInt(GPValueListEditor.Cells[1,9]);
    Ellipsoid.Ring.Ellipse.Env.Assimilation.AssimilationAz.IncidentL.IncidentLAz.GP:=StrToInt(GPValueListEditor.Cells[1,10]);
    Ellipsoid.Ring.Ellipse.Env.Assimilation.GP:=StrToInt(GPValueListEditor.Cells[1,11]);
    Ellipsoid.Ring.Ellipse.Env.Assimilation.AssimilationAz.GP:=StrToInt(GPValueListEditor.Cells[1,12]);
end;

procedure TMainForm.DoIntervals(Ellipsoid : TEllipsoid);
// Initialise the gaussion integration intervals and three azimuth widths
begin
//Ellipsoid z (min)=-1
//Ellipsoid z (max)=1
    Ellipsoid.x_min:=StrToFloat(IntervalValueListEditor.Cells[1,1]);
    Ellipsoid.x_max:=StrToFloat(IntervalValueListEditor.Cells[1,2]);
//Ellipsoid psi (min*pi)=0
//Ellipsoid psi (max*pi)=2
    Ellipsoid.Ring.Ellipse.x_min:=StrToFloat(IntervalValueListEditor.Cells[1,3])*pi;
    Ellipsoid.Ring.Ellipse.x_max:=StrToFloat(IntervalValueListEditor.Cells[1,4])*pi;
//I psi (min*pi)=0
//I psi (max*pi)=2
    Ellipsoid.Ring.Ellipse.Env.Absorption.AbsorptionAz.x_min:=StrToFloat(IntervalValueListEditor.Cells[1,5])*pi;
    Ellipsoid.Ring.Ellipse.Env.Absorption.AbsorptionAz.x_max:=StrToFloat(IntervalValueListEditor.Cells[1,6])*pi;
//I_0 theta (min*pi)=0
//I_0 theta (max*pi)=0,5
    Ellipsoid.Ring.Ellipse.Env.Light.x_min:=StrToFloat(IntervalValueListEditor.Cells[1,7])*pi;
    Ellipsoid.Ring.Ellipse.Env.Light.x_max:=StrToFloat(IntervalValueListEditor.Cells[1,8])*pi;
//Kf psi (min*pi)=0
//Kf psi (max*pi)=2
    Ellipsoid.Ring.Ellipse.Env.Light.Extinction.ExtinctionAz.x_min:=StrToFloat(IntervalValueListEditor.Cells[1,9])*pi;
    Ellipsoid.Ring.Ellipse.Env.Light.Extinction.ExtinctionAz.x_max:=StrToFloat(IntervalValueListEditor.Cells[1,10])*pi;
//P psi (min*pi)=0
//P psi (max*pi)=2
    Ellipsoid.Ring.Ellipse.Env.Assimilation.AssimilationAz.x_min:=StrToFloat(IntervalValueListEditor.Cells[1,11])*pi;
    Ellipsoid.Ring.Ellipse.Env.Assimilation.AssimilationAz.x_max:=StrToFloat(IntervalValueListEditor.Cells[1,12])*pi;
//Crown AzWidth f_omega (*pi)=2
    Ellipsoid.Ring.Ellipse.Env.Crown.F.AzWidth:=StrToFloat(IntervalValueListEditor.Cells[1,13])*pi;
//Veg AzWidth f_omega (*pi)=2
    Ellipsoid.Ring.Ellipse.Env.Vegetation.F.AzWidth:=StrToFloat(IntervalValueListEditor.Cells[1,14])*pi;
//AzWidth i_omega_0 (*pi)=2
    Ellipsoid.Ring.Ellipse.Env.Light.AzWidth:=StrToFloat(IntervalValueListEditor.Cells[1,15])*pi;
end;

procedure TMainForm.ExitButtonClick(Sender: TObject);
begin
    Application.Terminate;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
    PageControl1.TabIndex:=0;
    Plot:=TPlot.Create;

    fVersion := getVersion; // Retrieve project version information
    MainForm.Caption := MainForm.Caption + ' v.' + version;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
    FreeAndNil(Plot);
end;

procedure TMainForm.MainRunButtonClick(Sender: TObject);
var
    I: Integer;
    RunTime : DWord;
    GIR : GIResult;
begin
    TimeLabeledEdit.Text:='';
    runtime:=GetTickCount64;
    ProgressBar1.Min:=0;
    ProgressBar1.Max:=Length(Plot.Plants);
    ProgressBar1.Position:=0;
    try
        // Prevent user action during calculations
        PageControl1.Enabled:=false;
        MainRunButton.Enabled:=false;
        Screen.Cursor := crHourglass;

        SetLength(Plot.AbsResults,Length(Plot.Plants));
        SetLength(Plot.PhotResults,Length(Plot.Plants));

        for I := 0 to High(Plot.Plants) do
        // Initialise and calculate
        begin
            // Set up integration points
            DoGP(Plot.Plants[I]);
                // The actual work
                GIR:=Plot.Plants[I].Calculate;
                // Save results
                Plot.AbsResults[I]:=GIR[0];
                Plot.PhotResults[i]:=GIR[1];

                ProgressBar1.StepIt;
                TimeLabeledEdit.Text:=FloatToStr((GetTickCount64-RunTime)/1000);
                // Keep application responsive
                Application.ProcessMessages;
        end;
    finally
        Screen.Cursor := crDefault;
        MainRunButton.Enabled:=true;
        PageControl1.Enabled:=true;
    end;
end;

procedure TMainForm.IndTreeRunButtonClick(Sender: TObject);
var
    RunTime : DWord;
    Ellipsoid : TEllipsoid;
    Env : TEnvironment;
    Phot : TPhotosynthesis;
    tmpS : String;
    GIR : GIResult;
begin
    runtime:=GetTickCount64;

    Ellipsoid:= TEllipsoid.Create;
    Env:=Ellipsoid.Ring.Ellipse.Env;
    Phot:=Ellipsoid.Ring.Ellipse.Env.Photosynthesis;

    try // Make sure Ellipsoid is cleaned up
        // Set Gaussian points
        DoGP(Ellipsoid);

        // Set up crown dimensions
        Env.Crown.a:=StrToFloat(ModelValueListEditor.Cells[1,1]);
        Env.Crown.b:=StrToFloat(ModelValueListEditor.Cells[1,2]);
        Env.Crown.c:=StrToFloat(ModelValueListEditor.Cells[1,3]);

        // Set up vegetation parameters
        Env.Vegetation.r_gap:=StrToFloat(ModelValueListEditor.Cells[1,4]);
        Env.Vegetation.h_t:=  StrToFloat(ModelValueListEditor.Cells[1,5]);
        Env.Vegetation.h_b:=  StrToFloat(ModelValueListEditor.Cells[1,6]);

        // Add some leaves and leaf angle classes
        Env.Crown.F.Clear;
        Env.Crown.F.LADist:=LADistComboBox.ItemIndex;
        Env.Crown.F.F:=StrToFloat(ModelValueListEditor.Cells[1,7]);
        If HorLeafCheckBox.Checked then
        begin
            Env.Crown.F.addclassD(0.5,1,1);
        end
        else
        begin
            Env.Crown.F.addclassD(15,30, StrToFloat(ModelValueListEditor.Cells[1,8]));
            Env.Crown.F.addclassD(45,30, StrToFloat(ModelValueListEditor.Cells[1,9]));
            Env.Crown.F.addclassD(75,30, StrToFloat(ModelValueListEditor.Cells[1,10]));
        end;
        Env.Crown.F.fractionise;
        Env.Crown.F.a_L:=StrToFloat(ModelValueListEditor.Cells[1,11]);

        // Add some leaves and leaf angle classes
        Env.Vegetation.F.Clear;
        Env.Vegetation.F.LADist:=LADistComboBox.ItemIndex;
        Env.Vegetation.F.F:=StrToFloat(ModelValueListEditor.Cells[1,12]);
        If HorLeafCheckBox.Checked then
        begin
            Env.Vegetation.F.addclassD(0.5,1,1);
        end
        else
        begin
            Env.Vegetation.F.addclassD(15,30, StrToFloat(ModelValueListEditor.Cells[1,13]));
            Env.Vegetation.F.addclassD(45,30, StrToFloat(ModelValueListEditor.Cells[1,14]));
            Env.Vegetation.F.addclassD(75,30, StrToFloat(ModelValueListEditor.Cells[1,15]));
        end;
        Env.Vegetation.F.fractionise;
        Env.Vegetation.F.a_L:=StrToFloat(ModelValueListEditor.Cells[1,16]);

        Env.Light.c:=StrToFloat(ModelValueListEditor.Cells[1,17]);
        Env.Light.I_H:=StrToFloat(ModelValueListEditor.Cells[1,18]);

        // Set Integration intervals (after clearing and init of F's)
        DoIntervals(Ellipsoid);

        Phot.N_top:=StrToFloat(PhotValueListEditor.Cells[1,1]);
        Phot.a_N:=StrToFloat(PhotValueListEditor.Cells[1,2]);
        Phot.a_P:=StrToFloat(PhotValueListEditor.Cells[1,3]);
        Phot.b_P:=StrToFloat(PhotValueListEditor.Cells[1,4]);
        tmpS:=PhotValueListEditor.Cells[1,5];
        if tmpS='' then
        begin
            Phot.p_lin:=true;
            tmpS:='0';
        end
        else
            Phot.p_lin:=false;
        Phot.c_P:=StrToFloat(tmpS);
        Phot.a_R:=StrToFloat(PhotValueListEditor.Cells[1,6]);
        Phot.b_R:=StrToFloat(PhotValueListEditor.Cells[1,7]);
        Phot.phi:=StrToFloat(PhotValueListEditor.Cells[1,8]);
        Phot.theta:=StrToFloat(PhotValueListEditor.Cells[1,9]);

        // Calculate absorption&photosynthesis
        GIR:=Ellipsoid.Calculate;

        AbsLightEdit.Text:=FloatToStr(GIR[0]);
        PhotoSynthEdit.Text:=FloatToStr(GIR[1]);
        // Crown volume
        Edit7.Text:=FloatToStr(4/3*pi*Env.Crown.a*Env.Crown.b*Env.Crown.c);
    finally
        FreeAndNil(Ellipsoid);
    end;

    // Timing
    runtime:=GetTickCount64-RunTime;
    RuntimeLabeledEdit.Text:=inttoStr(round(runtime/1000));
end;

procedure TMainForm.SelectFileButtonClick(Sender: TObject);
var
    toReadPlot : ReadPlot;
begin
    OpenDialog.Filter:='Microsoft Excel files (*.xls)|*.XLS;*.xls|CSV files (*.csv)|*.CSV;*.csv';
    OpenDialog.Title:='Open';
    OpenDialog.FileName:='';
    try
        // Prevent user action during calculations
        PageControl1.Enabled:=false;
        Screen.Cursor := crHourglass;

        toReadPlot:= ReadPlot.Create;

        if OpenDialog.Execute then
        begin
            MainRunButton.Enabled:=false;
            ProgressBar1.Position:=0;
            FilenameEdit.Text:=OpenDialog.FileName;
            Plot.Clear;
            // Update UI
            Application.ProcessMessages;
            CountLabeledEdit.Text:=IntToStr(toReadPlot.ReadData(Plot,OpenDialog.FileName));
        end;
    finally
        FreeAndNil(toReadPlot);
        MainRunButton.Enabled:=true;
        Screen.Cursor := crDefault;
        PageControl1.Enabled:=true;
    end;
end;

procedure TMainForm.SaveButtonClick(Sender: TObject);
var
    WriteExcel : TWriteExcel;
begin
    SaveOpenDialog.Filter:='Microsoft Excel files (*.xls)|*.XLS;*.xls';
    SaveOpenDialog.Title:='Save';
    SaveOpenDialog.FileName:='';
    if SaveOpenDialog.Execute then
    begin
        WriteExcel:=TWriteExcel.Create;
        if not WriteExcel.Write(Plot, SaveOpenDialog.FileName) then
            Application.MessageBox('Error writing results file','Error',MB_OK)
        else
            Application.MessageBox('Succesfully written file','Succes',MB_OK);
        FreeAndNil(WriteExcel);
        If SaveOpenCheckBox.Checked then
             OpenDocument(PChar(SaveOpenDialog.FileName)); { *Converted from ShellExecute* }
    end;
end;

function TMainForm.getVersion : string;
var
  FileVerInfo: TFileVersionInfo;
  version_: string;
begin
  FileVerInfo := TFileVersionInfo.Create(nil);
  try
    FileVerInfo.FileName := ParamStr(0);
    FileVerInfo.ReadFileInfo;
    version_ := FileVerInfo.VersionStrings.Values['FileVersion'];
    // Cut off build number
    version_ := LeftStr(version_, RPos('.', version_) - 1);
  finally
    FreeAndNil(FileVerInfo);
  end;
  Result := version_;
end;

end.
