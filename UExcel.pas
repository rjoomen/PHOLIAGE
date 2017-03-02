unit UExcel;

// Native methods for writing a simple Excel file
// Based on source by Fatih Olcer published in this article:
//   http://www.swissdelphicenter.ch/en/showcode.php?id=725

interface

uses
    classes, SysUtils;

type
    WriteXLS = class
      private
        XLSStream: TFileStream;
        procedure XlsBeginStream(_XlsStream: TStream; const BuildNumber: Word);
        procedure XlsEndStream(_XlsStream: TStream);
      public
        function xlsopen(filename: string):boolean;
        procedure xlsclose;

        // Integer
        procedure XlsWriteCellRk(const ACol, ARow: Word;
            const AValue: Integer);
        // Floating point number
        procedure XlsWriteCellNumber(const ACol, ARow: Word;
            const AValue: Double);
        // String
        procedure XlsWriteCellLabel(const ACol, ARow: Word;
            const AValue: AnsiString);
    end;


implementation

var
  CXlsBof: array[0..5] of Word = ($809, 8, 00, $10, 0, 0); 
  CXlsEof: array[0..1] of Word = ($0A, 00); 
  CXlsLabel: array[0..5] of Word = ($204, 0, 0, 0, 0, 0);
  CXlsNumber: array[0..4] of Word = ($203, 14, 0, 0, 0); 
  CXlsRk: array[0..4] of Word = ($27E, 10, 0, 0, 0); 

procedure WriteXLS.XlsBeginStream(_XlsStream: TStream; const BuildNumber: Word);
begin 
  CXlsBof[4] := BuildNumber;
  _XlsStream.WriteBuffer(CXlsBof, SizeOf(CXlsBof)); 
end;

procedure WriteXLS.XlsEndStream(_XlsStream: TStream);
begin 
  _XlsStream.WriteBuffer(CXlsEof, SizeOf(CXlsEof));
end;

procedure WriteXLS.XlsWriteCellRk(const ACol, ARow: Word;
  const AValue: Integer);
var 
  V: Integer; 
begin
  CXlsRk[2] := ARow;
  CXlsRk[3] := ACol; 
  XlsStream.WriteBuffer(CXlsRk, SizeOf(CXlsRk)); 
  V := (AValue shl 2) or 2;
  XlsStream.WriteBuffer(V, 4);
end;

procedure WriteXLS.XlsWriteCellNumber(const ACol, ARow: Word;
  const AValue: Double);
begin
  CXlsNumber[2] := ARow;
  CXlsNumber[3] := ACol;
  XlsStream.WriteBuffer(CXlsNumber, SizeOf(CXlsNumber));
  XlsStream.WriteBuffer(AValue, 8);
end;

procedure WriteXLS.XlsWriteCellLabel(const ACol, ARow: Word;
  const AValue: AnsiString);
var
  L: Word;
begin
  L := Length(AValue);
  CXlsLabel[1] := 8 + L;
  CXlsLabel[2] := ARow;
  CXlsLabel[3] := ACol;
  CXlsLabel[5] := L;
  XlsStream.WriteBuffer(CXlsLabel, SizeOf(CXlsLabel));
  XlsStream.WriteBuffer(Pointer(AValue)^, L);
end;

function WriteXLS.xlsopen(filename: string): boolean;
begin
    XlsStream := TFileStream.Create(filename, fmCreate);
    try
        XlsBeginStream(XlsStream, 0);
        result := true;
    except
        freeandnil(XlsStream);
        result := false;
    end;
end;

procedure WriteXLS.xlsclose;
begin
    XlsEndStream(XlsStream);
    freeandnil(XlsStream);
end;

// Links for Excel file reading and writing in Delphi

// Delphi 3 and Automation with Excel. --> Includes wrapper class!
// http://vzone.virgin.net/graham.marshall/excel.htm

// How to use a variant array to write data to Excel in one go
// http://www.lmc-mediaagentur.de/dpool/tips/1485.htm

// Excel OLE Tips for Everyone
// http://www.undu.com/DN970501/00000021.htm

// create an Excel File without OLE?
// http://www.swissdelphicenter.ch/en/showcode.php?id=725

// control Excel with OLE?
// http://www.swissdelphicenter.ch/en/showcode.php?id=156

// Delphi and Microsoft Office: Automating Excel and Word - by Charles Calvert
// http://community.borland.com/article/0,1410,10126,00.html

// check for excel
{ var
  ClassID: TCLSID;
  strOLEObject: string;
begin
  strOLEObject := 'Excel.Application';
  if (CLSIDFromProgID(PWideChar(WideString(strOLEObject)), ClassID) = S_OK)
then
  begin
    // application is installed
  end
  else
  begin
    // application is not installed
  end
end;
}

end.

