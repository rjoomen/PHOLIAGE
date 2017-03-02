unit Vector;

{$MODE Delphi}

//
// Vector calculations unit, (c) Roelof Oomen, 2007
//

//  Coordinate system
//
//  Cartesian
//              z|
//               |    / y
//               |  /
//     __________|/_________ x
//              /|
//            /  |
//          /    |
//
//
// Spherical coordinates are defined as (r, psi, theta) with psi being
//   the azimuth angle (0-360 degrees, in the x-y plane, counterclockwise)
//   and theta the polar/zenith angle (0-180 degrees, angle with z-axis).
//
// Cylindrical coordinates are defined as (r, psi, h)
//   where r is the radius (distance to the z-axis), h is the
//   height, i.e. the Z-coordinate, and psi the angle with the x-axis in
//   the x-y plane, counterclockwise.
//
// WARNING: The definitions of the spherical coordinates differ from many texts,
//   (common: r, theta, phi).
//

interface

type
    // Cartesian
    TVectorC = record
      private
        function getR: double; //inline;
      public
        x,
        y,
        z : double;

        property  r     : double read getR; // Length

        procedure makeUnit; //inline;
        function  isUnit : boolean; //inline;

        procedure InitC(x, y, z : Double);

        procedure Null; //inline;
        function  isNull : boolean; //inline;

        // Operator overloadings - Delphi 2005 and later
        class operator Negative(a: TVectorC) : TVectorC; //inline; // Negate
        class operator Add(a: TVectorC; b: TVectorC): TVectorC; //inline;
        class operator Subtract(a: TVectorC; b: TVectorC) : TVectorC; //inline;
        class operator Multiply(a: Double; b: TVectorC) : TVectorC; //inline; // Multiply a vector by a scalar
        class operator Multiply(a: TVectorC; b: Double) : TVectorC; //inline; // Multiply a vector by a scalar

        class operator Multiply(a: TVectorC; b: TVectorC) : Double; //inline; // Dot product!
        class operator Divide(a: TVectorC; b: Double) : TVectorC; //inline;
        class operator Equal(a: TVectorC; b: TVectorC) : Boolean; //inline;
    end;

    // Spherical
    TVectorS = record
        theta,
        psi,
        r      : double;

        procedure Null; //inline;
        function  isNull : boolean; //inline;

        class operator Equal(a: TVectorS; b: TVectorS) : Boolean; //inline;
        class operator Multiply(a: TVectorS; b: TVectorS) : Double; //inline; // Dot product!

        class operator Implicit(a : TVectorS) : TVectorC; //inline;
        class operator Explicit(a : TVectorS) : TVectorC; //inline;
        // Forward declaration of TVectorS is not possible, so these two casts are placed here
        class operator Implicit(a : TVectorC) : TVectorS; //inline;
        class operator Explicit(a : TVectorC) : TVectorS; //inline;
    end;

    // Cylindrical
{    TVectorCyl = record
        r,
        psi,
        h      : double;

        class operator Implicit(a : TVectorCyl) : TVectorS; //inline;
        class operator Explicit(a : TVectorCyl) : TVectorS; //inline;
    end;     }

implementation

uses
    math, sysutils, LCLIntf, LCLType;

{ *** TVector *************************************************************** }
class operator TVectorC.Add(a, b: TVectorC): TVectorC;
begin
    result.x:=a.x+b.x;
    result.y:=a.y+b.y;
    result.z:=a.z+b.z;
end;

class operator TVectorC.Subtract(a, b: TVectorC): TVectorC;
begin
    result.x:=a.x-b.x;
    result.y:=a.y-b.y;
    result.z:=a.z-b.z;
end;

class operator TVectorC.Divide(a: TVectorC; b: Double): TVectorC;
begin
    result.x:=a.x/b;
    result.y:=a.y/b;
    result.z:=a.z/b;
end;

class operator TVectorC.Equal(a, b: TVectorC): Boolean;
begin
    result:=(a.x=b.x) and (a.y=b.y) and (a.z=b.z);
end;

function TVectorC.getR: double;
begin
    result:=sqrt(sqr(x)+sqr(y)+sqr(z));
end;

procedure TVectorC.InitC(x, y, z: Double);
begin
    self.x:=x;
    self.y:=y;
    self.z:=z;
end;

class operator TVectorC.Multiply(a, b: TVectorC): Double;
begin
    result:=a.x*b.x+a.y*b.y+a.z*b.z;
end;

class operator TVectorC.Multiply(a: Double; b: TVectorC): TVectorC;
begin
    result.x:=a*b.x;
    result.y:=a*b.y;
    result.z:=a*b.z;
end;

class operator TVectorC.Multiply(a: TVectorC; b: Double): TVectorC;
begin
    result.x:=b*a.x;
    result.y:=b*a.y;
    result.z:=b*a.z;
end;

class operator TVectorC.Negative(a: TVectorC): TVectorC;
begin
    result.x:=-a.x;
    result.y:=-a.y;
    result.z:=-a.z;
end;

function TVectorC.isNull: boolean;
begin
    if ( (x=0) and (y=0) and (z=0) ) then
        result:=true
    else
        result:=false;
end;

function TVectorC.isUnit: boolean;
begin
    // Compensate for very minor differences (rounding errors etc)
    result:=( RoundTo(r,-12)=1 );
end;

procedure TVectorC.makeUnit;
var
    r_i:Double;
begin
    r_i:=r;
    x:=x/r_i;
    y:=y/r_i;
    z:=z/r_i;
end;

procedure TVectorC.null;
begin
    x:=0;
    y:=0;
    z:=0;
end;

{ TVectorS }

function TVectorS.isNull: boolean;
begin
    if (theta=0) and (psi=0) and (r=0) then
        result:=true
    else
        result:=false;
end;

class operator TVectorS.Multiply(a, b: TVectorS): Double;
var
    ax, ay, az, bx, by, bz : double;
begin
    //result:=cos(a.psi-b.psi)*sin(a.theta)*sin(b.theta)+cos(a.theta)*cos(b.theta);
    ax:=a.r*sin(a.theta)*cos(a.psi);
    ay:=a.r*sin(a.theta)*sin(a.psi);
    az:=a.r*cos(a.theta);
    bx:=b.r*sin(b.theta)*cos(b.psi);
    by:=b.r*sin(b.theta)*sin(b.psi);
    bz:=b.r*cos(b.theta);
    result:=ax*bx+ay*by+az*bz;
end;

procedure TVectorS.Null;
begin
    theta:=0;
    psi:=0;
    r:=0;
end;

class operator TVectorS.Equal(a, b: TVectorS): Boolean;
begin
    //inherited;
    result:=(a.theta=b.theta) and (a.psi=b.psi) and (a.r=b.r);
end;

class operator TVectorS.Explicit(a: TVectorS): TVectorC;
begin
    result.x:=a.r*sin(a.theta)*cos(a.psi);
    result.y:=a.r*sin(a.theta)*sin(a.psi);
    result.z:=a.r*cos(a.theta);
end;

class operator TVectorS.Implicit(a: TVectorS): TVectorC;
begin
    result.x:=a.r*sin(a.theta)*cos(a.psi);
    result.y:=a.r*sin(a.theta)*sin(a.psi);
    result.z:=a.r*cos(a.theta);
end;

class operator TVectorS.Implicit(a: TVectorC): TVectorS;
begin
    result.r:=a.r;
    result.theta := arccos(a.z/result.r); // Use result.r instead of a.r, because
                                          //   a.r is calculated for each call.
    // ArcTan2(Y,X) calculates ArcTan(Y/X), and returns an angle in the correct quadrant.
    result.psi := arctan2(a.y,a.x);
end;

class operator TVectorS.Explicit(a: TVectorC): TVectorS;
begin
    result.r:=sqrt(sqr(a.x)+sqr(a.y)+sqr(a.z));
    result.theta := arccos(a.z/result.r);
    // ArcTan2(Y,X) calculates ArcTan(Y/X), and returns an angle in the correct quadrant.
    result.psi := arctan2(a.y,a.x);
end;

{ TVectorCyl }
{
class operator TVectorCyl.Explicit(a: TVectorCyl): TVectorS;
begin
    result.r:=sqrt(sqr(a.r)+sqr(a.h));
    result.psi:=a.psi;
    result.theta:=arctan(a.r/a.h);
end;

class operator TVectorCyl.Implicit(a: TVectorCyl): TVectorS;
begin
    result.r:=sqrt(sqr(a.r)+sqr(a.h));
    result.psi:=a.psi;
    result.theta:=arctan2(a.r,a.h);
end;
}
end.

