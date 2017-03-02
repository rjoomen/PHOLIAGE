unit DataRW;

//
// PHOLIAGE Model, (c) Roelof Oomen, 2006-2007
//
// Data Reading and Writing classes
//

interface

uses
    LCLIntf, LCLType, Variants, Classes, fpspreadsheet,
    Ellipsoid_Integration, UExcel;


type
    TMyCSV2=class
    private
        m_RowCount,
        m_ColCount : Integer;
        Data : array of array of String;
        Function GetFieldText(Row,Col:Integer):String;
        Function GetFieldTextD(Row,Col:Integer):Double;
    public
        // CSV separator character
        Separator : char;
        // Dimensions
        property RowCount: Integer read m_RowCount;
        property ColCount: Integer read m_ColCount;
        // Row and Col are 1-based to comply with Excel automation
        property Item[Row,Col:Integer]:String read GetFieldText;
        property ItemD[Row,Col:Integer]:Double read GetFieldTextD;
        // Load the data
        procedure LoadFile(const FileName: string);
        // Extra constructor
        Constructor Create(FileName:String; sep : char); overload;
    end;

    TMyCSV=class(TStringList)
    private
        Function GetFieldText(Row,Col:Integer):String;
        procedure SetFieldText(Row,Col:Integer;Value:String);
    public
        // CSV separator character
        Separator : char;
        // Row and Col are 1-based to comply with Excel automation
        property FieldText[Row,Col:Integer]:String read GetFieldText write SetFieldText;
        procedure LoadFile(const FileName:String);
    end;

    ReadPlot = class
    private
        function ReadExcelData(Plot : TPlot; FileName : String):Integer;
        function ReadCSVData(Plot : TPlot; FileName : String):Integer;
    public
        function ReadData(Plot : TPlot; FileName : String):Integer;
    end;

    TWriteExcel = class (WriteXLS)
        function Write(Plot:TPlot; xlsname : String): boolean;
    end;

    // Wrapper for TsWorkSheet with 1-based row and column indexing
    TSheet = class helper for TsWorksheet
        function ReadAsUTF8Text(ARow, ACol: Cardinal): string;
        function ReadAsNumber(ARow, ACol: Cardinal): Double;
    end;

implementation

uses
    SysUtils, StrUtils, Dialogs,
    Model_Absorption, Math,
    // fpspreadsheet supported file formats
    xlsbiff2, xlsbiff5, xlsbiff8, xlsxooxml, fpsopendocument;

function ReadPlot.ReadCSVData(Plot: TPlot; FileName: String): Integer;
var
    CSV : TMyCSV2;

    c, I_H, PlHeight : Double;
    I, col : Integer;
    Diam : boolean;
    Ellipsoid : TEllipsoid;
    Env : TEnvironment;
    Phot : TPhotosynthesis;
    tmpS : String;
    // Names of currently read colums for error message
    colnames : TStringList;
begin
    result:=0;
    I:=1;
    col:=1;
    colnames:=TStringList.Create;
    colnames.Clear;
    try
        try
            CSV := TMyCSV2.Create(FileName, #59);

            Colnames.Add('Name/Location');
            // Cells.Item[row, column]
            Plot.name:=CSV.Item[4,1];
            Plot.location:=CSV.Item[4,2];

            Colnames[0]:='Clouding const/Horiz. light';
            c:=CSV.ItemD[7,1];
            if c=0 then
                Raise EInOutError.Create('Clouding constant cannot not be zero');
            I_H:=CSV.ItemD[7,2];

            // Check if a,b and c are written as radii or diameters
            if LeftStr(CSV.Item[8,4],8)='Diameter' then
                Diam:=true
            else
                Diam:=false;

            Ellipsoid:=TEllipsoid.Create;
            Env:=Ellipsoid.Ring.Ellipse.Env;
            Phot:=Ellipsoid.Ring.Ellipse.Env.Photosynthesis;

            Colnames.Clear;
            // Read all column names to be able to give specific error messages
            I:=1;
            repeat
                tmpS:=CSV.Item[9,I];
                if tmpS<>'' then
                    colnames.Add(tmpS);
                inc(I);
            until tmpS='';

            for I := 10 to CSV.RowCount do
            with CSV do
            begin
                col:=1;
                Ellipsoid.Name:=Item[I,col];
                // Stop on first empty line
                if Ellipsoid.Name='' then
                    break;

                // Set up crown dimensions
                inc(col);
                PlHeight:=StrToFloat(Item[I,col]);
                inc(col);
                Env.Crown.a:=StrToFloat(Item[I,col]);
                inc(col);
                Env.Crown.b:=StrToFloat(Item[I,col]);
                inc(col);
                Env.Crown.c:=StrToFloat(Item[I,col]);
                if (Env.Crown.a=0) or (Env.Crown.b=0) or (Env.Crown.c=0) then
                    Raise EInOutError.Create('Crown dimensions cannot be zero');
                If Diam then
                begin
                    Env.Crown.a:=Env.Crown.a/2;
                    Env.Crown.b:=Env.Crown.b/2;
                    Env.Crown.c:=Env.Crown.c/2;
                end;

                // Set up vegetation parameters
                inc(col);
                Env.Vegetation.r_gap:=StrToFloat(Item[I,col]);
                inc(col);
                Env.Vegetation.h_t:=  StrToFloat(Item[I,col]);
                inc(col);
                Env.Vegetation.h_b:=  StrToFloat(Item[I,col]);

                if PlHeight<>0 then
                begin
                    // Origin of data is plant stem base
                    Env.Vegetation.h_t:=Env.Vegetation.h_t-(PlHeight-Env.Crown.a);
                    Env.Vegetation.h_b:=Env.Vegetation.h_b-(PlHeight-Env.Crown.a);
                end;

                // Add leaves and leaf angle classes
                Env.Crown.F.Clear;
                inc(col);
                Env.Crown.F.F:=StrToFloat(Item[I,col]);
                // Calculate leaf area density from plant total leaf area
                //   and crown volume
                Env.Crown.F.F:=Env.Crown.F.F/(4/3*pi*Env.crown.a*Env.crown.b*Env.crown.c);
                inc(col);
                Env.Crown.F.addclassD(15,30, StrToFloat(Item[I,col]));
                inc(col);
                Env.Crown.F.addclassD(45,30, StrToFloat(Item[I,col]));
                inc(col);
                Env.Crown.F.addclassD(75,30, StrToFloat(Item[I,col]));
                try
                    Env.Crown.F.fractionise;
                except
                    on E:EMathError do
                        Raise EInOutError.Create('At least one crown leaf angle class must not be zero');
                end;
                inc(col);
                Env.Crown.F.a_L:=StrToFloat(Item[I,col]);

                // Add leaves and leaf angle classes
                Env.Vegetation.F.Clear;
                inc(col);
                Env.Vegetation.F.F:=StrToFloat(Item[I,col]);
                // Calculate leaf area density from vegetation LAI and thickness
                Env.Vegetation.F.F:=Env.Vegetation.F.F/(Env.Vegetation.h_t-Env.Vegetation.h_b);
                inc(col);
                Env.Vegetation.F.addclassD(15,30, StrToFloat(Item[I,col]));
                inc(col);
                Env.Vegetation.F.addclassD(45,30, StrToFloat(Item[I,col]));
                inc(col);
                Env.Vegetation.F.addclassD(75,30, StrToFloat(Item[I,col]));
                try
                    Env.Vegetation.F.fractionise;
                except
                    on E:EMathError do
                        Raise EInOutError.Create('At least one vegetation leaf angle class must not be zero');
                end;
                inc(col);
                Env.Vegetation.F.a_L:=StrToFloat(Item[I,col]);
                Env.Light.c:=c;
                Env.Light.I_H:=I_H;

                inc(col);
                Phot.N_top:=StrToFloat(Item[I,col]);
                inc(col);
                Phot.a_N:=StrToFloat(Item[I,col]);
                inc(col);
                Phot.a_P:=StrToFloat(Item[I,col]);
                inc(col);
                Phot.b_P:=StrToFloat(Item[I,col]);
                inc(col);
                // This column can be empty
                tmpS:=Item[I,col];
                if tmpS='' then
                begin
                    Phot.p_lin:=true;
                    tmpS:='0';
                end
                else
                    Phot.p_lin:=false;
                Phot.c_P:=StrToFloat(tmpS);
                inc(col);
                // This column can be empty
                tmpS:=Item[I,col];
                if tmpS='' then
                    tmpS:='0';
                Phot.a_R:=StrToFloat(tmpS);
                inc(col);
                Phot.b_R:=StrToFloat(Item[I,col]);
                inc(col);
                Phot.phi:=StrToFloat(Item[I,col]);
                inc(col);
                Phot.theta:=StrToFloat(Item[I,col]);

                SetLength(Plot.Plants,Length(Plot.Plants)+1);
                SetLength(Plot.Heights,Length(Plot.Plants));
                Plot.Plants[High(Plot.Plants)]:=Ellipsoid;
                Plot.Heights[High(Plot.Plants)]:=PlHeight;

                Ellipsoid:=TEllipsoid.Create;
                Env:=Ellipsoid.Ring.Ellipse.Env;
                Phot:=Ellipsoid.Ring.Ellipse.Env.Photosynthesis;
                Result:=I-9;
            end;
         except
              on E: Exception do
              begin
                  Result:=0;  // 0 plants correctly read
                  Plot.Clear; // Clear everything read so far
                  ShowMessage(' '+E.Message+' in row '+IntToStr(I)+', column "'+colnames[col-1]+'".');
              end;
        end;
    finally
        FreeAndNil(ColNames);
        FreeAndNil(Ellipsoid);
        FreeAndNil(CSV);
    end;

end;

function ReadPlot.ReadExcelData(Plot : TPlot; FileName : String):Integer;
var
    WorkBook: TsWorkbook; // Spreadsheet workbook
    Sheet: TsWorksheet;

    c, I_H, PlHeight : Double;
    I, col : Integer;
    Diam : boolean;
    Ellipsoid : TEllipsoid;
    Env : TEnvironment;
    Phot : TPhotosynthesis;
    tmpS : String;
    // Names of currently read colums for error message
    colnames : TStringList;
begin
    result:=0;
    I:=1;
    col:=1;
    colnames:=TStringList.Create;
    colnames.Clear;

    Workbook := TsWorkbook.Create;
    try
        Workbook.ReadFromFile(FileName);
        try
            Sheet := WorkBook.GetWorksheetByIndex(0);

            Colnames.Add('Name/Location');
            // Cells.Item[row, column]
            Plot.name:=Sheet.ReadAsUTF8Text(4,1);
            Plot.location:=Sheet.ReadAsUTF8Text(4,2);

            Colnames[0]:='Clouding const/Horiz. light';
            c:=Sheet.ReadAsNumber(7,1);
            if c=0 then
                Raise EInOutError.Create('Clouding constant cannot not be zero');
            I_H:=Sheet.ReadAsNumber(7,2);

            // Check if a,b and c are written as radii or diameters
            if LeftStr(Sheet.ReadAsUTF8Text(8,4) ,8)='Diameter' then
                Diam:=true
            else
                Diam:=false;

            Ellipsoid:=TEllipsoid.Create;
            Env:=Ellipsoid.Ring.Ellipse.Env;
            Phot:=Ellipsoid.Ring.Ellipse.Env.Photosynthesis;

            Colnames.Clear;
            // Read all column names to be able to give specific error messages
            I:=1;
            repeat
                tmpS:=Sheet.ReadAsUTF8Text(9,I);
                if tmpS<>'' then
                    colnames.Add(tmpS);
                inc(I);
            until tmpS='';

            for I := 10 to Sheet.GetLastRowIndex() do
            with Sheet.Cells do
            begin
                col:=1;
                Ellipsoid.Name:=Sheet.ReadAsUTF8Text(I,col);
                // Stop on first empty line
                if Ellipsoid.Name='' then
                    break;

                // Set up crown dimensions
                inc(col);
                PlHeight:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Env.Crown.a:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Env.Crown.b:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Env.Crown.c:=Sheet.ReadAsNumber(I,col);
                if (Env.Crown.a=0) or (Env.Crown.b=0) or (Env.Crown.c=0) then
                    Raise EInOutError.Create('Crown dimensions cannot be zero');
                If Diam then
                begin
                    Env.Crown.a:=Env.Crown.a/2;
                    Env.Crown.b:=Env.Crown.b/2;
                    Env.Crown.c:=Env.Crown.c/2;
                end;

                // Set up vegetation parameters
                inc(col);
                Env.Vegetation.r_gap:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Env.Vegetation.h_t:=  Sheet.ReadAsNumber(I,col);
                inc(col);
                Env.Vegetation.h_b:=  Sheet.ReadAsNumber(I,col);

                if PlHeight<>0 then
                begin
                    // Origin of data is plant stem base
                    Env.Vegetation.h_t:=Env.Vegetation.h_t-(PlHeight-Env.Crown.a);
                    Env.Vegetation.h_b:=Env.Vegetation.h_b-(PlHeight-Env.Crown.a);
                end;

                // Add leaves and leaf angle classes
                Env.Crown.F.Clear;
                inc(col);
                Env.Crown.F.F:=Sheet.ReadAsNumber(I,col);
                // Calculate leaf area density from plant total leaf area
                //   and crown volume
                Env.Crown.F.F:=Env.Crown.F.F/(4/3*pi*Env.crown.a*Env.crown.b*Env.crown.c);
                inc(col);
                Env.Crown.F.addclassD(15,30, Sheet.ReadAsNumber(I,col));
                inc(col);
                Env.Crown.F.addclassD(45,30, Sheet.ReadAsNumber(I,col));
                inc(col);
                Env.Crown.F.addclassD(75,30, Sheet.ReadAsNumber(I,col));
                try
                    Env.Crown.F.fractionise;
                except
                    on E:EMathError do
                        Raise EInOutError.Create('At least one crown leaf angle class must not be zero');
                end;
                inc(col);
                Env.Crown.F.a_L:=Sheet.ReadAsNumber(I,col);

                // Add leaves and leaf angle classes
                Env.Vegetation.F.Clear;
                inc(col);
                Env.Vegetation.F.F:=Sheet.ReadAsNumber(I,col);
                // Calculate leaf area density from vegetation LAI and thickness
                Env.Vegetation.F.F:=Env.Vegetation.F.F/(Env.Vegetation.h_t-Env.Vegetation.h_b);
                inc(col);
                Env.Vegetation.F.addclassD(15,30, Sheet.ReadAsNumber(I,col));
                inc(col);
                Env.Vegetation.F.addclassD(45,30, Sheet.ReadAsNumber(I,col));
                inc(col);
                Env.Vegetation.F.addclassD(75,30, Sheet.ReadAsNumber(I,col));
                try
                    Env.Vegetation.F.fractionise;
                except
                    on E:EMathError do
                        Raise EInOutError.Create('At least one vegetation leaf angle class must not be zero');
                end;
                inc(col);
                Env.Vegetation.F.a_L:=Sheet.ReadAsNumber(I,col);
                Env.Light.c:=c;
                Env.Light.I_H:=I_H;

                inc(col);
                Phot.N_top:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Phot.a_N:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Phot.a_P:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Phot.b_P:=Sheet.ReadAsNumber(I,col);
                inc(col);
                // This column can be empty
                tmpS:=Sheet.ReadAsUTF8Text(I,col);
                if tmpS='' then
                begin
                    Phot.p_lin:=true;
                    tmpS:='0';
                end
                else
                    Phot.p_lin:=false;
                Phot.c_P:=StrToFloat(tmpS);
                inc(col);
                // This column can be empty
                tmpS:=Sheet.ReadAsUTF8Text(I,col);
                if tmpS='' then
                    tmpS:='0';
                Phot.a_R:=StrToFloat(tmpS);
                inc(col);
                Phot.b_R:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Phot.phi:=Sheet.ReadAsNumber(I,col);
                inc(col);
                Phot.theta:=Sheet.ReadAsNumber(I,col);

                SetLength(Plot.Plants,Length(Plot.Plants)+1);
                SetLength(Plot.Heights,Length(Plot.Plants));
                Plot.Plants[High(Plot.Plants)]:=Ellipsoid;
                Plot.Heights[High(Plot.Plants)]:=PlHeight;

                Ellipsoid:=TEllipsoid.Create;
                Env:=Ellipsoid.Ring.Ellipse.Env;
                Phot:=Ellipsoid.Ring.Ellipse.Env.Photosynthesis;
                Result:=I-9;
            end;
         except
              on E: Exception do
              begin
                  Result:=0;  // 0 plants correctly read
                  Plot.Clear; // Clear everything read so far
                  ShowMessage(' '+E.Message+' in row '+IntToStr(I)+', column "'+colnames[col-1]+'".');
              end;
        end;
    finally
        FreeAndNil(ColNames);
        FreeAndNil(Ellipsoid);
        FreeAndNil(WorkBook);
    end;
end;

function ReadPlot.ReadData(Plot: TPlot; FileName: String): Integer;
begin
    Result:=0;
    if UpperCase(ExtractFileExt(FileName))='.CSV' then
        result:=ReadCSVData(Plot,FileName);
    if UpperCase(ExtractFileExt(FileName))='.XLS' then
        result:=ReadExcelData(Plot,FileName);
end;

{ TWriteExcel }

function TWriteExcel.Write(Plot:TPlot; xlsname : String): boolean;
var
    name_int,
    row, col, i : integer;
begin
    XlsOpen(xlsname);
    row:=0;
    XlsWriteCellLabel(0,row,'PHOLIAGE model results');
    inc(row);
    XlsWriteCellLabel(0,row,'Plot details');
    inc(row);
    XlsWriteCellLabel(0,row,'Name');
    XlsWriteCellLabel(1,row,'Location');
    inc(row);
    XlsWriteCellLabel(0,row,AnsiString(Plot.Name));
    XlsWriteCellLabel(1,row,AnsiString(Plot.Location));
    inc(row);
    XlsWriteCellLabel(0,row,'Results');
    inc(row);
    XlsWriteCellLabel(0,row,'Plant ID');
    XlsWriteCellLabel(1,row,'PPFD absorbed');
    XlsWriteCellLabel(2,row,'Net photosynthesis');
    inc(row);
    for i:=0 to High(Plot.Plants) do
        with Plot.Plants[i] do
        begin
            col:=0;
            try
                name_int:=strtoint(name);
                XlsWriteCellRk(col,row,name_int); // save as integer
            except
                XlsWriteCellLabel(col,row,AnsiString(name)); // save as string
            end;
            Inc(Col);
            XlsWriteCellNumber(col,row,Plot.AbsResults[i]);
            Inc(Col);
            XlsWriteCellNumber(col,row,Plot.PhotResults[i]);
            Inc(Row);

        end;

    XlsClose;

    result:=true;

end;


Function TMyCSV.GetFieldText(Row,Col:Integer):String;
var s:String;StartPos,EndPos,SLen,fY:Integer;
begin
    Dec(Row);
    Dec(Col);
    Result:='';
    if Row<Count then
    begin
        s:=Strings[Row];
        fY:=0;
        StartPos:=1;
        EndPos:=1;
        SLen:=length(s);
        While EndPos<= SLen do
        begin
            if s[EndPos]=separator then
            begin
                if fY=Col then Break;
                StartPos:=EndPos+1;
                Inc(fY);
            end;
            inc(EndPos);
        end;
        if fY=Col then result:=copy(s,StartPos,EndPos-StartPos);
    end;
end;

procedure TMyCSV.SetFieldText(Row,Col:Integer;Value:String);
var
    s : String;
    StartPos,
    EndPos,
    SLen,
    fY : Integer;
    FieldModified : Boolean;
begin
    Dec(Row);
    Dec(Col);
    FieldModified:=False;
    if Row>=Count then
    begin
        for fy:=0 to Row-Count do
            Add('');
    end;
    s:=Strings[Row];
    fY:=0;
    StartPos:=1;
    EndPos:=1;
    SLen:=length(s);
    While EndPos<= SLen do
    begin
        if s[EndPos]=separator then
        begin
            if fY=col then
            begin
                S:=copy(s,0,StartPos-1)+Value+copy(s,EndPos,SLen);
                FieldModified:=True;
                Break;
            end;
            StartPos:=EndPos+1;
            Inc(fY);
        end;
        inc(EndPos);
    end;
    if not FieldModified then
    begin
        for StartPos:=0 to col-fY-1 do
            S:=S+separator;
        S:=S+Value;
    end;
    Strings[Row]:=s;
end;

procedure  TMyCSV.LoadFile(const FileName:String);
var
  Stream  : TStream;
  Size    : Int64;
  S,
  CurrentLine : string;
  EndPos,
  StartPos : Integer;

begin
    Clear;
    CurrentLine:='';
    StartPos:=1;
    EndPos:=1;
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
        Stream.Position:=0;
        Size := Stream.Size;
        SetString(S, nil, Size);
        Stream.Read(Pointer(S)^, Size);
    finally
        FreeAndNil(Stream);
    end;
    while EndPos <= Size do
    begin
        if (S[EndPos] + S[EndPos + 1] = #13#10) or (EndPos=Size) then
        begin
            CurrentLine:=CurrentLine+','+copy(S,StartPos,EndPos-StartPos);
            CurrentLine:=Copy(CurrentLine,2,length(CurrentLine));
            Add(CurrentLine);
            CurrentLine:='';
            StartPos:=EndPos+2;
            Inc(EndPos);
        end
        else
        if S[EndPos] = separator then
        begin
            CurrentLine:=CurrentLine+','+copy(S,StartPos,EndPos-StartPos);
            StartPos:=EndPos+1;
        end;
        Inc(EndPos);
    end;
end;

constructor TMyCSV2.Create(FileName:String; sep : Char);
begin
    inherited Create;
    separator := sep;
    LoadFile(FileName);
end;

function TMyCSV2.GetFieldText(Row, Col: Integer): String;
begin
    if Row>m_RowCount then
        result := ''
    else
        if Col>m_ColCount then
            result := ''
        else
            result:=data[row-1,col-1];
end;

function TMyCSV2.GetFieldTextD(Row, Col: Integer): Double;
begin
    if Row>m_RowCount then
        result := 0
    else
        if Col>m_ColCount then
            result := 0
        else
            result:=StrToFloat(data[row-1,col-1]);
end;

procedure TMyCSV2.LoadFile(const FileName: string);
var
  Stream  : TStream;
  Size    : Int64;
  S       : string;
  Start,ArraySize :Integer;
  Y, I, X : Integer;
begin
  Start:=1;
  I := 1;   // Placeholder
  X := 0;   // Holds Horz. Position
  Y := 0;   // Array Vert. Position
  ArraySize:=0;
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Stream.Position:=0;
    Size := Stream.Size;
    SetString(S, nil, Size);
    Stream.Read(Pointer(S)^, Size);
  finally
    FreeAndNil(Stream);
  end;
  while I <= Size do
  begin
    ArraySize:=Max(X,ArraySize);
    m_RowCount:=Y+1;
    m_ColCount:=ArraySize+1;
    SetLength(Data, Y + 1, ArraySize + 1);

    if S[i] + S[I + 1] = #13#10 then
    begin
      Data[Y, X] := Copy(S,Start,I-Start);
      Start:=I+2;
      Inc(Y);
      Inc(I);
      X:=0;
    end
    else if S[i] = separator then
    begin
      Data [Y, X] := Copy(S,Start,I-Start);
      Start:=I+1;
      inc(X);
    end
    else if I=Size then Data[Y, X] := Copy(S,Start,I-Start);

    Inc(I);
  end;
end;

function TSheet.ReadAsUTF8Text(ARow, ACol: Cardinal): string;
begin
    Result := inherited ReadAsUTF8Text(ARow-1, ACol-1);
end;

function TSheet.ReadAsNumber(ARow, ACol: Cardinal): Double;
begin
    Result := inherited ReadAsNumber(ARow-1, ACol-1);
end;

end.
