unit Ellipsoid_Integration;

//
// PHOLIAGE Model, (c) Roelof Oomen, 2006-2007
//
// Model integration methods
//

interface

uses
    Model_Absorption, GaussInt;

type
    TEllipse = class(TGaussIntA)
    private
        r : Double; // Radius of circle transformation at Z
        Z : Double; // Z-Coordinate in sphere transformation
    public
        Env : TEnvironment;
        function fuGI(const xGI:Double): GIResult; override;
        constructor Create;
        destructor Destroy; override;
    end;

    TRing = class(TGaussIntA)
    public
        Ellipse : TEllipse;
        constructor Create;
        destructor Destroy; override;
        function fuGI(const xGI:Double): GIResult; override;
    end;

    TEllipsoid = class(TGaussIntA)
    private
        procedure SetgpPsi(val : Integer);
        function  GetgpPsi : Integer;
        procedure SetgpR(val : Integer);
        function  GetgpR : Integer;
        procedure SetgpZ(val : Integer);
        function  GetgpZ : Integer;
    public
        Ring : TRing;

        Name : String; // Plant's identifier

        constructor Create;
        destructor Destroy; override;

        function fuGI(const xGI:Double): GIResult; override;
        function Calculate: GIResult;

        // Number of gaussian integration points for each integral
        property gpZ   : Integer read GetgpZ write SetgpZ;
        property gpPsi : Integer read GetgpPsi write SetgpPsi;
        property gpR   : Integer read GetgpR write SetgpR;
    end;

    TPlot = class
        // Identification
        Name       : String;
        Location   : String;
        // Array of plant calculation classes
        Plants     : Array of TEllipsoid;
        // Heights of Plants, used to calculate correct vegetation heights
        //   relative to ellipsoid center
        Heights    : Array of Double;
        // Results of light absorption calculations
        AbsResults : GIResult;
        // Results of photosynthesis calculations
        PhotResults : GIResult;

        // Frees Plant, Heights and AbsResults arrays
        procedure Clear;

        // Call to make sure Plant array objects are freed
        destructor Destroy; override;
    end;

implementation

uses
    SysUtils, Vector, Paths;

function TEllipse.fuGI(const xGI:Double): GIResult;
var
    p : TVectorC;
begin
    // As We integrate over a unit sphere, instead of the original ellipsoidal
    //   crown, we have to translate parameter p to a point p in the crown.
    //   We have to transform the cylindrical coordinates (r, psi, Z)
    //   (with xGI as psi), used for integrating, to Cartesian coordinates to be
    //   able to translate over three orthonormal ellipsoid axes.

    p.x:=(r*cos(xGI))*Env.Crown.a;
    p.y:=(r*sin(xGI))*Env.Crown.b;
    p.z:=Z*Env.Crown.c;
    SetLength(Result, 2);
    result[0]:=Env.Absorption.I( p );
    result[1]:=Env.Assimilation.P_tot( p );
end;

constructor TEllipse.Create;
begin
	inherited Create;
    if not assigned(Env) then
        Env:=TEnvironment.Create;
    // Initialise for testing purposes, when TEllipse is used stand-alone
    r:=1;
    Z:=0;
    x_min:=0;
    x_max:=2*pi;
end;

destructor TEllipse.Destroy;
begin
    FreeAndNil(Env);
	inherited Destroy;
end;

function TRing.fuGI(const xGI:Double): GIResult;
var
  I: Integer;
begin
    Ellipse.r:=xGI;
    result:=Ellipse.integrate;// Default: (0,2*pi)
    for I := 0 to High(result) do
        result[I]:=Ellipse.r*result[I];
end;

constructor TRing.Create;
begin
	inherited Create;
    Ellipse:=TEllipse.Create;
end;

destructor TRing.Destroy;
begin
    FreeAndNil(Ellipse);
	inherited Destroy;
end;

function TEllipsoid.fuGI(const xGI:Double): GIResult;
begin
    Ring.Ellipse.Z:=xGI;
    result:=Ring.integrate(0,sqrt(1-sqr(Ring.Ellipse.Z)));
end;

function TEllipsoid.Calculate: GIResult;
var
  I: Integer;
  GIR : GIResult;
  p : TVectorC;
begin
    // Initialise light at the top of the ellipsoid, used for the nitrogen distr
    p.x:=0;
    p.y:=0;
    p.z:=Ring.Ellipse.Env.Crown.c;
    // Divide light by a_L as we want the incident and not the absorbed light
    Ring.Ellipse.Env.Photosynthesis.I_top:=Ring.Ellipse.Env.Absorption.I( p )/Ring.Ellipse.Env.Crown.F.a_L;

    // Actual calculation
    GIR:=integrate; // Default: (-1,1)
    SetLength(result, Length(GIR));
    // Translate to ellipsoid
    for I := 0 to High(GIR) do
        result[I]:=Ring.Ellipse.Env.crown.a*Ring.Ellipse.Env.crown.b*Ring.Ellipse.Env.crown.c*GIR[I];
end;

constructor TEllipsoid.Create;
begin
	inherited Create;
    Ring:=TRing.Create;
    x_min:=-1;
    x_max:=1;
end;

destructor TEllipsoid.Destroy;
begin
    FreeAndNil(Ring);
	inherited Destroy;
end;

function TEllipsoid.GetgpZ: Integer;
begin
    result:=GP;
end;

procedure TEllipsoid.SetgpZ(val : Integer);
begin
    GP:=val;
end;

function TEllipsoid.GetgpPsi: Integer;
begin
    result:=Ring.Ellipse.GP;
end;

procedure TEllipsoid.SetgpPsi(val : Integer);
begin
    Ring.Ellipse.GP:=val;
end;

function TEllipsoid.GetgpR: Integer;
begin
    result:=Ring.GP;
end;

procedure TEllipsoid.SetgpR(val : Integer);
begin
    Ring.GP:=val;
end;

{ TPlot }

procedure TPlot.Clear;
var
    I : Integer;
begin
    // Clean up
    for I := 0 to High(Plants) do
        FreeAndNil(Plants[I]);
    SetLength(Plants, 0);
    SetLength(Heights,0);
    SetLength(AbsResults,0);
    SetLength(PhotResults,0);
end;

destructor TPlot.Destroy;
begin
    Clear;
    inherited;
end;

end.
