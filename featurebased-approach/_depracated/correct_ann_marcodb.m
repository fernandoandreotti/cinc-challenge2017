% 'O' - AB - atrial bigeminy
% 'A' - AF - atrial fibrillation
% 'O' - B0 - ventricular bigeminy
% 'O' - EX - pre-excitation (WPW)
% 'O' - NO - nodal (A-V junctional) rhythm
% 'N' - NR - normal rhythm
% 'O' - OT - other rhythms
% 'O' - PA - paced
% 'O' - SB - sinus bradycardia
% 'O' - SV - supraventricular tachyarrhythmia
% 'O' - TV - ventricular trigeminy
% 'O' - VF - ventricular fibrillation
% 'O' - VT - ventricular tachycardia
% 'O' - ZZ - NO CLUE
% MU - patients that present 'A' and 'O'
% WR - patient 221 was weirdly annotated, changed all to 'O'

% corr_ann.ann = repmat('?',32574,1);
% corr_ann.ann(ann_new.final_ann == 4) = '~'; % annotated as noisy
% corr_ann.ann(ann_new.final_ann == 5) = '?'; % annotated as to be removed
% 
% corr_ann.ann((ann_new.final_ann == 1)&cellfun(@(x) x == 'N',ann_old.final_ann)) = 'N'; % agreed as normal
% corr_ann.ann((ann_new.final_ann == 2)&cellfun(@(x) x == 'A',ann_old.final_ann)) = 'A'; % agreed as A
% corr_ann.ann((ann_new.final_ann == 3)&cellfun(@(x) x == 'O',ann_old.final_ann)) = 'O'; % agreed as O
% corr_ann.ann((ann_new.final_ann == 2)&cellfun(@(x) x == 'O',ann_old.final_ann)) = 'O'; % AF -> O
% corr_ann.ann((ann_new.final_ann == 1)&cellfun(@(x) x == 'O',ann_old.final_ann)) = 'O'; % N -> O
%% Generating plots
% clear
load('~/Downloads/wkspace3.mat')
corr_ann(corr_ann.ann == '?',:) = [];
fls = corr_ann.name;
% Bandpass
fs = 300; % Hz
LWIDTH = 1.2;
FONT_SIZE = 15;

% using Butterworth filters for high and low passes (faster)
HF_CUT = 100;   % high cut frequency
LF_CUT = 3;     % low cut frequency
NO_CUT = [49 51];    % notch filter
NO_CUT2 = [59 61];    % notch filter

b_no = fir1(fs,[NO_CUT].*2./fs,'stop');
b_no2 = fir1(fs,[NO_CUT2].*2./fs,'stop');
a_no = 1;
[b_lp,a_lp] = butter(5,HF_CUT/(fs/2),'low');
[b_bas,a_bas] = butter(3,LF_CUT/(fs/2),'high');


for i = 1:length(fls)
    load(['/data/CINCDB_Marco/traindb_new/' fls{i}]) % loading data
    % Preprocessing data
    rawmecg = signal;
    nomix = filtfilt(b_no,a_no,rawmecg);              % notch1
    nomix = filtfilt(b_no2,a_no,nomix);              % notch2
    lpmix = filtfilt(b_lp,a_lp,nomix);              % lowpass
    ppmecg = filtfilt(b_bas,a_bas,lpmix);   % highpass
    signal = ppmecg - mean(ppmecg);
    signal = signal/std(signal);
    if size(signal,2) > size(signal,1), signal = signal'; end          
    subgroup = corr_ann.sublabel{i};
    label = corr_ann.ann(i);
    save(['/data/CINCDB_Marco/augmentedDB/' fls{i}],'signal','label','fs','subgroup')
    close
    figure('units','normalized','outerposition',[0 0 1 1]);    
    plot(signal,'Color','b','LineWidth',LWIDTH)
    set(findall(gcf,'type','text'),'fontSize',FONT_SIZE);
    set(gca,'FontSize',FONT_SIZE)
    set(gca,'XTickLabel','')
    xlabel('10 s','FontSize',FONT_SIZE,'FontWeight','bold')
    ylabel('Amplitude (mV)','FontSize',FONT_SIZE,'FontWeight','bold')
    title(label)
    print('-dpng','-r300',['/local/engs1314/Downloads/reannot/' fls{i} '.png'])
    close 
    clear label signal subgroup
end


%Copying some random '~'s
fls = dir('/data/CINCDB_Marco/traindb_new/N*.mat');
fls = arrayfun(@(x) x.name,fls,'UniformOutput',false);
idxkeep = randsample(length(fls),9400);
fls = fls(idxkeep);
cellfun(@(x) copyfile(['/data/CINCDB_Marco/traindb_new/' x],['/data/CINCDB_Marco/augmentedDB/' x]),fls);

%Copying some random 'O's
fls = dir('/data/CINCDB_Marco/traindb_new/O*.mat');
fls = arrayfun(@(x) x.name,fls,'UniformOutput',false);
idxkeep = randsample(length(fls),7500);
fls = fls(idxkeep);
cellfun(@(x) copyfile(['/data/CINCDB_Marco/traindb_new/' x],['/data/CINCDB_Marco/augmentedDB/' x]),fls);


% clear
% load('wkspace2.mat')
% indv = unique(ann_old.subj);
% %ann_old.sublabel = ann_old.subset;
% % for i = 29953:30649
% %     load(['/data/CINCDB_Marco/' ann_old.name{i} '.mat'])
% %     plot(signal)
% %     title(ann_old.name(i))
% %     close
% % end
% 
% %% Look for patients with multiple problems and label them
% for i = 1:length(indv)
%    idx = find(ann_old.subj == indv(i));
%    weirdidx = cellfun(@isempty,regexp(ann_old.subset(idx),'N'));
%    if any(weirdidx)          
%        weirdidx = find(weirdidx);
%        if length(unique(ann_old.final_ann(idx(weirdidx))))>1
%            ann_old.subset(idx) = {'MU'}; % multiple problems
%        else
%            ann_old.subset(idx) = ann_old.subset(idx(weirdidx(1)));
%        end
%    end
% end
% 
% 
% %% Making summary table
% corr_ann.ann = repmat('F',size(corr_ann,1),1);
% corr_ann.sublabel = ann_old.subset;
% corr_ann.subj = ann_old.subj;
% for idx =1:size(ann_old,1)
%     idx2 = find(strcmp(ann_new.name,ann_old.name(idx)));
%     if ~isempty(idx2)
%         switch ann_new.final_ann(idx2)
%             case 1
%                 %disp(['Kept ' ann_old.name{idx} ' unchanged.']) 
%                 corr_ann.ann(idx) = 'N';    
%             % case annotated as ectopic/arrhythmic
%             case {2,3}
%                 switch ann_old.subset{idx}
%                     case 'AF'
%                         disp(['Changed ' ann_old.name{idx} ' from "' ann_old.final_ann{idx} '" to "A".'])
%                         corr_ann.ann(idx) = 'A';                        
%                     case 'NR'
%                         %disp(['Changed ' ann_old.name{idx} ' from "' ann_old.final_ann{idx} '" to "N".'])
%                         corr_ann.ann(idx) = 'N';
%                     case 'MU'
%                         if ann_new.final_ann(idx2) == 2
%                             disp(['Changed ' ann_old.name{idx} ' from "' ann_old.final_ann{idx} '" to "A".'])
%                             corr_ann.ann(idx) = 'A';
%                         else
%                             disp(['Changed ' ann_old.name{idx} ' from "' ann_old.final_ann{idx} '" to "O".'])
%                             corr_ann.ann(idx) = 'O';
%                         end
%                     otherwise
%                         disp(['Changed ' ann_old.name{idx} ' from "' ann_old.final_ann{idx} '" to "O".'])
%                         corr_ann.ann(idx) = 'O';
%                 end
%             % case annotated as noisy
%             case 4
%                 disp(['Changed ' ann_old.name{idx} ' from "' ann_old.final_ann{idx} '" to "~".'])
%                 corr_signalann.ann(idx) = '~';                                
%             case 5
%                 disp(['Marked ' ann_old.name{idx} ' to be removed.'])
%                 corr_ann.ann(idx) = 'R';
%             otherwise
%                 error('Whaaat!?')                
%         end
%     else
%         corr_ann.ann(idx) = ann_old.final_ann{idx};
%     end
%     clear idx2
% end
% 
% clearvars -except corr_ann
% 
% %% Relabling signals
% writetable(corr_ann,'/data/traindb_new/RECORDS.csv')
% for i = 1:size(corr_ann,1)  
%    disp(corr_ann.name{i})
%    load(['/data/CINCDB_Marco/' corr_ann.name{i} '.mat']) 
%    label = corr_ann.ann(i);
%    if label == 'R'
%     continue
%    end
%    subgroup = corr_ann.sublabel{i};
%    subject = corr_ann.subj(i);
%    save(['/data/traindb_new/' corr_ann.name{i} '.mat'],'signal','label','fs','subgroup','subject')   
% end
% 
% 
% sigs = randperm(size(corr_ann,1));
% for i = 1:1000
%     load(['/data/CINCDB_Marco/traindb_new/' corr_ann.name{sigs(i)} '.mat'])
%     plot(signal)
%     title([label '(' subgroup ')'])
%     print(corr_ann.name{sigs(i)},'-dpng')
% end
% 
% 



