function [nu, beta] = leo_doppler(fc, h, elev_deg)
% LEO_DOPPLER  Doppler shift and Doppler rate of a LEO satellite seen from the ground.
%   fc       : carrier frequency [Hz]
%   h        : orbit altitude [m] (circular orbit, pass through the UE's zenith)
%   elev_deg : elevation angle of the satellite [deg]
%   nu       : Doppler shift [Hz]    (negative = satellite moving away)
%   beta     : Doppler rate  [Hz/s]  (largest magnitude at zenith)
%
% Geometry: UE at radius R, satellite at radius r = R + h, central angle theta.
%   slant range     d    = sqrt(R^2 + r^2 - 2 R r cos(theta))
%   range rate      d'   = R r sin(theta) w / d
%   range accel.    d''  = (R r cos(theta) w^2 - d'^2) / d
%   nu = -fc d' / c ,  beta = -fc d'' / c

R  = 6371e3;                 % Earth radius [m]
mu = 3.986004418e14;         % Earth gravitational parameter [m^3/s^2]
c  = 299792458;              % speed of light [m/s]

r     = R + h;
v     = sqrt(mu / r);        % orbital speed [m/s]
w     = v / r;               % angular rate [rad/s]
elev  = deg2rad(elev_deg);
theta = acos(R * cos(elev) / r) - elev;     % central angle for this elevation

d     = sqrt(R^2 + r^2 - 2 * R * r * cos(theta));
d1    = R * r * sin(theta) * w / d;         % range rate [m/s]
d2    = (R * r * cos(theta) * w^2 - d1^2) / d;

nu   = -fc * d1 / c;
beta = -fc * d2 / c;
end
