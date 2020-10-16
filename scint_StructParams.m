%Meteorological Structure parameters from OMS
%Equations from Andreas 1988 & Ludi et al 2005
%Inputs
    %Cn2 - matrix of Refractive index structure param
        %[Cn1^2, Cn1n2, Cn2^2]
        %n1 - infrared structure param
        %n2 - millimeter structure param
        %n1n2 - cross structure param
    %T - mean temperature [K]
    %P - mean pressure [Pa]
    %q - mean specific humidity [kg kg^-1]
    %l1 - infrared frequency [micrometers]
%Outputs
    %Ct2 - temperature structure param
    %Cq2 - humidity structure param
    %Ctq - temperature humidity cross structure param
    %r_tq - temperature humidity correlation coefficient

function [Ct2, Ctq, Cq2, r_Tq, A] = scint_StructParams(Cn2, T, P, q, l1, varargin)

if nargin>5
    if varargin{1}
        flag = 1;
        r_Tq = varargin{2};
    else
        flag = 0;
    end
else 
    flag = 0;
end

checkInputs = [Cn2', T, P, q];
if any(isnan(checkInputs))
    Ct2 = nan;
    Ctq = nan;
    Cq2 = nan;
    r_Tq = nan;
    A = nan.*ones([1, 4]);
    
    return;
end

Rd = 287.058;  % [J/K/kg] Gas constant for air
Rv = 461.495;  % [J/K/kg] Gas constant for water vapor
R = Rd+q*(Rv-Rd);
%from Ward, et. al 2013
    %coefficients for infrared
    m1_opt = 0.237134+68.39297/(130-l1^(-2))+0.45473/(38.9-l1^(-2));
    m2_opt = 0.648731+0.0058058*l1^(-2)-0.000071150*l1^(-4)+0.000008851*l1^(-6);

    bt1_opt = 1E-6*m1_opt;
    bt2_opt = 1E-6*(m2_opt-m1_opt);
    bq2_opt = bt2_opt;
    A(1, 1) = -P/T*(bt1_opt+bt2_opt*(Rv/R*q));          %A_t_opt
    A(1, 2) = P/T*(Rv/R)*q*bq2_opt*(1-q/R*(Rv-Rd));    %A_q_opt
    
    %coefficients for microwave
    m1_mw = 0.776;
    m2a_mw = 0.720;
    m2b_mw = 3750/T;
    m2_mw = m2a_mw+m2b_mw;
    
    bt1_mw = 1E-6*m1_mw;
    bt2_mw = 1E-6*(m2b_mw+m2_mw-m1_mw);
    bq2_mw = 1E-6*(m2_mw-m1_mw);
    
    A(2, 1) = -P/T*(bt1_mw+bt2_mw*(Rv/R*q));            %A_t_mw
    A(2, 2) = P/T*(Rv/R)*q*bq2_mw*(1-q/R*(Rv-Rd));     %A_q_mw

    
if flag
    C_met(1) = (A(2, 2)^2*Cn2(1)+A(1, 2)^2*Cn2(3)+2*r_Tq*A(1, 2)*A(2,2)*sqrt(Cn2(1)*Cn2(3)))/...
        ((A(2, 1)*A(1, 2)-A(1, 1)*A(2, 2))^2*T^(-2));
    
    C_met(3) = (A(2, 1)^2*Cn2(1)+A(1, 1)^2*Cn2(3)+2*r_Tq*A(1, 1)*A(2,1)*sqrt(Cn2(1)*Cn2(3)))/...
        ((A(2, 1)*A(1, 2)-A(1, 1)*A(2, 2))^2*q^(-2));
    
    C_met(2) = r_Tq*sqrt(C_met(1)*C_met(3));
else
    %Coefficient Matrix
    M = [A(1, 1)^2/T^2, 2*A(1, 1)*A(1, 2)/(T*q), A(1, 2)^2/q^2;...
        A(1, 1)*A(2, 1)/T^2, (A(1, 1)*A(2, 2)+A(2, 1)*A(1, 2))/(T*q), A(1, 2)*A(2, 2)/q^2;...
        A(2, 1)^2/T^2, 2*A(2, 1)*A(2, 2)/(T*q), A(2, 2)^2/q^2];

    C_met = M\Cn2;
end


A = [A(1, :), A(2, :)];

Ct2 = C_met(1);
Ct2(Ct2<0) = nan;
Ctq = C_met(2);
Cq2 = C_met(3);
Cq2(Cq2<0) = nan;
if ~flag
    r_Tq = Ctq./sqrt(Ct2.*Cq2);
end


