%Calculate heat and moisture fluxes from structure parameters using MOS
%functions and itterating from an initial guess of the fluxes

%Inputs
    %Ct2 - Temperature structure parameter
    %Cq2 - Specific Humidity structure parameter
    %r_tq - temperature humidity correlation
    %z_eff - effective measurement height
    %u_star - friction velocity
    %WndDir - Wind direction
    %T - Average temperature
    %rho - air density [kg m^-3]
    %Cp - Specific heat of air [J kg^-1 K^-1]
    %Lv - Latent heat of vaporization of water [J g^-1]
    %xt - Parameters for MOST equation for Temperature
    %xq - Parameters for MOST equations for Humidity
        %Form for xt and xq:
        %[Unstable c1, Unstable c2;
        %Stable c1, Stable c2];
    %nighttime - Flag for nighttime -> corrects for when r_tq is positive
        %at night

function [H, LHflux, L] = StructParam_Flux(Ct2, Cq2, r_tq, z_eff, WndDir, WndSpd, u_star, T, rho, Cp, Lv, xt, xq, nighttime, info)

if isscalar(z_eff)
    z_eff = z_eff.*ones(size(Ct2));
end

if isempty(info)
   error('Need Displacemt height information in info structure'); 
end

thresh = 0.0001;
maxIttr = 1000;

kv = 0.4;  %von Karman constant
g = 9.81; %acceleration due to gravity [m s^-1]

%initial guess for Fluxes
Q_H = 100.*ones(size(Ct2));
if ~isempty(nighttime)
    Q_H(nighttime) = -1.*Q_H(nighttime);            %Negative sensible heat flux at night
else
    Q_H = Q_H.*sign(r_tq);                          %r_tq determines sign 
end
Q_LE = ones(size(Cq2));                             %moisture flux always positive
% % % if info.useECsign
% % %     signLE = sign(Q_H).*sign(r_tq);
% % %     Q_LE = sign(Q_H).*sign(r_tq).*Q_LE;             %Correct sign of latent heat flux
% % % end

%Old values NaN to star
Q_H_old = nan;
Q_LE_old = nan;
q_star_old = nan;
T_star_old = nan;
L_ob_old = nan;
u_star_old = nan;

%Initial values
T_star = -Q_H./(rho.*Cp.*u_star);
q_star = -Q_LE./(rho.*(1000.*Lv).*u_star);

%Check to make sure Temperature is in Kelvin
if max(T)<200
    T = T+273.15;
end

%Initial Obukhov length
L_ob = T.*u_star.^2./(kv.*g.*T_star);

for ii=1:length(Ct2)
    %Adjust for displacement height
    
    %Find location in wind sector
    if ~isnan(WndDir(ii))
        flag = and(info.wind_Sector(:, 1)<=WndDir(ii), WndDir(ii)<info.wind_Sector(:, 2));
        d = info.d(flag);
        
        z_0 = info.z_0(flag);
    else
        %If Wind direction does not exist or isnan no displacement height
        d = 0;
        
        z_0 = nan;
    end
    
    z_d(ii) = z_eff(ii)-d;
    
    %%%%%%%%%%%%%%%%%
    %Sensible heat flux, T_star, u_star, and Obukhov length
    done = 0;
    doneCntr=1;
    while ~done
        if L_ob(ii)<0   %Unstable
            f_t = xt(1, 1).*(1-xt(2, 1).*(z_d(ii)./L_ob(ii))).^(-2/3);
        elseif L_ob(ii)>=0  %Stable
            f_t = xt(1, 2)*(1+xt(2, 2)*(z_d(ii)/L_ob(ii)).^(2/3));
        elseif isnan(L_ob(ii))
            f_t = NaN;
        end
        
        %Calculate heat flux using above MOS functions
        Q_H(ii) = sqrt(z_d(ii)^(2/3).*Ct2(ii)./f_t'.*(rho(ii).*Cp(ii).*u_star(ii)).^2);
        if ~isnan(nighttime(ii))
            if nighttime(ii)
                Q_H(ii) = -1*abs(Q_H(ii));
            else
                Q_H(ii) = abs(Q_H(ii));
            end
        else
            if sign(r_tq(ii))==-1
                Q_H(ii) = -1*abs(Q_H(ii));
            else
                Q_H(ii) = abs(Q_H(ii));
            end
        end
        %Calculate T_star
        T_star(ii) = -Q_H(ii)./(rho(ii).*Cp(ii).*u_star(ii));
        
        %Recalculate Obukhov length
        L_ob(ii) = T(ii).*u_star(ii).^2./(kv.*g.*T_star(ii));
        
        if ~info.uStarEC
            %Recalculate u_Star
            if L_ob(ii)<0
                x_m1(ii) = (1-16.*z_d(ii)./L_ob(ii)).^(1/4);
                Phi1(ii) = 2.*log((1+x_m1(ii))./2)+log((1+x_m1(ii).^2)./2)+atan(x_m1(ii))+pi/2;

                x_m2(ii) = (1-16.*z_0./L_ob(ii)).^(1/4);
                Phi2(ii) = 2.*log((1+x_m2(ii))./2)+log((1+x_m2(ii).^2)./2)+atan(x_m2(ii))+pi/2;

            else
                Phi1(ii) = 1-(1+6.25.*(z_d(ii)./L_ob(ii))).^(4/5);

                Phi2(ii) = 1-(1+6.25.*(z_0/L_ob(ii))).^(4/5);

            end

            u_star(ii) = kv.*WndSpd(ii)./(log(z_d(ii)./z_0)-Phi1(ii)+Phi2(ii));
            
            if u_star(ii)<1E-5
                u_star(ii) = nan;
            end
        end
         

        %Check to see how current iteration performs to last
        if and(and(and(max(abs(Q_H(ii)-Q_H_old))<thresh,...
                max(abs(T_star(ii)-T_star_old))<thresh),...
                max(abs(L_ob(ii)-L_ob_old))<thresh),...
                max(abs(u_star(ii)-u_star_old))<thresh)
            done=1;
            continue;
        elseif isnan(Q_H(ii))
            %warning('Fluxes are all NaNs');
            done = 1;
        elseif doneCntr>maxIttr
            warning('Sensible heat flux did not converge after 1000 iterations');
            done = 1;
        end
        
        %Set new values to old values
        Q_H_old = Q_H(ii);
        T_star_old = T_star(ii);
        L_ob_old = L_ob(ii);
        u_star_old = u_star(ii);
        
        %progress loop counter
        doneCntr = doneCntr+1;
    end
    
    %%%%%%%%%%%%%%%%%
    %Latent Heat Flux and q_star
    done = 0;
    doneCntr=1;
    while ~done
        if L_ob(ii)<0   %Unstable
            f_q = xq(1, 1).*(1-xq(2, 1).*(z_d(ii)./L_ob(ii))).^(-2/3);
        elseif L_ob(ii)>=0  %Stable
            f_q = xq(1, 2)*(1+xq(2, 2)*(z_d(ii)/L_ob(ii)).^(2/3));
        elseif isnan(L_ob(ii))
            f_q = NaN;
        end
        
        %calculate moisture flux using above MOS functions
        Q_LE(ii) = sqrt(z_d(ii)^(2/3).*Cq2(ii)./f_q.*(rho(ii).*(1000.*Lv(ii)).*u_star(ii)).^2);
        
% % %         %Correct sign if using EC data for H sign
% % %         if exist('signLE', 'var')
% % %             if signLE(ii)==-1
% % %                 Q_LE(ii) = -1.*abs(Q_LE(ii));
% % %             else
% % %                 Q_LE(ii) = abs(Q_LE(ii));
% % %             end
% % %         end
        
        %Calculate q_star
        q_star(ii) = -Q_LE(ii)./(rho(ii).*(1000.*Lv(ii)).*u_star(ii));

        %Check to see how current iteration performs to last
        if and(max(abs(Q_LE(ii)-Q_LE_old))<thresh,...
                max(abs(q_star(ii)-q_star_old))<thresh)
            done=1;
            continue;
        elseif isnan(Q_LE(ii))
            %warning('Fluxes are all NaNs');
            done = 1;
        elseif doneCntr>maxIttr
            warning('fluxes did not converge after 1000 iterations');
            done = 1;
        end

        %Set new values to old values
        Q_LE_old = Q_LE(ii);
        q_star_old = q_star(ii);
        
        %Increment counter
        doneCntr = doneCntr+1;
    end
end

H = [T_star, Q_H];
LHflux = [q_star, Q_LE];
L = [z_d', u_star, L_ob];
