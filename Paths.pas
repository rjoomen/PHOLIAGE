unit Paths;

{$MODE Delphi}

//
// PHOLIAGE Model, (c) Roelof Oomen, 2006-2007
//
// Model path length calculations
//

interface

// Use table lookup instead of calculating everything every time
// Speeds up program enormously
{$DEFINE TABLES}

uses
    Vector, Quadratic, GaussInt;

const
    // Constants of leaf angle distribution functions
    LACLASSES    = 0;
    LACONTINUOUS = 1;
    LASPHERICAL  = 2;

type

//*************** Support classes/records **************************************

    TAngleClass = record
        Mid      : Double;
        Width    : Double;
        fraction : Double;
    end;

    ///Area for leaf area density and distribution
    TLeafArea = record
        // Angle class array
        //   Note: Last class includes upper boundary
        //   E.g. in degrees: [0,30) [30,60) [60,90]
        AngleClasses : array of TAngleClass;
        // Leaf area density
        F : Double;
        // Leaf light absorption coefficient
        a_L : double;
        // Leaf angle distribution function
        LADist : byte;
        // Azimuthal width of the leaf distribution, normally 2pi
        AzWidth : Double;
        // Identification for lookup table
        id : integer;

        // Clear leaf angle list & set up record -- Always call first!
        procedure Clear;
        // Add a leaf angle class and keeps class list sorted
        procedure addclass(Mid, Width, fraction : Double);
        // Same but in degrees instead of radians
        procedure addclassD(Mid, Width, fraction : Double);
        // If numbers of leaves in each class are added instead of fractions
        //   this calculates fractions for each class adding up to a total of 1
        procedure fractionise;
        function f_omega(const theta_L: double):double;
    end;

//*************** Extinction coefficient calculations **************************

    ///Integration class of azimuth part of extinction
    TExtinctionAz = class(TGaussInt)
    strict private
        d_L,
        d_i: TVectorS;
        {$IFDEF TABLES}
        Ans : array of Double; // Saves last result
        {$ENDIF}
    protected
        function fuGI(const xGI: Double): Double; override;
    public
        function AzInt(const _d_L, _d_i: TVectorS; _step: integer): double;
        constructor Create;
    end;

    ///Calculates a vegetation extinction coefficient
    TExtinction = class (TGaussInt)
    strict private
        d_L,
        d_i : TVectorS;
        F   : TLeafArea;
        // Used for table index
        AClass : Integer;
        {$IFDEF TABLES}
        Kf_table : array[0..1,0..1] of array of array of Double;
        {$ENDIF}
    private
        procedure GP_w(const Value: integer);
        function number_N: integer;
    protected
        function fuGI(const xGI: Double): Double; override;
    public
        // Class integrating over the azimuth angle
        ExtinctionAz : TExtinctionAz;

        function Kf(const _d_i : TVectorS; var _F : TLeafArea; stepPol, stepAz, id: integer): double;
        // Set both own and ExtinctionAz's GP
        property    GP : integer read number_N write GP_w;

        constructor Create; // Instantiates ExtinctionAz
        destructor  Destroy; override;
    end;

//*************** Pathlength calculations **************************************

    TAttenuation = interface
        function Attenuation( _p, _d_i : TVectorS; stepPol, stepAz, id: integer): double;
    end;

    ///The surrounding vegetation for a circular gap
    TVegetationCircular = class (TQuadratic)
      strict private
        Extinction : TExtinction;
        p,               // Intersection of light with the crown ellipsoid
                         //   Should be equal to TCrown.q
        q,               // Intersection of light with the vegetation
        d_i   : TVectorC; // Inverse direction of light beam
        function veg_path(const side: boolean) : double;

        /// Path length through the vegetation
        ///   _p:   Intersection of light with the crown ellipsoid (TCrown.q)
        ///   _d_i: Inverse direction of light beam
        function pathlength( _p, _d_i : TVectorC ) : double;

      protected
        function alpha : double; override;
        function beta  : double; override;
        function gamma : double; override;

      public
        r_gap,             // Radius of gap
        h_t,               // Top of TVegetation
        h_b   : double;    // Bottom of TVegetation
        F     : TLeafArea; // Leaf area density and angle classes

        function Attenuation( _p, _d_i : TVectorS; stepPol, stepAz, id: integer): double;
        constructor Create;
        destructor Destroy; override;
    end;

    ///The tree crown
    TCrown = class (TQuadratic)
      strict private
        Extinction : TExtinction;
        d_i,                   // Inverse direction of light beam
        p   : TVectorC;         // Point for which to calculate pathlengths

        function pathlength( _p, _d_i : TVectorC ) : double;

      protected
        function alpha : double; override;
        function beta  : double; override;
        function gamma : double; override;

      public
        a,
        b,
        c   : double;    // Semi-axes
        q   : TVectorC;   // Intersection of light with crown ellipsoid
                         //   Necessary for TVegetation
        F   : TLeafArea; // Leaf area density and angle classes

        function Attenuation( _p, _d_i : TVectorS; stepPol, stepAz, id: integer): double;
        constructor Create;
        destructor  Destroy; override;
    end;

function Deg2Rad (degrees : Double) : Double; //inline;

implementation

uses
    SysUtils;

{ *** TExtinctionAz ********************************************************** }

constructor TExtinctionAz.Create;
begin
    inherited;
    x_min:=0;
    x_max:=2*pi;
end;

function TExtinctionAz.fuGI(const xGI: Double): Double;
// xGI is psi_L
begin
    d_L.psi:=xGI;
    result:=abs(d_L*d_i);
end;

function TExtinctionAz.AzInt(const _d_L, _d_i: TVectorS; _step: integer): double;
begin
    {$IFDEF TABLES}
    // Check for known result
    if (_d_i=d_i) then
        if (Length(Ans)>=_step) then
        begin
            result:=ans[_step-1];
            exit;
        end;
    {$ENDIF}

    // * Actual math
    d_i:=_d_i;
    d_L:=_d_L;
    result:=integrate;// Default: (0,2*pi)

    {$IFDEF TABLES}
    // Save result
    SetLength(Ans,_step);
    ans[_step-1]:=result;
    {$ENDIF}
end;

{ *** TExtinction ************************************************************ }

constructor TExtinction.Create;
begin
    inherited Create;
    x_min:=0;
    x_max:=pi/2;
    ExtinctionAz:=TExtinctionAz.Create;
end;

destructor TExtinction.Destroy;
begin
    FreeAndNil(ExtinctionAz);
    inherited;
end;

function TExtinction.fuGI(const xGI: Double): Double;
// xGI is theta_L
begin
    d_L.theta:=xGI;
    result:=sin(xGI)*F.f_omega(xGI)*ExtinctionAz.AzInt(d_L, d_i, (AClass*GP)+step);
end;

function TExtinction.Kf(const _d_i : TVectorS; var _F : TLeafArea; stepPol, stepAz, id: integer): double;
var
    I : Integer;
begin
    {$IFDEF TABLES}
    // Check for known result
    // First check table dimensions
    // Note: _F.id is 0-based, steps are 1-based.
    if High(Kf_table[id,_F.id])<(stepPol-1) then
        SetLength(Kf_table[id,_F.id],stepPol);
    ASSERT(Length(Kf_table[id,_F.id])>=(stepPol));
    if High(Kf_table[id,_F.id,stepPol-1])<(stepAz-1) then
        SetLength(Kf_table[id,_F.id,stepPol-1],stepAz)
    else
    begin
        // Known result
        result:=Kf_table[id,_F.id,stepPol-1,stepAz-1];
        exit;
    end;
    ASSERT(Length(Kf_table[id,_F.id,stepPol-1])>=(stepAz));
    {$ENDIF}

    // * Actual math
    d_i:=_d_i;
    d_L.r:=1; // Set length, angles are set by integrations
    F:=_F;
    // Should integrate over theta_L angles 0 to 1/2 pi
    // Integration is divided over the angle classes, as the transition
    //   between these classes is not continuous.
    result:=0;
    for I := 0 to High(F.AngleClasses) do
    begin
        AClass:=I; // For loop control variable must be simple local variable
        result:=result+_F.a_L*integrate((F.AngleClasses[AClass].Mid-(0.5*F.AngleClasses[AClass].Width)),(F.AngleClasses[AClass].Mid+(0.5*F.AngleClasses[AClass].Width)));
    end;
    _F:=F;

    {$IFDEF TABLES}
    // Save result
    Kf_table[id,_F.id,stepPol-1,stepAz-1]:=result;
    {$ENDIF}
end;

procedure TExtinction.GP_w(const Value: integer);
begin
    // Set both own and ExtinctionAz's GP
    inherited GP:=value;
    ExtinctionAz.GP:=value;
end;

function TExtinction.number_N: integer;
begin
    result:=inherited GP;
end;

{ *** TCrown ***************************************************************** }

function TCrown.alpha: double;
begin
    result := sqr(d_i.x) / sqr(a) +
              sqr(d_i.y) / sqr(b) +
              sqr(d_i.z) / sqr(c);
end;

function TCrown.Attenuation(_p, _d_i: TVectorS; stepPol, stepAz, id: integer): double;
begin
    result := - Extinction.Kf(_d_i,F, stepPol, stepAz, id) * pathlength(_p, _d_i);
end;

function TCrown.beta: double;
begin
    result := 2 * d_i.x * p.x / sqr(a) +
              2 * d_i.y * p.y / sqr(b) +
              2 * d_i.z * p.z / sqr(c);
end;

constructor TCrown.Create;
begin
    inherited;
    F.id := 0;
    Extinction := TExtinction.Create;
end;

destructor TCrown.Destroy;
begin
    FreeAndNil(Extinction);
    inherited;
end;

function TCrown.gamma: double;
begin
    result := sqr(p.x) / sqr(a) +
              sqr(p.y) / sqr(b) +
              sqr(p.z) / sqr(c) - 1;
end;

function TCrown.pathlength( _p, _d_i : TVectorC ) : double;
begin
    p := _p;
    d_i := _d_i;
    // Path length
    result := Solve(true);
    // Intersection with ellipsoid boundary
    q := result * d_i + p;
end;

{ *** TVegetation ************************************************************ }

function TVegetationCircular.alpha: double;
begin
    result := sqr(d_i.x)+sqr(d_i.y);
end;

function TVegetationCircular.Attenuation(_p, _d_i: TVectorS; stepPol, stepAz, id: integer): double;
begin
    result := - Extinction.Kf(_d_i, F, stepPol, stepAz, id) * pathlength(_p, _d_i);
end;

function TVegetationCircular.beta: double;
begin
    result := 2*p.x*d_i.x+2*p.y*d_i.y;
end;

constructor TVegetationCircular.Create;
begin
    inherited;
    F.id := 1;
    Extinction := TExtinction.Create;
end;

destructor TVegetationCircular.Destroy;
begin
    FreeAndNil(Extinction);
    inherited;
end;

function TVegetationCircular.gamma: double;
begin
    result := sqr(p.x)+sqr(p.y)-sqr(r_gap);
end;

function TVegetationCircular.veg_path(const side: boolean): double;
begin
    if side then
        result := (h_t-p.z)/d_i.z
    else // Lower boundary: no need to calculate new p
        result := (h_t-h_b)/ d_i.z;
end;

function TVegetationCircular.pathlength( _p, _d_i : TVectorC ) : double;
var
    lambda, lambda2 : double;
begin
    p := _p; // Define new p as the intersection with the ellipsoid
    d_i := _d_i;

    if p.z>=h_t then // Above top of veg
        result := 0 // No intersection
    else
        if p.z>=h_b then // Between top and bottom of veg
            if sqrt(sqr(p.x)+sqr(p.y))>=r_gap then // Joins veg
                result := veg_path(true) // Calc from side, new p is q is old p
            else // Does not join
            begin
                lambda := Solve(true);
                // Point on boundary
                q := p+lambda*d_i;
                if q.z>=h_t then // No intersection
                    result := 0
                else //calc from side
                begin
                    // New p on boundary
                    p := q;
                    result := veg_path(true);
                end;
            end
        else // Below veg
            if sqrt(sqr(p.x)+sqr(p.y))>=r_gap then // Lower boundary
                result := veg_path(false)
            else // Lower or side boundary
            begin
                // Path length through gap to side boundary
                lambda := Solve(true);
                // Path length through gap to lower boundary
                lambda2 := (h_b-p.z)/d_i.z;

                if lambda>lambda2 then // Intersects with side boundary
                begin
                    // Point on boundary
                    q := p+lambda*d_i;
                    if q.z>=h_t then // No intersection
                        result := 0
                    else
                    begin
                        // New p on boundary
                        p := q;
                        result := veg_path(true); // Calc from side, new p is q is old p
                    end;
                end
                else // Intersects with lower boundary
                    result := veg_path(false);
            end;
end;

{ *** TLeafArea ************************************************************** }

procedure TLeafArea.Clear;
begin
    SetLength(AngleClasses,0);
    LADist := 0;
    AzWidth := 2*pi;
end;

procedure TLeafArea.addclass(Mid, Width, fraction : Double);
var
  I, J : Integer;
  T : TAngleClass;
begin
    // Add
    SetLength(AngleClasses,Length(AngleClasses)+1);
    AngleClasses[High(AngleClasses)].Mid := Mid;
    AngleClasses[High(AngleClasses)].Width := Width;
    AngleClasses[High(AngleClasses)].fraction := fraction;
    // Sort
    for I := 0 to High(AngleClasses) - 1 do
        for J := I to High(AngleClasses) do
            if ( AngleClasses[I].Mid > AngleClasses[J].Mid ) then
            begin
                // Swap entries
                T := AngleClasses[I];
                AngleClasses[I] := AngleClasses[J];
                AngleClasses[J] := T;
            end;
end;

procedure TLeafArea.addclassD(Mid, Width, fraction: Double);
begin
    addclass(Deg2Rad(Mid),Deg2Rad(Width),fraction);
end;

procedure TLeafArea.fractionise;
var
    I : Integer;
    total : Double;
begin
    total := 0;
    for I := 0 to High(AngleClasses) do
        total := total+AngleClasses[I].fraction;
    for I := 0 to High(AngleClasses) do
        AngleClasses[I].fraction := AngleClasses[I].fraction/total;
end;

function TLeafArea.f_omega(const theta_L: double): double;
var
  I: Integer;
  AClass: Integer;
  Len : Integer;
begin
    case LADist of
        LACLASSES:
        begin
            AClass := -1; // -1 indicates nothing found
            Len := High(AngleClasses);
            // Find the corresponding class
            for I := 0 to Len-1 do
                // Check if Theta_L is smaller than upper class boundary
                if theta_L < (AngleClasses[I].Mid+(0.5*AngleClasses[I].Width)) then
                begin
                    AClass := I;
                    break;
                end;
            // Check if it's the upper class (inc. upper boundary)
            if AClass=-1 then
                if theta_L <= (AngleClasses[Len].Mid+(0.5*AngleClasses[Len].Width)) then
                    AClass := Len;
            ASSERT( AClass <> -1 ); // Should have found a class
            //result :=  (F*AngleClasses[AClass].fraction) /(2*pi*(AngleClasses[AClass].Width));
            result := (F*AngleClasses[AClass].fraction) /(AzWidth*
                    ( cos(AngleClasses[AClass].Mid-(0.5*AngleClasses[Len].Width))
                     -cos(AngleClasses[AClass].Mid+(0.5*AngleClasses[Len].Width))) );
        end;
        LACONTINUOUS:
        begin
            result := F*(2/pi)/(2*pi*sin(theta_L));
        end;
        LASPHERICAL:
        begin
            result := F*sin((pi/2)-theta_L)/(2*pi*sin(theta_L));
        end;
        else
        begin
            ASSERT(false);
            result := 0;
        end;
    end;
end;

// *** Support function ********************************************************

function deg2rad (degrees : Double) : Double;
begin
    result := degrees * (pi/180);
end;

end.
