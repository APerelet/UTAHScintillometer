function output = dayNightFlag(OMS, Lat, Long, Firstday, avgPer, UTC_Offset, DST)

%Assume sunrise sunset does not change much over 2 day period
[day, ~] = dayofyear(Firstday, 'dd-mmm-yyyy');

[~, ~, ~, hss] = sun_pos(Lat, Long, day, avgPer, UTC_Offset, DST);
hss = hss+UTC_Offset+DST;
Sunrise = hss(:, 1)/24;
Sunset = hss(:, 2)/24;

%Day Time Flag
Time = OMS.MWSC(:, 1)-OMS.MWSC(1, 1);
if Sunrise<0
    if Sunset>1
        pause(1)
    else
        output = or(...
            or(Time<Sunset, and(Time>Sunrise+1, Time<Sunset+1)),...
            Time>(2+Sunrise)...
            );
    end
else
    if Sunset>1
        output = or(...
            or(and(Time>Sunrise, Time<Sunset), Time>Sunrise+1),...
            Time<(Sunset-1)...
            );
    else
        output = or(and(Time>Sunrise, Time<Sunset), and(Time>Sunrise+1, Time<Sunset+1));
    end
end