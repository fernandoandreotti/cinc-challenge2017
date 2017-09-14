function qrs=detect_segments(ecg,fs,WIN)

% Run MaxSearch and jqrs through segments
NUM_SEG = 2*ceil(length(ecg)/WIN); % just for prealloc
REF_WIN = 0.2*fs; % refractory window, no detection should occur here.

% GET QRS
qrs1 = jqrs(ecg,REF_WIN,[],fs,[],[],0)+startpoint-1;
HR_PARAM = fs./median(diff(qrs1));           % estimate rate (in Hz) for MaxSearch
qrs2 = OSET_MaxSearch(ecg,HR_PARAM/fs)+startpoint-1;



