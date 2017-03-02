unit Model_Absorption;

//
// PHOLIAGE Model, (c) Roelof Oomen, 2006-2007
//
// Model data definitions and calculation methods
//

interface

// Use table lookup instead of calculating everything every time
// Speeds up program enormously
{$DEFINE TABLES}
// Use old (non-Kf based) absorption calculation
{ $DEFINE OLDABS}

uses
    Paths, Vector, GaussInt;

type
    /// Calculates light for a given pathlength through a vegetation
    ///   Note: Be sure to assign Crown and Vegetation! (normally done by TAbsorption)
    TLight = class(TGaussInt)
    private
        _c : Double; // Internal c variable
        _I_H : double; // Internal I_H variable
        _AzWidth   : double;

        // Setters make sure I_omega_0 is updated
        procedure setC(const Value: Double);
        procedure setI_H(const Value: Double);

        /// Calculates i_omega_0
        function i_omega_0_calc:double;
        procedure setAzWidth(const Value: Double);
    protected
        function fuGI(const xGI: Double): Double; override;
    public
        Crown      : TCrown;      // Calculates path length through crown
        Vegetation : TVegetationCircular; // Calculates path length through surrounding vegetation
        // TODO: Remove extinction - but how interwoven is this with TAbsorption?
        Extinction : TExtinction;

        i_omega_0 : double;

        /// Curvature of light function, default = 2
        property c : Double read _c write setC;
        /// Total light intensity on the horizontal plane, default = 1000
        property I_H : Double read _I_H write setI_H;
        // Azimuthal width of the light distribution, normally 2pi
        property AzWidth : Double read _AzWidth write setAzWidth;

        // Light model from Van Bentum and Schieving, 2007, unpublished
        function i_omega_f(const Theta: Double): double;
        function i_omega(const p, d_i: TVectorS; stepPol, stepAz, id: integer): double;

        constructor Create; // Instantiates Extinction, Crown and Vegetation
        destructor  Destroy; override;
    end;

// *** Absorption speed per unit crown volume ********************************************
{$IFNDEF OLDABS}
    ///Integration class of azimuth part of total absorption
    TAbsorptionAz = class(TGaussInt)
    strict private
        d_i,
        p  : TVectorS;
        stepPol : Integer;

    protected
        function fuGI(const xGI: Double): Double; override;

    public
        Light : TLight;

        function    AzInt(const _p, _d_i : TVectorS; _stepPol : integer): double;

        constructor Create; // Instantiates Light
        destructor  Destroy; override;
    end;

    ///Total light absorption speed
    TAbsorption = Class(TGaussInt)
    strict private
        p,                 // Point for which to calculate absorption
        d_i : TVectorS;

    private
        procedure GP_w(Value : integer);
        function number_N: integer;     // Leaf normal

    protected
        function fuGI(const xGI: Double): Double; override;

    public
        AbsorptionAz : TAbsorptionAz; // Azimuth integration

        function I(const _p : TVectorS ) : Double; virtual;

        // Set both own and AbsorptionAz's GP
        property    GP : integer read number_N write GP_w;

        constructor Create; // Instantiates AbsorptionKfAz
        destructor  Destroy; override;
    end;
{$ENDIF}
// *** Photosynthesis speed per unit leaf area ********************************************

    TPhotosynthesis = class
    public
        // Quantum yield
        phi : Double;
        // Curvature
        theta : Double;
        // Slope, y-intercept, asymptotic maximum of photosynthesis hyperbola
        a_P, b_P, c_P : Double;
        // Slope, y-intercept of dark respiration function
        a_R, b_R : Double;
        // Indicates whether a linear or a hyperbolic photosynthesis function is used
        p_lin : Boolean;
        // Light at the top of the crown
        I_top : Double;
        // Nitrogen content
        N_top : Double;
        // Nitrogen coefficient
        a_N : Double;

        // Nitrogen at a certain point (expressed as a light level) in the crown
        function N( I : Double) : Double;
        // Dark respiration
        function R_d( _N : Double): Double;
        // Light saturated rate of gross photosynthesis
        function p_m( _N : Double): Double;
        // Photosynthesis, based on absorbed light I
        function p_L(const I, _N : Double ) : Double; overload;
        // This is p_L( I, N( I ) )
        function p_L(const I : Double ) : Double; overload;
    end;

// *********************** Incident light routines ***********************

/// Integration class of azimuth part of absorption per unit leaf area
    ///   Note: Be sure Light is assigned! (normally done by TAbsorption)
    TIncidentLAz = class(TGaussInt)
    strict private
        d_L,
        d_i,
        p  : TVectorS;
        // Integration step of Polar LAbsorption integral (TIncidentL)
        stepPol : Integer;
    protected
        function fuGI(const xGI: Double): Double; override;
    public
        Light      : TLight;      // Calculates light climate and extinction

        function AzInt(const _p, _d_L, _d_i: TVectorS; _stepPol:integer): double;

        constructor Create; // Instantiates Light
        destructor  Destroy; override;
    end;

    /// Incident light per unit leaf area for leaves with normal d_L
    TIncidentL = Class(TGaussInt)
    strict private
        p,                 // Point for which to calculate light
        d_i,               // Inverse direction of light beam
        d_L : TVectorS;

    private
        procedure GP_w(const Value: integer);
        function number_N: integer;     // Leaf normal
    protected
        function fuGI(const xGI: Double): Double; override;

    public
        IncidentLAz : TIncidentLAz; // Azimuth integration

        function I_L(const _p, _d_L : TVectorS ) : double;

        // Set both own and IncidentLAz's GP
        property GP : integer read number_N write GP_w;
        constructor Create; // Instantiates IncidentLAz
        destructor  Destroy; override;
    End;

// *** Total light absorption at point p ***************************************
{$IFDEF OLDABS}
    /// Integration class of azimuth part of total absorption
    TAbsorptionAz = class(TGaussInt)
    strict private
        d_L,
        p  : TVectorS;
    protected
        function fuGI(const xGI: Double): Double; override;

    public

        IncidentL : TIncidentL;

        function AzInt(const _p, _d_L : TVectorS): double;

        constructor Create;
        destructor  Destroy; override;
    end;

    /// Total light absorption
    TAbsorption = Class(TGaussInt)
    strict private
        p,                 // Point for which to calculate absorption
        d_L : TVectorS;

    private
        procedure GP_w(const Value: integer);
        function number_N: integer;     // Leaf normal

    protected
        function fuGI(const xGI: Double): Double; override;

    public
        AbsorptionAz : TAbsorptionAz; // Azimuth integration

        function I(const _p : TVectorS ) : Double; virtual;

        // Set both own and AbsorptionAz's GP
        property    GP : integer read number_N write GP_w;

        constructor Create;
        destructor  Destroy; override;
    End;
{$ENDIF}

    /// Integration class of azimuth part of total assimilation
    TAssimilationAz = class(TGaussInt)
    strict private
        d_L,
        p  : TVectorS;
    protected
        function fuGI(const xGI: Double): Double; override;

    public

        IncidentL : TIncidentL;
        Photosynthesis : TPhotosynthesis;

        function AzInt(const _p, _d_L : TVectorS): double;

        constructor Create; // Instantiates IncidentL and Photosynthesis
        destructor  Destroy; override;
    end;

    /// Total assimilation speed
    TAssimilation = Class(TGaussInt)
    strict private
        p,                 // Point for which to calculate assimilation
        d_L : TVectorS;

    private
        procedure GP_w(const Value: integer);
        function number_N: integer;     // Leaf normal

    protected
        function fuGI(const xGI: Double): Double; override;

    public
        AssimilationAz : TAssimilationAz; // Azimuth integration

        function P_tot(const _p : TVectorS) : Double; virtual;

        // Set both own and AssimilationAz's GP
        property    GP : integer read number_N write GP_w;

        constructor Create; // Instantiates AssimilationAz
        destructor  Destroy; override;
    End;

    TEnvironment = class
    public
        Light          : TLight;
        Photosynthesis : TPhotosynthesis;
        Crown          : TCrown;
        Vegetation     : TVegetationCircular;

        Assimilation   : TAssimilation;
        Absorption     : TAbsorption;

        constructor Create;
        destructor Destroy; override;
    end;

implementation

uses
    Math, SysUtils;

{ *** TAbsorptionAz ***************************************************************** }
{$IFNDEF OLDABS}
constructor TAbsorptionAz.Create;
begin
    inherited;
    Light:=TLight.Create;
    x_min:=0;
    x_max:=2*pi;
end;

destructor TAbsorptionAz.Destroy;
begin
    FreeAndNil(Light);
	inherited Destroy;
end;

function TAbsorptionAz.fuGI(const xGI: Double): Double;
// xGI is psi_L
begin
    d_i.psi:=xGI;
    result:=Light.i_omega(p, d_i, stepPol,step, 0)*Light.Extinction.Kf(d_i, Light.Crown.F, stepPol, step, 0);
end;

function TAbsorptionAz.AzInt(const _p, _d_i : TVectorS; _stepPol : integer): double;
begin
    p:=_p;
    d_i:=_d_i;
    stepPol:=_stepPol;
    result:=integrate; // Default: (0, 2*pi)
end;

{ *** TAbsorption ***************************************************************** }

constructor TAbsorption.Create;
begin
    inherited Create;
    // Initialise
    AbsorptionAz:=TAbsorptionAz.Create;
    x_min:=0;
    x_max:=pi/2;
end;

destructor TAbsorption.Destroy;
begin
  FreeAndNil(AbsorptionAz);
  inherited;
end;

function TAbsorption.fuGI(const xGI: Double): Double;
// xGI is theta_L
begin
    d_i.theta:=xGi;
    result:=sin(d_i.theta)*AbsorptionAz.AzInt(p, d_i, step);
end;

function TAbsorption.I(const _p : TVectorS ): Double;
begin
    p:=_p;
    d_i.r:=1;
    result:=integrate;// Default: (0,pi/2)
end;

procedure TAbsorption.GP_w(Value : integer);
begin
    inherited GP:=Value;
    AbsorptionAz.GP:=Value;
end;

function TAbsorption.number_N: integer;
begin
    Result:=inherited GP;
end;
{$ENDIF}
{ *** TLight ***************************************************************** }

constructor TLight.Create;
begin
    inherited;
    Extinction:=TExtinction.Create;
    Crown:=TCrown.Create;
    Vegetation:=TVegetationCircular.Create;
    x_min:=0;
    x_max:=pi/2;
    _AzWidth:=2*pi;
    c:=2;
    I_H:=1000;
end;

destructor TLight.Destroy;
begin
    FreeAndNil(Vegetation);
    FreeAndNil(Crown);
    FreeAndNil(Extinction);
    inherited;
end;

procedure TLight.setAzWidth(const Value: Double);
begin
    _AzWidth:=Value;
    i_omega_0:=i_omega_0_calc;
end;

procedure TLight.setC(const Value: Double);
begin
    _c:=value;
    i_omega_0:=i_omega_0_calc;
end;

procedure TLight.setI_H(const Value: Double);
begin
    _I_H:=value;
    i_omega_0:=i_omega_0_calc;
end;

function TLight.fuGI(const xGI: Double): Double;
begin
    result:=sin(xGI)*cos(xGI)*(1-Power(sin(xGI),c));
end;

function TLight.i_omega_0_calc: double;
begin
    result:=I_H/(AzWidth*integrate);// Default: (0,pi/2)
end;

function TLight.i_omega_f(const Theta: Double): double;
begin
    result:=i_omega_0*(1-power(sin(theta),c));
end;

function TLight.i_omega(const p, d_i: TVectorS; stepPol, stepAz, id: integer): double;
begin
    // We have to be sure that Crown.pathlength is calulated first,
    //   as Vegetation.pathlength uses Crown.q as input. By placing extra
    //   parentheses around Kf()*Crown.pathlength() we make sure this expression
    //   is evaluated before Kf()*Vegetation.pathlength()
    //   (See also: "Operator Precedence" in Delphi help)
    result := i_omega_f(d_i.theta) * exp(
//        -( ( Extinction.Kf(d_i,Crown.F, stepPol, stepAz, id)      * Crown.pathlength(p, d_i) ) +
             Crown.Attenuation(p, d_i, stepPol, stepAz, id) +
//            Extinction.Kf(d_i, Vegetation.F, stepPol, stepAz, id) * Vegetation.pathlength(Crown.q, d_i) ));
             Vegetation.Attenuation(Crown.q, d_i, stepPol, stepAz, id) );
end;

function TPhotosynthesis.R_d( _N: Double): Double;
begin
    Result := a_R * _N + b_R;
end;

function TPhotosynthesis.p_m( _N: Double): Double;
begin
    if p_lin then  // Linear Pmax relation
        Result := a_P*_N + b_P
    else           // Hyperbolic Pmax relation
        Result := (a_P*_N + b_P)*c_P / ((a_P*_N + b_P)+c_P);
end;

function TPhotosynthesis.N(I: Double): Double;
begin
    Result:=N_top * Power(I/I_top,a_N);
end;

function TPhotosynthesis.p_L(const I, _N : Double ): Double;
begin
    Result:=((p_m(_N)+I*phi)- sqrt( sqr(p_m(_N)+I*phi)-(4*theta*p_m(_N)*I*phi) ))
            /(2*theta) - R_d(_N);
end;

function TPhotosynthesis.p_L(const I: Double): Double;
begin
    Result:=p_L(I, N(I));
end;

{ *** TLAbsorptionAz ********************************************************* }

constructor TIncidentLAz.Create;
begin
    inherited;
    Light:=TLight.Create;
    x_min:=0;
    x_max:=2*pi;
end;

destructor TIncidentLAz.Destroy;
begin
    FreeAndNil(Light);
    inherited;
end;

function TIncidentLAz.fuGI(const xGI: Double): Double;
// xGI is psi_i
begin
    d_i.psi:=xGI;
    result:=abs(d_L*d_i)*Light.i_omega(p, d_i, stepPol, step, 1);
end;

function TIncidentLAz.AzInt(const _p, _d_L, _d_i: TVectorS; _stepPol: integer): double;
begin
    p:=_p;
    d_L:=_d_L;
    d_i:=_d_i;
    stepPol:=_stepPol;
    result:=integrate; // Default: (0,2*pi)
end;

{ *** TLAbsorption *********************************************************** }

constructor TIncidentL.Create;
begin
    inherited Create;
    IncidentLAz:=TIncidentLAz.Create;
    x_min:=0;
    x_max:=pi/2;
end;

destructor TIncidentL.Destroy;
begin
    FreeAndNil(IncidentLAz);
    inherited;
end;

function TIncidentL.fuGI(const xGI: Double): Double;
// xGI is theta_i
begin
    d_i.theta:=xGI;
    result:=sin(xGI)*IncidentLAz.AzInt(p,d_L,d_i,step);
end;

procedure TIncidentL.GP_w(const Value: integer);
begin
    inherited GP:=Value;
    IncidentLAz.GP:=Value;
end;

function TIncidentL.I_L(const _p, _d_L : TVectorS ) : double;
begin
    p := _p;
    d_L:=_d_L;
    d_i.r:=1;
    result:=integrate; // Default: (0,pi/2)
end;

function TIncidentL.number_N: integer;
begin
    result:=inherited GP;
end;

{ *** TAbsorptionAz ********************************************************** }
{$IFDEF OLDABS}
constructor TAbsorptionAz.Create;
begin
	inherited Create;
    IncidentL:=TIncidentL.Create;
    x_min:=0;
    x_max:=2*pi;
end;

destructor TAbsorptionAz.Destroy;
begin
    FreeAndNil(IncidentL);
	inherited Destroy;
end;

function TAbsorptionAz.fuGI(const xGI: Double): Double;
// xGI is psi_L
begin
    d_L.psi:=xGI;
    result:=IncidentL.I_L(p, d_L);
end;

function TAbsorptionAz.AzInt(const _p, _d_L: TVectorS): double;
begin
    p:=_p;
    d_L:=_d_L;
    result:=integrate; // Default: (0, 2*pi)
end;

{ *** TAbsorption ************************************************************ }

constructor TAbsorption.Create;
begin
    inherited Create;
    AbsorptionAz:=TAbsorptionAz.Create;
    // Initialise
    x_min:=0;
    x_max:=pi/2;
end;

destructor TAbsorption.Destroy;
begin
  FreeAndNil(AbsorptionAz);
  inherited;
end;

function TAbsorption.fuGI(const xGI: Double): Double;
// xGI is theta_L
begin
    d_L.theta:=xGi;
    With AbsorptionAz.IncidentL.IncidentLAz.Light do
        result:=sin(d_L.theta)*Crown.F.f_omega(d_L.theta)*AbsorptionAz.AzInt(p, d_L);
end;

function TAbsorption.I(const _p: TVectorS): double;
var
    J : Integer;
begin
    p:=_p;
    d_L.r:=1;
    // Should integrate over theta_L angles 0 to 1/2 pi
    // Integration is divided over the angle classes, as the transition
    //   between these classes is not continuous.
    result:=0;
    With AbsorptionAz.IncidentL.IncidentLAz.Light do
        for J := 0 to High(Crown.F.AngleClasses) do
            result:=result+Crown.F.a_L*self.integrate((Crown.F.AngleClasses[J].Mid-(0.5*Crown.F.AngleClasses[J].Width)),(Crown.F.AngleClasses[J].Mid+(0.5*Crown.F.AngleClasses[J].Width)));// Default: (0,pi/2)
end;

procedure TAbsorption.GP_w(const Value: integer);
begin
    inherited GP:=Value;
    AbsorptionAz.GP:=Value;
end;

function TAbsorption.number_N: integer;
begin
    Result:=inherited GP;
end;
{$ENDIF}

{ *** TAssimilationAz ********************************************************** }

constructor TAssimilationAz.Create;
begin
	inherited Create;
    IncidentL:=TIncidentL.Create;
    Photosynthesis:=TPhotosynthesis.Create;
    x_min:=0;
    x_max:=2*pi;
end;

destructor TAssimilationAz.Destroy;
begin
    FreeAndNil(Photosynthesis);
    FreeAndNil(IncidentL);
	inherited Destroy;
end;

function TAssimilationAz.fuGI(const xGI: Double): Double;
// xGI is psi_L
begin
    d_L.psi:=xGI;
    result:=Photosynthesis.p_L(IncidentL.I_L(p,d_L));
    // For testing this integration use the following, then P should yield
    //   the same as I.
//    result:=IncidentL.IncidentLAz.Light.Crown.F.a_L*IncidentL.I_L(p,d_L);
end;

function TAssimilationAz.AzInt(const _p, _d_L: TVectorS): double;
begin
    p:=_p;
    d_L:=_d_L;
    result:=integrate; // Default: (0, 2*pi)
end;

{ *** TAssimilation ************************************************************ }

constructor TAssimilation.Create;
begin
    inherited Create;
    AssimilationAz:=TAssimilationAz.Create;
    x_min:=0;
    x_max:=pi/2;
end;

destructor TAssimilation.Destroy;
begin
  FreeAndNil(AssimilationAz);
  inherited;
end;

function TAssimilation.fuGI(const xGI: Double): Double;
// xGI is theta_L
begin
    d_L.theta:=xGi;
    With AssimilationAz.IncidentL.IncidentLAz.Light do
        result:=sin(d_L.theta)*Crown.F.f_omega(d_L.theta)*AssimilationAz.AzInt(p, d_L);
end;

function TAssimilation.P_tot(const _p: TVectorS ): double;
var
    J : Integer;
begin
    p:=_p;
    d_L.r:=1;
    // Should integrate over theta_L angles 0 to 1/2 pi
    // Integration is divided over the angle classes, as the transition
    //   between these classes is not continuous.
    result:=0;
    With AssimilationAz.IncidentL.IncidentLAz.Light do
        for J := 0 to High(Crown.F.AngleClasses) do
            result:=result+Crown.F.a_L*self.integrate((Crown.F.AngleClasses[J].Mid-(0.5*Crown.F.AngleClasses[J].Width)),(Crown.F.AngleClasses[J].Mid+(0.5*Crown.F.AngleClasses[J].Width)));// Default: (0,pi/2)
end;

procedure TAssimilation.GP_w(const Value: integer);
begin
    inherited GP:=Value;
    AssimilationAz.GP:=Value;
end;

function TAssimilation.number_N: integer;
begin
    Result:=inherited GP;
end;

{ TEnviroment }

constructor TEnvironment.Create;
begin
    inherited;
    // Create main classes
    Absorption:=TAbsorption.Create;
    Assimilation:=TAssimilation.Create;
    // Make accessory classes point to the right locations
    {$IFNDEF OLDABS}
    Light:=Absorption.AbsorptionAz.Light;
    Crown:=Absorption.AbsorptionAz.Light.Crown;
    Vegetation:=Absorption.AbsorptionAz.Light.Vegetation;
    {$ELSE}
    Light:=Absorption.AbsorptionAz.IncidentL.IncidentLAz.Light;
    Crown:=Absorption.AbsorptionAz.IncidentL.IncidentLAz.Light.Crown;
    Vegetation:=Absorption.AbsorptionAz.IncidentL.IncidentLAz.Light.Vegetation;
    {$ENDIF}
    Photosynthesis:=Assimilation.AssimilationAz.Photosynthesis;

    // This light has been instantiated already in case Assimilation is used
    //   stand-alone, so now it has to be freed...
    FreeAndNil(Assimilation.AssimilationAz.IncidentL.IncidentLAz.Light);
    // ...and to be made to point to the right location:
    Assimilation.AssimilationAz.IncidentL.IncidentLAz.Light:=Light;
end;

destructor TEnvironment.Destroy;
begin
    FreeAndNil(Assimilation);

    // This has been freed when freeing Assimilation.AssimilationAz.IncidentL.IncidentLAz.Light
    //   however, it has not been nilled for some reason, making the destroying
    //   of Absorption try to free it again leading to an invalid pointer operation.
    {$IFNDEF OLDABS}
    Absorption.AbsorptionAz.Light:=nil;
    {$ELSE}
    Absorption.AbsorptionAz.IncidentL.IncidentLAz.Light:=nil;
    {$ENDIF}

    FreeAndNil(Absorption);
    inherited;
end;

end.
