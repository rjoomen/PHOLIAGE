unit Quadratic;

interface

type
    ///Quadratic formula; Solves quadratic equations of the form
    ///   alpha*x^2+beta*x+gamma=0
    TQuadratic = class
    private
        // Temporary variables, initialised by Discriminant
        t_Discriminant,
        t_alpha,
        t_beta   : double;
    protected
        // Parameters
        function alpha : double; virtual; abstract;
        function beta  : double; virtual; abstract;
        function gamma : double; virtual; abstract;

        function Discriminant : Double;
    public
        /// Solve raises EInvalidArgument exception when no real solution possible
        function Solve(const Positive : Boolean) : Double;
    end;

implementation

uses
    Math;

{ *** TQuadratic ************************************************************* }

function TQuadratic.Discriminant: Double;
begin
    t_alpha := alpha;
    t_beta := beta;
    t_Discriminant := sqr(t_beta) - 4 * t_alpha * gamma;
    Result := t_Discriminant;
end;

function TQuadratic.Solve(const Positive : Boolean) : Double;
var
   result1, result2 : Double;
begin
    if Discriminant>=0 then
    begin
        result1 := ( -t_beta + sqrt(t_Discriminant)) / (2 * t_alpha);
        result2 := ( -t_beta - sqrt(t_Discriminant)) / (2 * t_alpha);
        if Positive then
        begin
            if result1>result2 then
                result := result1
            else
                result := result2;
            // Round result to 16 digits, as rounding errors in the calculations can
            //   result in a very small number (about 1e-19) here, instead of zero.
            result:=RoundTo(result, -16);
            ASSERT(result>=0);
        end;
    end
    else
        raise EInvalidArgument.Create('No real solutions to quadratic equation');
end;

end.
