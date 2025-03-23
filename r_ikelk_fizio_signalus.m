function [fizio_datasets, amzius, visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena, priedo_priesaga)
%% [fizio_datasets, amzius, visakita]=r_ikelk_fizio_signalus(katalogas_su_rinkmena)
% 
% Nuskaityti fiziologinius duomenis ir paruošti juos „Ritminukui“
%
% (c) 2020-2023 Kauno technologijos universitetas
% (c) 2020-2023 Mindaugas Baranauskas

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Ši programa yra laisva. Jūs galite ją platinti ir/arba modifikuoti
% remdamiesi Free Software Foundation paskelbtomis GNU Bendrosios
% Viešosios licencijos sąlygomis: 3 licencijos versija, arba (savo
% nuožiūra) bet kuria vėlesne versija.
%
% Ši programa platinama su viltimi, kad ji bus naudinga, bet BE JOKIOS
% GARANTIJOS; taip pat nesuteikiama jokia numanoma garantija dėl TINKAMUMO
% PARDUOTI ar PANAUDOTI TAM TIKRAM TIKSLU. Daugiau informacijos galite 
% rasti pačioje GNU Bendrojoje Viešojoje licencijoje.
%
% Jūs kartu su šia programa turėjote gauti ir GNU Bendrosios Viešosios
% licencijos kopiją; jei ne - žr. <https://www.gnu.org/licenses/>.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%%

[katalogas,rinkmena,galune]=fileparts(katalogas_su_rinkmena);
if nargin < 2
    priedo_priesaga='ritminukas';
end
amzius=[];
visakita=[];
fizio_datasets=struct();

switch lower(galune)
    
    case {'.edf'}
        [fizio_datasets, visakita]=ikelk_EDF(katalogas_su_rinkmena);
        
    case {'.acq'}
        [fizio_datasets, visakita]=ikelk_BIOPAC_ACQ(katalogas_su_rinkmena);
        
    case {'.mat'}
        MAT_kintamieji = who('-file', katalogas_su_rinkmena);
        
        if ... % isequal(regexp(rinkmena,'^Aurimod[0-9][0-9]_New.mat'),1) && ... % Aurimod
          all(ismember({'ECG_Lead_II' 'Fs_ecg' 'Time_ECG' 'Respiration' 'Fs_resp' 'Time_Respiration' }, MAT_kintamieji))
            
            % KTU
            [fizio_datasets, amzius, visakita]=ikelk_Aurimod_nepilna(katalogas_su_rinkmena);
            
        elseif ... % isequal(regexp(rinkmena,'^Aurimod[0-9][0-9].mat'),1) && ... % Aurimod
          all(ismember({'Biopac' 'CNAP' 'Nautilus' 'SubjectData' }, MAT_kintamieji))
            
            [fizio_datasets, amzius, visakita]=ikelk_Aurimod_pilniau(katalogas_su_rinkmena);
            
        elseif all(ismember({'data' 'isi' 'isi_units' 'labels' 'start_sample' 'units' }, MAT_kintamieji))
            % BIOPAC > MAT
            
            % Viena
            if isequal(regexp(rinkmena,'^SkinCurv[1-4]_2'),1)
                error('SkinCurv*_2 yra "Skin". EKG, kvėpavimą ir kraujo spaudimą rasite SkinCurv*_1')
            end
            
            [fizio_datasets, amzius, visakita]=ikelk_BIOPAC_MAT(katalogas_su_rinkmena);
            
        elseif ismember({'fizio_datasets'},MAT_kintamieji)
            visakita=load(katalogas_su_rinkmena);
            fizio_datasets=visakita.fizio_datasets;
            visakita=rmfield(visakita,'fizio_datasets');
        elseif ~isempty(regexp(katalogas_su_rinkmena, ['.' priedo_priesaga '.*.mat$'], 'once'))
            pirminis_rastas=false;
            paieskos_katIrRinkm=regexprep(katalogas_su_rinkmena, ['.' priedo_priesaga '.*.mat$'],'');
            kandidatas_mat=[paieskos_katIrRinkm '.mat'];
            if exist(kandidatas_mat,'file')
                MAT_kintamieji2 = who('-file', kandidatas_mat);
                if ismember({'fizio_datasets'},MAT_kintamieji2)
                    visakita=load(kandidatas_mat);
                    fizio_datasets=visakita.fizio_datasets;
                    visakita=rmfield(visakita,'fizio_datasets');
                    pirminis_rastas=true;
                end
            else % ta pati rinkmena, tik katalogu aukščiau?
                [~,paieskos_rinkm]=fileparts([paieskos_katIrRinkm '.mat']);
                kandidatas_mat=fullfile(fileparts(katalogas),[paieskos_rinkm '.mat']);
            end
            if ~pirminis_rastas
                kandidatai=filter_filenames([paieskos_katIrRinkm '.*']);
                kandidatai_netinkami=filter_filenames([paieskos_katIrRinkm '.ritminukas*.mat']);
                %kandidatai_netinkami=[kandidatai_netinkami {kandidatas_mat}];
                kandidatai=setdiff(kandidatai,kandidatai_netinkami);
                kandidatai=unique([{kandidatas_mat} kandidatai ],'stable');
                for fi=1:length(kandidatai)
                    try if exist(kandidatai{fi}, 'file')
                            fprintf('Bandoma ieškoti fiziologinių duomenų kitoje rinkmenoje:\n %s\n', kandidatai{fi})
                            [fizio_datasets, amzius, visakita]=r_ikelk_fizio_signalus(kandidatai{fi}, priedo_priesaga);
                            disp('Pavyko!')
                            break
                        end
                    catch
                    end
                end
            end
        else
            error('Nežinau, ką daryti su šiuo MAT...');
        end
        
    otherwise
        if exist('pop_loadset','file') && exist('eeg_checkset','file') && exist('eeg_ikelk','file')
            [fizio_datasets]=ikelk_per_EEGLAB(katalogas_su_rinkmena);
        else
            error('Nepavyko įkelti duomenų. Pabandykite įdiegti EEGLAB, papildinį Darbeliai ir bandykite iš naujo.')
        end
end

if isequal(struct(),fizio_datasets)
    error('Nepavyko rasti fiziologinių duomenų.')
end


function [EKG_kan,RSP_kan,ABP_kan]=kanalu_parinkimas(kanalu_pavad0)
if ischar(kanalu_pavad0) || length(kanalu_pavad0)<2
    error('Įraše per mažai signalų. Reikia bent dviejų: kardiogramos ir kvėpavimo.')
end
% pavadinimų autodekcija
RSP_kan=find(arrayfun(@(v)isequal(v{1},1),regexp(kanalu_pavad0,'^Resp|^Breath|^Kvep'))); % Kvėpavimas
EKG_kan=find(arrayfun(@(v)isequal(v{1},1),regexp(kanalu_pavad0,'^ECG|^EKG|^Electrocardiogra|^Elektrokardiogra'))); % EKG
ABP_kan=find(arrayfun(@(v)isequal(v{1},1),regexp(kanalu_pavad0,'^Blood|^ABP|^BP|^Krauj'))); % Kraujo spaudimas
if length(RSP_kan) == 1 && length(EKG_kan) == 1 && length(ABP_kan) == 1
    return
end
f=figure('Name',r_lokaliz('Pasirinkite signalu kanalus'),'NumberTitle','off', 'units','pixels');
f.Position=[f.Position([1 2]) - [500 100] + f.Position([3 4]) 500 100 ];
f.Units='normalized';
f.MenuBar='none';
% Naudoti vieną, patį pirmąjį iš nurodytų arba tiesiog pirmąjį
EKG_kan=[EKG_kan(:); 1]; EKG_kan=EKG_kan(1);
RSP_kan=[RSP_kan(:); 1]; RSP_kan=RSP_kan(1);
%ABP_kan=[ABP_kan(:); 1]; ABP_kan=ABP_kan(1);
ABP_kan=[ABP_kan(:); length(kanalu_pavad0)+1]; ABP_kan=ABP_kan(1);

%kanalu_pavad={kanalu_pavad{:}};
kanalu_pavad=arrayfun(@(x) sprintf('%d. %s', x, kanalu_pavad0{x}), 1:length(kanalu_pavad0), 'UniformOutput', false);
%kanalu_pavad_=kanalu_pavad;
kanalu_pavad_=[kanalu_pavad {' - '}]; % leisti nepasirinkti tikro kanalo
table1=uitable(f, ...
    'Data', {kanalu_pavad{EKG_kan} kanalu_pavad{RSP_kan} kanalu_pavad_{ABP_kan}}, ...
    'RowName',r_lokaliz('Kanalas'), ...
    'ColumnName',{r_lokaliz('Elektrokardiograma') r_lokaliz('Kvepavimas') r_lokaliz('Kraujo spaudimas')}, ...
    'ColumnEditable',[true true true], ...
    'ColumnFormat', {kanalu_pavad kanalu_pavad kanalu_pavad_}, ...
    'ColumnWidth',{120}, ...
    'Units','normalized', ...
    'OuterPosition', [0.05 0.3 0.9 0.6]);
%'ColumnWidth',{95}, 'Units','normalized', 'OuterPosition',[5 gui_eilutes_y(gui_eil)-390 480 390]
mygt=uicontrol('style','pushbutton', 'String', r_lokaliz('OK'), 'Units', 'normalized', 'position', [0.3 0.03 0.4 0.25], 'callback', 'delete(gcbo)');
waitfor(mygt);
if isvalid(table1)
    EKG_kan=find(ismember(kanalu_pavad, table1.Data{1}));
    RSP_kan=find(ismember(kanalu_pavad, table1.Data{2}));
    ABP_kan=find(ismember(kanalu_pavad, table1.Data{3}));
    delete(f);
else
    delete(f);
    error('Nepasirinktas kanalas!')
end
while length(unique([EKG_kan,RSP_kan,ABP_kan])) < length([EKG_kan,RSP_kan,ABP_kan])
    warning('Pasirinkti kanalai turi būti unikalūs!')
    [EKG_kan,RSP_kan,ABP_kan]=kanalu_parinkimas(kanalu_pavad0);
end

function [fizio_datasets,visakita]=ikelk_EDF(katalogas_su_rinkmena)
%% Informacija
[katalogas,vardas]=fileparts(katalogas_su_rinkmena);
info = edfinfo(katalogas_su_rinkmena);
fs = info.NumSamples/seconds(info.DataRecordDuration);
[EKG_kan,RSP_kan,ABP_kan]=kanalu_parinkimas(info.SignalLabels);

%% Importavimas
% MATLAB integrated "edfread" from R2020b version
[EDFdata,visakita.annotations] = edfread(katalogas_su_rinkmena,... 
    'SelectedSignals',info.SignalLabels([EKG_kan RSP_kan ABP_kan]));
% 'SelectedDataRecords',1:10

%% Apdorojimas
% EKG
[visakita.EKG, Rt]=ikelk_EKG_ir_R(katalogas,vardas,cat(1,EDFdata.(1){:}),fs(EKG_kan));

% Kvėpavimas
kvepavimas=apdorok_kvepavimo_signala(cat(1,EDFdata.(2){:}),fs(RSP_kan));

% Kraujo spaudimas
if isempty(ABP_kan)
    warning('Kraujo spaudimo kanalas nerastas');
    DBP_real=[]; %timeseries();
    SBP_real=[]; %timeseries();
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real);
else
    if isnumeric(EDFdata.(3))
        bp_sig=cat(1,EDFdata.(3));
    else
        bp_sig=cat(1,EDFdata.(3){:});
    end
    bp_sig=bp_sig-median(bp_sig,'omitnan')+80;
    
    % prie kairio skilvelio, o ir prie aortos bei carotis anksčiau nei rankos piršte
    BP_vietos_paklaida=-0.1; % FIXME: padaryti pasirenkamą?
    
    [abp,DBP_real,SBP_real]=apdorok_kraujo_spaud_signala(bp_sig,fs(ABP_kan),[],BP_vietos_paklaida);
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real,'abp',abp);
end


function [fizio_datasets, amzius, visakita]=ikelk_Aurimod_pilniau(katalogas_su_rinkmena)
[katalogas,vardas]=fileparts(katalogas_su_rinkmena);
%AuriMod_duomenys=load(katalogas_su_rinkmena, 'Biopac','CNAP','Nautilus','SubjectData' ); % bet duomenys gigabaitiniai – gal geriau įkelkim dalimis
AuriMod_duomenys=load(katalogas_su_rinkmena, 'Nautilus');

% Širdies ritmas
[visakita.EKG, Rt, R_laikai_taisyti]=ikelk_EKG_ir_R(...
    katalogas,vardas,...
    AuriMod_duomenys.Nautilus.Biopotential.ECG.Lead2,...
    AuriMod_duomenys.Nautilus.Biopotential.ECG.SamplingFrequency);

% Kvėpavimas
AuriMod_duomenys=load(katalogas_su_rinkmena, 'Biopac'); % 'Nautilus'
kvepavimas=apdorok_kvepavimo_signala(AuriMod_duomenys.Biopac.Respiration.Respiration, AuriMod_duomenys.Biopac.Respiration.SamplingFrequency, AuriMod_duomenys.Biopac.Respiration.Time);
%kvepavimas=apdorok_kvepavimo_signala(Nautilus.Biopotential.Respiration.Respiration,Nautilus.Biopotential.Respiration.SamplingFrequency,Nautilus.Biopotential.Respiration.Time);

% Kraujo spaudimas
% Šaltinis reiškia ne tiek įrenginį, kiek lauką, kuriame išsaugota (atsitiktinai ar tyčia): 'Biopac' 'CNAP'
%bp_saltinis='Biopac'; % neapdorotas signalas
bp_saltinis='CNAP'; % apdorotas signalas
switch bp_saltinis
    case {'Biopac'}
        bp_sig=AuriMod_duomenys.Biopac.BloodPressure.BloodPressure;
        bp_t=AuriMod_duomenys.Biopac.BloodPressure.Time;
        bp_fs=AuriMod_duomenys.Biopac.BloodPressure.SamplingFrequency;
    case {'CNAP'}
        AuriMod_duomenys=load(katalogas_su_rinkmena, 'CNAP');
        bp_sig=AuriMod_duomenys.CNAP.ABPWave.Wave;
        bp_t=AuriMod_duomenys.CNAP.ABPWave.Time;
        bp_fs=AuriMod_duomenys.CNAP.ABPWave.SamplingFrequency;
        %{
        bp_t2=AuriMod_duomenys.CNAP.Hemodynamics.BeatTime;
        sbp=AuriMod_duomenys.CNAP.Hemodynamics.SystolicPressure;
        dbp=AuriMod_duomenys.CNAP.Hemodynamics.DiastolicPressure;
        %}
end

bp_sig_lygio_korekcija=median(bp_sig,'omitnan')-80;
bp_sig=bp_sig-bp_sig_lygio_korekcija;

% Sistolinis ir diastolis kraujo spaudimas
%if ~exist('sbp','var')
    rri=diff(R_laikai_taisyti);
    rri(rri<0.3)=NaN;
    min_rri=min(rri(rri>0.3));
    [sbp,dbp]=envelope(bp_sig,round(min_rri*bp_fs),'peak'); % FIXME
    bp_t2=bp_t;
%else
    %sbp=sbp-bp_sig_lygio_korekcija;
    %dbp=dbp-bp_sig_lygio_korekcija;
%end

%bp_sig=bp_sig-median(bp_sig,'omitnan')+80;
% prie kairio skilvelio, o ir prie aortos bei carotis anksčiau nei rankos piršte
BP_vietos_paklaida=-0.1; % FIXME: padaryti pasirenkamą?


DBP_real=timeseries(dbp, bp_t2+BP_vietos_paklaida, 'Name', 'Diastolinis kraujo spaudimas');
SBP_real=timeseries(sbp, bp_t2+BP_vietos_paklaida, 'Name', 'Sistolinis kraujo spaudimas');
[abp]=apdorok_kraujo_spaud_signala(bp_sig,bp_fs,bp_t,BP_vietos_paklaida);

fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real,'abp',abp);

% Amžius ir kiti duomenys apie tiriamąjį
AuriMod_duomenys=load(katalogas_su_rinkmena, 'SubjectData' );
amzius=AuriMod_duomenys.SubjectData.Age;
visakita.Gender=AuriMod_duomenys.SubjectData.Gender; % male/female
visakita.Height=AuriMod_duomenys.SubjectData.Height; % cm


function [fizio_datasets, amzius, visakita]=ikelk_Aurimod_nepilna(katalogas_su_rinkmena)
[katalogas,vardas]=fileparts(katalogas_su_rinkmena);
AuriMod_duomenys=load(katalogas_su_rinkmena);
%{'Age' 'DiastolicPressure' 'ECG_Lead_I' 'ECG_Lead_II' 'ECG_Lead_III' 'Fs_ecg' 'Fs_pressure' 'Fs_resp' 'MeanPressure' 'Phases' 'Respiration' 'SystolicPressure' 'Time_ECG' 'Time_Pressure' 'Time_Respiration'};

% Kvėpavimas
kvepavimas=apdorok_kvepavimo_signala(AuriMod_duomenys.Respiration,AuriMod_duomenys.Fs_resp,AuriMod_duomenys.Time_Respiration);

% Širdies ritmas
[visakita.EKG, Rt]=ikelk_EKG_ir_R(katalogas,vardas, AuriMod_duomenys.ECG_Lead_II,AuriMod_duomenys.Fs_ecg);

% Kraujo spaudimas
DBP_real=timeseries(AuriMod_duomenys.DiastolicPressure, AuriMod_duomenys.Time_Pressure, 'Name', 'Diastolinis kraujo spaudimas');
SBP_real=timeseries(AuriMod_duomenys.SystolicPressure, AuriMod_duomenys.Time_Pressure, 'Name', 'Sistolinis kraujo spaudimas');

% Amžius
if ismember('Age', fieldnames(AuriMod_duomenys))
    amzius=AuriMod_duomenys.Age;
else
    amzius=NaN;
end
fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real);

function [fizio_datasets, visakita]=ikelk_per_EEGLAB(katalogas_su_rinkmena)
[katalogas,vardas,galune]=fileparts(katalogas_su_rinkmena);
EEG=eeg_ikelk(katalogas,[vardas,galune]);
if isempty(EEG)
    error('Nutraukiama neradus duomenų')
end
% kvėpavimas
[EKG_kan,RSP_kan,ABP_kan]=kanalu_parinkimas({EEG.chanlocs.labels});
kvepavimas=apdorok_kvepavimo_signala(EEG.data(RSP_kan,:)',EEG.srate,EEG.times/1000);
% širdies ritmas
R_laikai_taisyti=eeg_ivykiu_latenc(EEG,'type','R','boundary',0) / 1000;
if isempty(R_laikai_taisyti)
    [visakita.EKG, Rt]=ikelk_EKG_ir_R(...
    katalogas,vardas,EEG.data(EKG_kan,:),EEG.srate);
else
    Rt=timeseries(R_laikai_taisyti, R_laikai_taisyti, 'Name', 'R laikai, s');
    visakita=struct();
end

% Kraujo spaudimas
if isempty(ABP_kan)
    warning('Kraujo spaudimo kanalas nerastas');
    DBP_real=[]; %timeseries();
    SBP_real=[]; %timeseries();
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real);
else
    bp_sig=EEG.data(ABP_kan,:)';
    bp_sig=bp_sig-median(bp_sig,'omitnan')+80;
    
    % prie kairio skilvelio, o ir prie aortos bei carotis anksčiau nei rankos piršte
    BP_vietos_paklaida=-0.1; % FIXME: padaryti pasirenkamą?
    
    [abp,DBP_real,SBP_real]=apdorok_kraujo_spaud_signala(bp_sig,fs(ABP_kan),[],BP_vietos_paklaida);
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real,'abp',abp);
end

function [fizio_datasets, visakita]=ikelk_BIOPAC_ACQ(katalogas_su_rinkmena)
% Kintamieji: {'data' 'isi' 'isi_units' 'labels' 'start_sample' 'units' }
[katalogas,vardas]=fileparts(katalogas_su_rinkmena);
acq_data=load_acq(katalogas_su_rinkmena);
kanalu_pavad={acq_data.hdr.per_chan_data.comment_text};
[EKG_kan,RSP_kan,ABP_kan]=kanalu_parinkimas(kanalu_pavad);
fs=1000/double(acq_data.hdr.graph.sample_time); % sampling rate, Hz
t=(0:(size(acq_data.data,1)-1))/fs; % laikas

% Kvėpavimas
kvepavimas=apdorok_kvepavimo_signala(acq_data.data(1:length(t),RSP_kan),fs);

% EKG
[visakita.EKG, Rt]=ikelk_EKG_ir_R(...
    katalogas,vardas,acq_data.data(:,EKG_kan),fs);

% Kraujo spaudimas
if isempty(ABP_kan)
    warning('Kraujo spaudimo kanalas nerastas');
    DBP_real=[]; %timeseries();
    SBP_real=[]; %timeseries();
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real);
else
    bp_sig=acq_data.data(1:length(t),ABP_kan);
    bp_sig=bp_sig-median(bp_sig,'omitnan')+80;
    
    % prie kairio skilvelio, o ir prie aortos bei carotis anksčiau nei rankos piršte
    BP_vietos_paklaida=-0.1; % FIXME: padaryti pasirenkamą?
    
    [abp,DBP_real,SBP_real]=apdorok_kraujo_spaud_signala(bp_sig,fs,t,BP_vietos_paklaida);
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real,'abp',abp);
end

function [fizio_datasets, amzius, visakita]=ikelk_BIOPAC_MAT(katalogas_su_rinkmena)
% Kintamieji: {'data' 'hdr' 'markers'}
[katalogas,vardas]=fileparts(katalogas_su_rinkmena);
biopac1=load(katalogas_su_rinkmena);
kanalu_pavad=cellstr(biopac1.labels);
[EKG_kan,RSP_kan,ABP_kan]=kanalu_parinkimas(kanalu_pavad);
fs=1000; % sampling rate, Hz
t=(0:(size(biopac1.data,1)-1))/fs; % laikas
laiko_ribojimas=[];
%laiko_ribojimas=300;
if ~isempty(laiko_ribojimas)
    t=t(t<laiko_ribojimas); % apriboti iki 5 min
end

% Kvėpavimas
kvepavimas=apdorok_kvepavimo_signala(biopac1.data(1:length(t),RSP_kan),fs);

% EKG
[visakita.EKG, Rt]=ikelk_EKG_ir_R(...
    katalogas,vardas,biopac1.data(:,EKG_kan),fs);

% Kraujo spaudimas
if isempty(ABP_kan)
    warning('Kraujo spaudimo kanalas nerastas');
    DBP_real=[]; %timeseries();
    SBP_real=[]; %timeseries();
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real);
else
    bp_sig=biopac1.data(1:length(t),ABP_kan);
    bp_sig=bp_sig-median(bp_sig,'omitnan')+80;
    
    % prie kairio skilvelio, o ir prie aortos bei carotis anksčiau nei rankos piršte
    BP_vietos_paklaida=-0.1; % FIXME: padaryti pasirenkamą?
    
    [abp,DBP_real,SBP_real]=apdorok_kraujo_spaud_signala(bp_sig,fs,t,BP_vietos_paklaida);
    fizio_datasets=struct('Rt',Rt,'kvepavimas',kvepavimas,'DBP_real',DBP_real,'SBP_real',SBP_real,'abp',abp);
end
if isfield(biopac1,'Age')
    amzius=biopac1.Age;
else
    amzius=[];
end

function kvepavimas=apdorok_kvepavimo_signala(kvep_signalas,fs,times)
    if nargin < 3 || numel(kvep_signalas) ~= numel(times)
        times=(0:length(kvep_signalas)-1)/fs;
    end
    %kvep_signalas=nthroot(zscore(kvep_signalas),3);
    [b,a] = butter(4, 0.4/(fs/2), 'low'); % paliekant lestenius kaip 0.4 Hz svyravimus
    kvep_signalas = filtfilt(b,a,double(kvep_signalas(:)));
    %kvep_signalas=zscore(kvep_signalas);
    kv_min_max=[min(kvep_signalas) max(kvep_signalas)];
    kvep_signalas=(kvep_signalas - kv_min_max(1))/diff(kv_min_max)-0.5;
    kvepavimas=timeseries(kvep_signalas, times, 'Name', 'Kvėpavimas');

function [abp,DBP_real,SBP_real]=apdorok_kraujo_spaud_signala(bp_sig,fs,times,BP_vietos_paklaida)
    if nargin < 3 || numel(bp_sig) ~= numel(times)
        t=(0:length(bp_sig)-1)/fs;
    else
        t=times;
    end
    if nargin < 4
        BP_vietos_paklaida=0;
    end
    % Filtravimas
    if fs>10
        [b,a] = butter(4, 10/(fs/2), 'low'); % paliekant lestenius kaip 10 Hz svyravimus
        bp_sig = filtfilt(b,a,double(bp_sig));
    end
    % Pats kraujo spaudimo signalas
    abp=timeseries(bp_sig, t+BP_vietos_paklaida, 'Name', 'ABP');
    % Papildomai tik diastolinis ir sistolinis
    if nargout > 1
        min_rri=0.5;
        [sbp,dbp]=envelope(bp_sig,round(min_rri*fs),'peak'); % FIXME
        DBP_real=timeseries(dbp, t+BP_vietos_paklaida, 'Name', 'Diastolinis kraujo spaudimas');
        SBP_real=timeseries(sbp, t+BP_vietos_paklaida, 'Name', 'Sistolinis kraujo spaudimas');
    end
    
function [EKG, Rt, R_laikai_taisyti]=ikelk_EKG_ir_R(katalogas,vardas,ekg_signalas,fs)
% EKG
ekg_signalas=fun_ECG_Filter(fs, ekg_signalas');
t=(0:length(ekg_signalas)-1)/fs;
EKG=timeseries(ekg_signalas(:), t, 'Name', 'EKG');

% Įkelti R laikus, jei jų rinkmena jau yra
R_laikai_taisyti=[];
katalogas_su_rinkmena_RRIs={ ...
    fullfile(katalogas,[vardas '.rrt']) ...
    fullfile(katalogas,'RRI',[vardas '.rrt']) ...
    fullfile(katalogas,[vardas '_rri.mat']) ...
    fullfile(katalogas,[vardas '_RRI.mat']) ...
    fullfile(katalogas,'RRI',[vardas '_RRI.mat']) };
for ri=1:length(katalogas_su_rinkmena_RRIs)
    katalogas_su_rinkmena_RRI=katalogas_su_rinkmena_RRIs{ri};
    if exist(katalogas_su_rinkmena_RRI,'file')
        try
            MAT_kintamieji = who('-file', katalogas_su_rinkmena_RRI);
            if ismember({'R_laikai_taisyti'},MAT_kintamieji)
                load(katalogas_su_rinkmena_RRI,'-mat','R_laikai_taisyti');
                fprintf('R laikai įkelti iš\n %s\n', katalogas_su_rinkmena_RRI);
                if ~isempty(R_laikai_taisyti)
                    break;
                end
            end
        catch
        end
    end
end

% R laikų nerasti - imti iš naujo 
if isempty(R_laikai_taisyti)
    R_laikai_taisyti=rask_R_laikus(ekg_signalas,fs);
    if isempty(R_laikai_taisyti)
        error('Nutraukta.')
    else
        RRI_kelias=fullfile(katalogas,'RRI');
        if ~exist(RRI_kelias,'dir')
            mkdir(RRI_kelias);
        end
        katalogas_su_rinkmena_RRI2=fullfile(RRI_kelias,[vardas '.rrt']);
        save(katalogas_su_rinkmena_RRI2,'R_laikai_taisyti','EKG','-mat');
        fprintf('R laikai įrašyti į\n %s\n', katalogas_su_rinkmena_RRI2);
    end
end

Rt=timeseries(R_laikai_taisyti, R_laikai_taisyti, 'Name', 'R laikai, s');

function [R_laikai_taisyti]=rask_R_laikus(ekg_signalas,fs)
    %f=figure; a=axes('Parent',f); plot(a,(0:length(ekg_signalas)-1)/fs,ekg_signalas,'r-'); title('EKG'); xlabel('t, s');
    try R_indeksai=fun_qrsDetector(ekg_signalas, fs*0.4, fs); 
    catch
        R_indeksai=[];
    end
    R_laikai_ms=1000*(R_indeksai'-1)/fs;
    R_laikai_taisyti=pop_RRI_perziura(R_laikai_ms, 1, ekg_signalas, fs)/1000;

