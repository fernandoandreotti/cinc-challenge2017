function [xp,yp]=circle(x,y,r,ang_step)

ang=0:ang_step:2*pi; 
xp=r*cos(ang)+x;
yp=r*sin(ang)+y;
end