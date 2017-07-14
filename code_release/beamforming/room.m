function [hr,DirGain] = room(N,sx,sy,sz,mx,my,mz,x,y,z,a,fs)

%N = 1000;
%sx=1.1; sy=1; sz=1;
%mx=2; my=1; mz=1;
%x=3.5; y=4; z=2.7;
%a = .6;
%fs = 16000;

speed=342;
ax= a; ay=a; az = a;
dx = sx-x/2;
dy = sy-y/2;
dz = sz-z/2;
dmx = mx-x/2;
dmy = my-y/2;
dmz = mz-z/2;

M = 10;

max_dist = N/fs*speed;

Nx = ceil(max_dist/x); Ny = ceil(max_dist/y); Nz = ceil(max_dist/z);

hr = zeros(N+2*M,1);

[xx,yy,zz]=ndgrid(-Nx:Nx,-Ny:Ny,-Nz:Nz);
px = xx*x +((-1).^xx)*dx;
py = yy*y +((-1).^yy)*dy;
pz = zz*z +((-1).^zz)*dz;
dist = sqrt((px-dmx).^2 + (py-dmy).^2 + (pz-dmz).^2);
att = (ax.^abs(xx)) .* (ay.^abs(yy)) .* (az.^abs(zz)) ./ dist;
pos = dist*(fs/speed);
posFrac = pos - round(pos);
pos = round(pos);
f = find(pos < N);
LL = size(f);

Vec = (-M:M)';

for ii = 1:LL
    % valid index
    valid_idx = pos(f(ii))+Vec >= 1;
    hr(pos(f(ii))+Vec(valid_idx)) = hr(pos(f(ii))+Vec(valid_idx))...
        +sinc(Vec(valid_idx)-posFrac(f(ii)))*att(f(ii));
end

hr = hr(1:N);
DirGain = 1/sqrt((dx-dmx)^2 + (dy-dmy)^2 + (dz-dmz)^2);

return;
