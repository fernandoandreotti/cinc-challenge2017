function feat=get_poincare(QRS,fs)
% Obtain poincare plots for HRV analysis
%
%
%
% --
% ECG classification from single-lead segments using Deep Convolutional Neural 
% Networks and Feature-Based Approaches - December 2017
% 
% Released under the GNU General Public License
%
% Copyright (C) 2017  Fernando Andreotti, Oliver Carr
% University of Oxford, Insitute of Biomedical Engineering, CIBIM Lab - Oxford 2017
% fernando.andreotti@eng.ox.ac.uk
%
% 
% For more information visit: https://github.com/fernandoandreotti/cinc-challenge2017
% 
% Referencing this work
%
% Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). 
% Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect 
% Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).
%
% Last updated : December 2017
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

i=1;
% Set the bins for the histogram
edges{1}=0:100:2000;     % <----------- SET BINS
edges{2}=-1000:100:1000; % <----------- SET BINS

% Get the RR interval series from the QRS detection
RR=diff(QRS./fs)*1000;

% If there are less than 5 r peaks, enter NaN instead of finding
% histogram

% Find the difference in RR interval series
dRR=diff(RR);

RR2=RR(2:end);
X=[RR2,dRR];

x_mid=median(RR2);
y_mid=median(dRR);

r=[50,100,200,300]; % <--------- SET NUMBER AND VALUES OF RADIUS (IF >4 CHANGE ALL FEATURE INDICES)
for j=1:4    
    ang=0:0.01:2*pi; 
    xc1=r(j)*cos(ang)+x_mid;
    yc1=r(j)*sin(ang)+y_mid;   
    
    in = inpolygon(RR2,dRR,xc1,yc1);
    
    % Features 1-4: Percentage of points inside circle (centred on median)
    feat(i,j)=sum(in)/length(in);
end
% Features 5-8: median and iqr of x and y coordinates
feat(i,5)=x_mid;
feat(i,6)=y_mid;
feat(i,7)=iqr(RR2);
feat(i,8)=iqr(dRR);

[N,~]=hist3(X,'Edges',edges);
[N2,~]=hist3([x_mid,y_mid],'Edges',edges);
[row,col]=find(N2);

% Features 9-14: Bins with at least 1 and greater than 1 values (and
% normalised)
feat(i,9)=sum(sum(N>0));
feat(i,10)=sum(sum(N>1));
feat(i,11)=sum(sum(N>0))/length(RR);
feat(i,12)=sum(sum(N>1))/length(RR);
feat(i,13)=sum(sum(N>0))/sum(RR);
feat(i,14)=sum(sum(N>1))/sum(RR);

[a1,a2]=meshgrid(1:length(edges{1}),1:length(edges{2}));
C = sqrt((a1-row).^2+(a2-col).^2)<=3; % <-----------------SET THIS RADIUS

M=N;
M(C)=0;

% Features 15-20: Bins with at least 1 and greater than 1 values (and
% normalised) excluding centre circle
feat(i,15)=sum(sum(M>0));
feat(i,16)=sum(sum(M>1));
feat(i,17)=sum(sum(M>0))/length(RR);
feat(i,18)=sum(sum(M>1))/length(RR);
feat(i,19)=sum(sum(M>0))/sum(RR);
feat(i,20)=sum(sum(M>1))/sum(RR);

k = boundary(RR2,dRR);

A = polyarea(RR2(k),dRR(k));
% Features 21-23: Minimum area enclosing all points (normalised)
feat(i,21)=A;
feat(i,22)=A/length(RR);
feat(i,23)=A/sum(RR);

k2 = boundary(RR2,dRR,0);
A2 = polyarea(RR2(k2),dRR(k2));

% Features 24-26: Minimum convex area enclosing all points (normalised)
feat(i,24)=A2;
feat(i,25)=A2/length(RR);
feat(i,26)=A2/sum(RR);

% Features 27-29: Perimeter of minimum area
feat(i,27)=sqrt(sum(diff(RR2(k)).^2+diff(dRR(k)).^2));
feat(i,28)=feat(i,27)/length(RR);
feat(i,29)=feat(i,27)/sum(RR);

% Features 30-32: Perimeter of minimum area
feat(i,30)=sqrt(sum(diff(RR2(k)).^2+diff(dRR(k)).^2));
feat(i,31)=feat(i,27)/length(RR);
feat(i,32)=feat(i,27)/sum(RR);

% Features 33-35: Average distance to centre
feat(i,33)=mean(sqrt((RR2-x_mid).^2+(dRR-y_mid).^2));
feat(i,34)=feat(i,33)/length(RR);
feat(i,35)=feat(i,33)/sum(RR);

B = bsxfun(@minus,X(:,1)',X(:,1)) + ...
    bsxfun(@minus,X(:,2)',X(:,2));
B=B.^2;
B(1:length(B)+1:numel(B)) = Inf;
minB=min(B);
% Features 36-38: Average distance to nearest point
feat(i,36)=mean(minB);
feat(i,37)=feat(i,36)/length(RR);
feat(i,38)=feat(i,36)/sum(RR);

% Features 39-41: Distance to next point
feat(i,39)=sqrt(sum(diff(RR2).^2+diff(dRR).^2));
feat(i,40)=feat(i,39)/length(RR);
feat(i,41)=feat(i,39)/sum(RR);

[idx,Cent,sumd] = kmeans(X,4);
Dist=pdist(Cent);

% Features 42-46: Cluster distances
feat(i,42)=max(Dist);
feat(i,43)=min(Dist);
feat(i,44)=mean(Dist);
feat(i,45)=std(Dist);
feat(i,46)=median(Dist);

vertA2=[RR2(k2),dRR(k2)];
DistA2=pdist(vertA2);
% Features 47-49: Area major minor axes
feat(i,47)=max(DistA2);

% Features 50-55: Smaller percentage in circle (for other rhythms)
r2=[3,5,10,20,30,40]; % <--------- SET NUMBER AND VALUES OF RADIUS (IF >4 CHANGE ALL FEATURE INDICES)
for j=1:6
    ang=0:0.01:2*pi;
    xc1=r2(j)*cos(ang)+x_mid;
    yc1=r2(j)*sin(ang)+y_mid;
    
    in = inpolygon(RR2,dRR,xc1,yc1);
    feat(i,47+j)=sum(in)/length(in);
end


P=[RR2(k2),dRR(k2)];
[A , c] = MinVolEllipse(P', 0.1);
[U Q V]=svd(A);
r1=1/sqrt(Q(1,1));
r2=1/sqrt(Q(2,2));
theta=acos(V(1,1));
% Features 56-61: Ellipse features
feat(i,54)=c(1);
feat(i,55)=c(2);
feat(i,56)=r1;
feat(i,57)=r2;
feat(i,58)=r1/r2;
feat(i,59)=theta;

% features 62-68: Number of clusters
thresh_dist=[100,200,300,400,500,750,1000];
for th=1:length(thresh_dist)
    if max(Dist)<thresh_dist(th)
        clust=1;
    elseif min(Dist)>thresh_dist(th)
        clust=4;
    else
        indD=Dist<thresh_dist(th);
        group1=1;
        group2=2;
        group3=3;
        group4=4;
        if indD(1)==1
            group1=[group1, 2];
            group2=[];
        end
        if indD(2)==1
            group1=[group1, 3];
            group3=[];
        end
        if indD(3)==1
            group1=[group1, 4];
            group4=[];
        end
        if indD(4)==1 && indD(1)==1
            group1=[group1, 3];
            group3=[];
        end
        if indD(4)==1 && indD(1)==0
            group2=[group2, 3];
            group3=[];
        end
        if indD(5)==1 && indD(1)==1
            group1=[group1, 4];
            group4=[];
        end
        if indD(5)==1 && indD(1)==0
            group2=[group2, 4];
            group4=[];
        end
        if indD(6)==1 && indD(2)==1
            group1=[group1, 4];
            group4=[];
        end
        if indD(6)==1 && indD(1)==0 && indD(4)==1
            group2=[group2, 4];
            group4=[];
        end
        if indD(6)==1 && indD(1)==0 && indD(4)==0
            group3=[group3, 4];
            group4=[];
        end
        clust=1;
        if ~isempty(group2)
            clust=clust+1;
        end
        if ~isempty(group3)
            clust=clust+1;
        end
        if ~isempty(group4)
            clust=clust+1;
        end
    end
    feat(i,59+th)=clust;
end



