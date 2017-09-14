function HRV=get_hrv(hrv_now)% Oliver Carr - 22/06/2015
% Loads QRS peak detector location file and calculates all heart rate
% variability features (HRV).

% Time domain features:
%               SDNN: Standard deviation of all NN intervals
%              SDANN: Standard deviation of mean of NN intervals in 5 min
%                     windows
%              RMSSD: Square root of mean of squares of differences between
%                     adjacent NN intervals
%          SDNNindex: mean of standard deviation of all NN intervals in all
%                     5 mins windows
%               SDSD: Standard deviation of differences between adjacent NN
%                     intervals
%               NN50: Number of pairs of adjacent NN intervals differing by
%                     more than 50ms
%              pNN50: Percentage NN50 (NN50/totan number of NN intervals)
%
% Frequency domain features
%           VLF_peak: Frequency of maximum peak in very low frequency range
%            LF_peak: Frequency of maximum peak in low frequency range
%            HF_peak: Frequency of maximum peak in high frequency range
%     VLF_power_perc: Percentage of total power in VLF range
%      LF_power_perc: Percentage of total power in LF range
%      HF_power_perc: Percentage of total power in HF range
%      LF_power_norm: Percentage of low and high frequency power in the low
%                     frequency range
%      HF_power_norm: Percentage of low and high frequency power in the
%                     high frequency range
%        LF_HF_ratio: Ratio of low to high frequency power

% load QRS time data

vlow_thresh=0.003;
low_thresh=0.04; % set frequency ranges for very low, low and high ranges (Hz)
mid_thresh=0.15;
high_thresh=0.4;

HRV=struct; % create HRV structure

%%

NN=1000*(hrv_now(:,1)-hrv_now(1,1));  % convert data points to time (ms)

NN_int_sec=1000*hrv_now(:,2); % find NN intervals (ms)

NN_mat=[NN,NN_int_sec]; %(ms)

HRV.mRR=mean(NN_int_sec);

HRV.medRR=median(NN_int_sec);

HRV.SDNN=std(NN_int_sec); 

D=diff(NN_int_sec);

D_sq=D.^2;

N=length(NN_int_sec);

mean_diff_int=sum((D_sq))/(N-1);

HRV.RMSSD=sqrt(mean_diff_int);

HRV.SDSD=std(D);
  
HRV.NN50=sum(D>0.05);   

HRV.pNN50=HRV.NN50/length(NN_int_sec);

% Power SPectral Density analysis ***** FOR UNEVEN TIME SPACING??? *****
if length(NN_mat(:,2))>3
[Pxx,F]=plomb(NN_mat(:,2)./1000-mean(NN_mat(:,2)./1000),NN_mat(:,1)./1000,0.001:0.001:0.7);



[~,vlow_index]=min(abs(F-vlow_thresh));
[~,low_index]=min(abs(F-low_thresh));
[~,mid_index]=min(abs(F-mid_thresh));
[~,high_index]=min(abs(F-high_thresh));

% VLF=Pxx(vlow_index:low_index);
LF=Pxx(low_index+1:mid_index);
HF=Pxx(mid_index+1:high_index);

% [~,very_low_peak_index]=max(VLF);
[~,low_peak_index]=max(LF);
[~,high_peak_index]=max(HF);

% HRV.VLF_peak=F(very_low_peak_index);
HRV.LF_peak=F(low_peak_index+low_index);
HRV.HF_peak=F(high_peak_index+mid_index);

HRV.total_power=trapz(F,Pxx)*1000000;
if vlow_index~=1
%     HRV.VLF_power=trapz(F(vlow_index-1:low_index),Pxx(vlow_index-1:low_index))*1000000;%sum(VLF)*1000000;
    HRV.LF_power=trapz(F(low_index-1:mid_index),Pxx(low_index-1:mid_index))*1000000;%sum(LF)*1000000;
    HRV.HF_power=trapz(F(mid_index-1:high_index),Pxx(mid_index-1:high_index))*1000000;%sum(HF)*1000000;
elseif low_index~=1
%     HRV.VLF_power=trapz(F(vlow_index:low_index),Pxx(vlow_index:low_index))*1000000;%sum(VLF)*1000000;
    HRV.LF_power=trapz(F(low_index-1:mid_index),Pxx(low_index-1:mid_index))*1000000;%sum(LF)*1000000;
    HRV.HF_power=trapz(F(mid_index-1:high_index),Pxx(mid_index-1:high_index))*1000000;%sum(HF)*1000000;
elseif mid_index~=1
%     HRV.VLF_power=trapz(F(vlow_index:low_index),Pxx(vlow_index:low_index))*1000000;%sum(VLF)*1000000;
    HRV.LF_power=trapz(F(low_index:mid_index),Pxx(low_index:mid_index))*1000000;%sum(LF)*1000000;
    HRV.HF_power=trapz(F(mid_index-1:high_index),Pxx(mid_index-1:high_index))*1000000;%sum(HF)*1000000;
elseif high_index<length(Pxx)
%     HRV.VLF_power=trapz(F(vlow_index:low_index),Pxx(vlow_index:low_index))*1000000;%sum(VLF)*1000000;
    HRV.LF_power=trapz(F(low_index:mid_index),Pxx(low_index:mid_index))*1000000;%sum(LF)*1000000;
    HRV.HF_power=trapz(F(mid_index:high_index+1),Pxx(mid_index:high_index+1))*1000000;%sum(HF)*1000000;
else
%     HRV.VLF_power=trapz(F(vlow_index:low_index),Pxx(vlow_index:low_index))*1000000;%sum(VLF)*1000000;
    HRV.LF_power=trapz(F(low_index:mid_index),Pxx(low_index:mid_index))*1000000;%sum(LF)*1000000;
    HRV.HF_power=trapz(F(mid_index:high_index),Pxx(mid_index:high_index))*1000000;%sum(HF)*1000000;    
end

HRV.LF_power_norm=100*HRV.LF_power/(trapz(F,Pxx)*1000000);
HRV.HF_power_norm=100*HRV.HF_power/(trapz(F,Pxx)*1000000);

HRV.LF_HF_ratio=HRV.LF_power/HRV.HF_power;
else
    HRV.VLF_power=NaN;
    HRV.LF_power=NaN;
    HRV.HF_power=NaN;

    HRV.LF_power_norm=NaN;
    HRV.HF_power_norm=NaN;

    HRV.LF_HF_ratio=NaN;
end

HRV.SD1=sqrt(var(((1/sqrt(2))*hrv_now(1:end-1,2))-((1/sqrt(2))*hrv_now(2:end,2))));
HRV.SD2=sqrt(abs((2*std(hrv_now(:,2))^2)-HRV.SD1^2));

% if length(hrv_now(:,2))<5
%     HRV.saen=NaN;
%     HRV.apen=NaN;
% else
%     HRV.saen = SampEn( 2, 0.2*std(hrv_now(:,2)), hrv_now(:,2) );
%     HRV.apen = ApEn( 2, 0.2*std(hrv_now(:,2)), hrv_now(:,2), 1);
% end

% HRV.COSEn=HRV.saen-log(2*30)-log(HRV.mRR);

[RP,DD] = RPplot(hrv_now(:,2)',3,1,0.5,0);
[RR1,DET1,ENTR1,L1] = Recu_RQA(RP,0);

HRV.RR=RR1; % Recurrence Rate
HRV.DET=DET1; %Determinism
HRV.ENTR=ENTR1; %Shannon Entropy
HRV.L=L1; %Average diagonal line length

% Teager-Kaiser Energy Operator
HRV.TKEO=mean(TKEO(hrv_now(:,2)));

% Detrended Fluctuation Analysis
% [D,alpha1]=DFA_main_a1(hrv_now(:,2)');
[~,alpha2]=DFA_main_a2(hrv_now(:,2)');

% HRV.DFA_a1=alpha1;
HRV.DFA_a2=alpha2;

% Lempel Ziv Complexity
bin_sig=zeros(size(hrv_now(:,2)));
bin_sig(hrv_now(:,2)>nanmedian(hrv_now(:,2)))=1;
if length(bin_sig)<3
    HRV.LZ=NaN;
else
[C,~,~]=calc_lz_complexity(bin_sig, 'exhaustive', 1);

HRV.LZ=C;
end

% Triangular Index
% h=histogram(hrv_now(:,2),30);
% HRV.TriIn=max(h.Values)*diff(h.BinLimits);





