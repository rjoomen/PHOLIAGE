unit GaussInt;

// Gaussian integration
// after: Press et al. 1989, "Numerical recipes in Pascal" par 4.5
// (Cambridge: Cambridge University Press)
// implemented by Feike Schieving, University of Utrecht, 2002
//
// Modifications by Roelof Oomen
// -all real types changed to double.
// -some variables renamed/clarified.
// -20070529 overloaded Integrate using x_min and x_man variables.
// -20070604 Protected member 'step', to be used for creating arrays of
//    known results.
// -2007xxxx Added TGaussIntA for calculating arrays of results.
// -20090630 In setArgmAndWeightArray corrected assignment to
//    number_N (between 3 and max_N), which was wrong.
// -20090630 Made TGaussIntA a subclass of TGaussInt

interface

type
//===================================================== TGausInt ; july2002
//                                           integration by Gauss' method
//=========================================================================
  TGaussInt = class
    private
      max_N : integer;    // ..  mx_N = 40, max nbr of points in integration
      number_N: integer ; //.. actual number of points used in integration
      eps_N: Double;      // .. eps_N = accuracy calculation of weight factors

      xArg_N : array of Double; // .. array of arguments in intv (0,1)
      wArg_N : array of Double; // .. associated weightfactors

      procedure setArgmAndWeightArray(const nbGI:integer);
      procedure GP_w(const GPw:integer);

    protected
      step : integer;
      function fuGI(const xGI:Double): Double; virtual; abstract;

    public
      constructor Create;
    var
      x_min, x_max : Double; // Integration borders for parameter-less integrate

      property GP : integer read number_N write GP_w;
      /// Integrates between x_beginGI and x_endGI
      function integrate(const x_beginGI, x_endGI : Double): Double; overload;
      /// Integrates between self.x_min and self.x_max
      function integrate : Double; overload;
  end;
// ===============================================================TGaussInt

// Result array for TGaussIntA
  GIResult = Array of Double;

//==================================================== TGausIntA ; july2002
//                                           integration by Gauss' method
//                                           integrates arrays of variables
//=========================================================================
  TGaussIntA = class (TGaussInt)
    private
//      max_N : integer;    // ..  mx_N = 40, max nbr of points in integration
//      number_N: integer ; //.. actual number of points used in integration
//      eps_N: Double;      // .. eps_N = accuracy calculation of weight factors
//
//      xArg_N : array of Double; // .. array of arguments in intv (0,1)
//      wArg_N : array of Double; // .. associated weightfactors
//
//      procedure setArgmAndWeightArray(const nbGI:integer);
//      procedure GP_w(const GPw:integer);

    protected
//      step : integer;
      function fuGI(const xGI:Double): GIResult; reintroduce; virtual; abstract;

    public
//      constructor Create;
//    var
//      x_min, x_max : Double; // Integration borders for parameter-less integrate

//      property GP : integer read number_N write GP_w;
      /// Integrates between x_beginGI and x_endGI
      function integrate(const x_beginGI, x_endGI : Double): GIResult; overload;
      /// Integrates between self.x_min and self.x_max
      function integrate : GIResult; overload;
  end;
// ===============================================================TGaussInt

implementation


//============================ integration by Gauss' method; july2002

{..IMPORTANT to prevent the 'interaction' between parameters, variables
             defined within the procedures below and the parameters of the
             function which are called by these procedures, the parameters,
             variables in the relevant 'hidden' procedures and functions all
             have the extension _N ..}

{..numerical integration according to the Gauss-Legendre method;
   for explanation of algorithm see Press et al. (1986), pargr 4.5}

{..Procedure SetArgmAndWeightArray computes for range x_begin,x_end = (0,1)
   the x-coordinate values xi and the weightfactors wi used for a
   Gauss_Legendre integration method of order nb.
   x-values and associated weightfactors are stored in dynamic array's
   xArg_N, wArg_N of TgaussInt object.
   Maximum number of points in integration, max_N and accuracy eps_N are set
   in procedure Create. Nbr of points in integration between 3 and max_N.
   Integration procedure evaluates/tests whether number of points over
   which integration must be done, is changed
   july2002  ..}

constructor TGaussInt.Create;
begin
    inherited;
    max_N:=40;
    eps_N:=1.0e-15;
    SetArgmAndWeightArray(5); // default setting
end; //____________________________________TgaussINT.create

procedure TGaussInt.SetArgmAndWeightArray(const nbGI : integer);
var
    m_N, j_N, i_N : integer;
    z1_N, z_N, xm_N, xl_N, pp_N, p3_N, p2_N, p1_N : Double ;
    xe_N,xb_N : Double;

begin
    //.. keeping number of integration points between 3 and mx
//    if nbGI<3 then
//        number_N:=3;
//    if nbGI > max_N then
//        number_N:=max_N;
//
//    number_N := nbGI;
    if nbGI < 3 then
        number_N:= 3
    else if nbGI > max_N then
        number_N:= max_N
    else
        number_N:= nbGI;

    //.. making the dynamic array's;
    //.. note that first element of  dynamic array has index zero
    SetLength(xArg_N,number_N+1); SetLength(wArg_N,number_N+1);

    //..computing the array's xArg[] and wArg[], all points xArg lie in (0,1)
    xe_N:=1;
    xb_N:=0;

    m_N  := (number_N + 1) Div 2 ;
    xm_N := 0.5 * (xe_N + xb_N);
    xl_N := 0.5 * (xe_N - xb_N);
    for i_N:= 1 TO m_N do
    begin
        z_N := cos(PI*(i_N - 0.25) / (number_N + 0.5));
        repeat
            p1_N := 1.0; p2_N:= 0.0 ;
            for j_N :=1 to number_N do
            begin
                p3_N := p2_N ;
                p2_N := p1_N;
                p1_N := ((2.0*j_N - 1.0) * z_N * p2_N -(j_N - 1.0) * p3_N) / j_N
            end;
            pp_N := number_N * (z_N * p1_N - p2_N) / (z_N * z_N - 1.0);
            z1_N := z_N ; z_N:= z1_N - p1_N / pp_N;
        until (abs(z_N - z1_N) <= eps_N );
        xArg_N[i_N] := xm_N - xl_N * z_N;
        xArg_N[number_N + 1 - i_N] := xm_N + xl_N * z_N;
        wArg_N[i_N] := 2.0 * xl_N / ( ( 1.0 - z_N * z_N ) *pp_N * pp_N);
        wArg_N[number_N + 1 - i_N] := wArg_N[i_N] ;
    end;
end; //_____________________________________TgausSetArgmAndWeightArray


function TGaussInt.integrate(const x_beginGI, x_endGI: Double):Double;
Var
    sum_N,fu_N : Double;
    i_N : integer;
begin
    {.. this is the actual integration, note the rescaling  }
    Sum_N:=0;
    for i_N := 1 to number_N do
    begin
        step:=i_N;
        fu_N := fuGI( x_beginGI+(x_endGI-x_beginGI)*xArg_N[i_N] );
        Sum_N := Sum_N + (x_endGI-x_beginGI) * wArg_N[i_N] * fu_N;
    end;
    Result:=Sum_N;
end;//_______________________________TgaussINT.integrate

function TGaussInt.integrate: Double;
begin
    result := integrate(x_min, x_max);
end;

procedure TGaussInt.GP_w(const GPw: integer);
begin
    // if new number of integration points, then recalculation of arrays
    if GPw<>number_N then
        setargmandweightarray(GPw);
end;
// =================================================== TGaussInt

//constructor TGaussIntA.Create;
//begin
//    inherited;
//    max_N:=40;
//    eps_N:=1.0e-15;
//    SetArgmAndWeightArray(5); // default setting
//end; //____________________________________TgaussINT.create

//procedure TGaussIntA.SetArgmAndWeightArray(const nbGI : integer);
//var
//    m_N, j_N, i_N : integer;
//    z1_N, z_N, xm_N, xl_N, pp_N, p3_N, p2_N, p1_N : Double ;
//    xe_N,xb_N : Double;
//
//begin
//    //.. keeping number of integration points between 3 and mx
//    if nbGI<3 then
//        number_N:=3;
//    if nbGI > max_N then
//        number_N:=max_N;
//
//    number_N := nbGI;
//
//    //.. making the dynamic array's;
//    //.. note that first element of  dynamic array has index zero
//    SetLength(xArg_N,number_N+1); SetLength(wArg_N,number_N+1);
//
//    //..computing the array's xArg[] and wArg[], all points xArg lie in (0,1)
//    xe_N:=1;
//    xb_N:=0;
//
//    m_N  := (number_N + 1) Div 2 ;
//    xm_N := 0.5 * (xe_N + xb_N);
//    xl_N := 0.5 * (xe_N - xb_N);
//    for i_N:= 1 TO m_N do
//    begin
//        z_N := cos(PI*(i_N - 0.25) / (number_N + 0.5));
//        repeat
//            p1_N := 1.0; p2_N:= 0.0 ;
//            for j_N :=1 to number_N do
//            begin
//                p3_N := p2_N ;
//                p2_N := p1_N;
//                p1_N := ((2.0*j_N - 1.0) * z_N * p2_N -(j_N - 1.0) * p3_N) / j_N
//            end;
//            pp_N := number_N * (z_N * p1_N - p2_N) / (z_N * z_N - 1.0);
//            z1_N := z_N ; z_N:= z1_N - p1_N / pp_N;
//        until (abs(z_N - z1_N) <= eps_N );
//        xArg_N[i_N] := xm_N - xl_N * z_N;
//        xArg_N[number_N + 1 - i_N] := xm_N + xl_N * z_N;
//        wArg_N[i_N] := 2.0 * xl_N / ( ( 1.0 - z_N * z_N ) *pp_N * pp_N);
//        wArg_N[nbGI + 1 - i_N] := wArg_N[i_N] ;
//    end;
//end; //_____________________________________TgausSetArgmAndWeightArray


function TGaussIntA.integrate(const x_beginGI, x_endGI: Double): GIResult;
Var
    sum_N,fu_N : GIResult;
    i_N : integer;
  i_R: Integer;
begin
    {.. this is the actual integration, note the rescaling  }
    SetLength(Sum_N,0);
    for i_N := 1 to number_N do
    begin
        step:=i_N;
        fu_N := fuGI( x_beginGI+(x_endGI-x_beginGI)*xArg_N[i_N] );

        // Initialise and zero the result array
        if Length(Sum_N)=0 then
        begin
            SetLength(Sum_N, Length(fu_N));
            for i_R := 0 to High(fu_N) do
                Sum_N[i_R]:=0;
        end;

        for i_R := 0 to High(fu_N) do
            Sum_N[i_R] := Sum_N[i_R] + (x_endGI-x_beginGI) * wArg_N[i_N] * fu_N[i_R];
    end;
    Result:=Sum_N;
end;//_______________________________TgaussINT.integrate

function TGaussIntA.integrate: GIResult;
begin
    result := integrate(x_min, x_max);
end;

//procedure TGaussIntA.GP_w(const GPw: integer);
//begin
//    // if new number of integration points, then recalculation of arrays
//    if GPw<>number_N then
//        setargmandweightarray(GPw);
//end;

end.
