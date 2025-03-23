function [paklaida,paklaida_sr,paklaida_bp,bauda,Rt,Rtm,SDNN,MSNA_poslinkis,RRI_laiku_prasislinkimas]=...
    r_modelio_1prasukimas(keiciamu_param_reiksmes,kintam_pavad,fiksuoti_param,fizio_datasets,trukme,kita)
%% [Paklaida]=r_modelio_1prasukimas(keiciami_param_reiksmes,kintam_pavad,fiksuoti_param,fizio_datasets,trukme,kita)
% Širdies ritmo modelio vienas prasukimas su paklaidos įvertinimu
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

% Atsarginiai išvedimui:
Rt=[];
Rtm=[];
SDNN=NaN;
MSNA_poslinkis=NaN;
RRI_laiku_prasislinkimas=[];

% numatytieji parametrai:
modelis='ritminukas24';
su_grafikais=0;
rodyti_grafikus=0;
vardas='';
issamios_klaidos=0;
ignoruojamas_laikotarpis_vertinant=30;
laiko_formatas=''; % 'mm:ss'
%issamesne_iteraciju_info=0;
fizio_flds=fieldnames(fizio_datasets);

if length(trukme) == 1
    trukme=[0 trukme];
end

% numatytoju parametrų perrašymas per „kita“
if nargin<6 || ~isstruct(kita)
    kita=struct;
end
if isfield(kita,'modelis') && ~isempty(kita.modelis)
    modelis=kita.modelis;
end
modelio_versija=str2double(regexprep(modelis,'^ritminukas(\d*).*','$1'));
if modelio_versija <= 21
    error('Modelio versija turi būti ritminukas22 arba naujesnė.')
end
if isfield(kita,'vardas') && ~isempty(kita.vardas)
    vardas=kita.vardas;
end
if isfield(kita,'su_grafikais') && ~isempty(kita.su_grafikais)
    su_grafikais=kita.su_grafikais;
end
if su_grafikais &&  isfield(kita,'rodyti_grafikus') && ...
  ~isempty(kita.rodyti_grafikus) && kita.rodyti_grafikus
    rodyti_grafikus=1;
end
if isfield(kita,'trukme2') && ~isempty(kita.trukme2)
    if length(kita.trukme2) == 1
        rodomas_laikotarpis=[0 kita.trukme2];
    else
        rodomas_laikotarpis=kita.trukme2([1 2]);
    end
    modeliuojamas_laikotarpis=[trukme(1) rodomas_laikotarpis(2)];
    vertinamas_laikotarpis=[floor(trukme(1)+min(diff(trukme)/2,ignoruojamas_laikotarpis_vertinant)) trukme(2)] ;
else
    modeliuojamas_laikotarpis=trukme;
    vertinamas_laikotarpis=[]; % []=auto, t.y. nuo 30 sekundės arba pusės trukmės
    rodomas_laikotarpis=[];
end
if isfield(kita,'issamios_klaidos') && ~isempty(kita.issamios_klaidos)
    issamios_klaidos=kita.issamios_klaidos;
end
if isfield(kita,'issamesne_iteraciju_info') && ~isempty(kita.issamesne_iteraciju_info)
    issamesne_iteraciju_info=kita.issamesne_iteraciju_info;
else
    issamesne_iteraciju_info=su_grafikais || issamios_klaidos;
end
if isfield(kita,'R_greta') && ~isempty(kita.R_greta) % && SIMUL==0
    R_greta=kita.R_greta;
elseif isfield(fiksuoti_param,'R_greta') && ~isempty(fiksuoti_param.R_greta) % && SIMUL==0
    R_greta=fiksuoti_param.R_greta;
else
    R_greta=0;
end
if isfield(kita,'R_tikras') && ~isempty(kita.R_tikras) % && SIMUL==0
    R_tikras=kita.R_tikras;
elseif isfield(fiksuoti_param,'R_tikras') && ~isempty(fiksuoti_param.R_tikras) % && SIMUL==0
    R_tikras=fiksuoti_param.R_tikras;
else
    R_tikras=0;
end
if ~isfield(kita,'paklaidos_sudedamosios') || isempty(kita.paklaidos_sudedamosios)
    kita.paklaidos_sudedamosios='auto';
end
if ismember({'auto'},lower(kita.paklaidos_sudedamosios))
    if any(ismember(kintam_pavad,{'Tmsna' 'Kv' 'Knadr' 'Kne1' 'Kne2' 'Dne1' 'Dne2' 'Imax' 'Presp' 'r' 'R' 'C' 'L'}))
        kita.paklaidos_sudedamosios=unique([kita.paklaidos_sudedamosios {'KS'}]);
    else
        kita.paklaidos_sudedamosios=unique([kita.paklaidos_sudedamosios {'SR'}]);
    end
end
if ~isfield(kita,'pakl_veiksena')
    kita.pakl_veiksena='';
end

if ~bdIsLoaded(modelis)
    load_system(modelis);
end
[SimIn,fiksuoti_ir_kint_param_struct]=r_vars2simstruct(modelis,kintam_pavad,keiciamu_param_reiksmes,fiksuoti_param,fizio_datasets,modeliuojamas_laikotarpis);
if ~isfield(kita,'FixedStep') || isempty(kita.FixedStep)
    kita.FixedStep=0.001;
end
SimIn = SimIn.setModelParameter('FixedStep',num2str(kita.FixedStep));
if ~isfield(fiksuoti_ir_kint_param_struct,'Trsa') || fiksuoti_ir_kint_param_struct.Trsa < kita.FixedStep || isnan(fiksuoti_ir_kint_param_struct.Trsa)
    if modelio_versija <= 23
        sim_blokas=[modelis '/NAmb, kvėpuojamoji aritmija //' 10 'respiratory arrthytmia/Transport Delay'];
    else
        sim_blokas=[modelis '/NAmb, kvėpuojamoji aritmija //' 10 'respiratory arrthytmia/Trsa'];
    end
    if ismember(sim_blokas,find_system(modelis))
        SimIn = SimIn.setBlockParameter(sim_blokas,'Commented','through');
    else
        warning('off','Simulink:blocks:TDelayDirectThroughAutoSet');
    end
end
if ~isfield(fiksuoti_ir_kint_param_struct,'Tmsna') || fiksuoti_ir_kint_param_struct.Tmsna < kita.FixedStep || isnan(fiksuoti_ir_kint_param_struct.Tmsna)
    sim_blokas=[modelis '/Vasculature,' 10 'Total peripheral resistance/Tmsna'];
    if ismember(sim_blokas,find_system(modelis))
        SimIn = SimIn.setBlockParameter(sim_blokas,'Commented','through');
    else
        warning('off','Simulink:blocks:TDelayDirectThroughAutoSet');
    end
    fiksuoti_ir_kint_param_struct.Tmsna=0;
%else % TODO: nuo 2023-02-01 šio bloko ritminukas25str jau nebeturi, tad reiktų perspėti naudotoją, jei naudoją šį parametrą
end
if ~(su_grafikais && issamios_klaidos)
  %if str2double(regexprep(modelis,'^ritminukas','')) > 21
    % signal data logging
    % išjungimas galbūt padės pagreitinti modeliavimą optimizuojant lygiagrečiai
    % set_param(bdroot, 'InstrumentedSignals', [])
    SimIn = SimIn.setModelParameter('InstrumentedSignals',[]);
    SimIn = SimIn.setModelParameter('SignalLogging','off');
    %set_param(blockName,'Commented','on');
    %set_param(blockName,'Commented','through');
    sim_blokas=[modelis '/SA/Širdies ritmas //' 10 'Heart rate, bmp'];
    if ismember(sim_blokas,find_system(modelis))
        SimIn = SimIn.setBlockParameter(sim_blokas,'Commented','on');
    end
  %end
else
    % SimIn = SimIn.setModelParameter('SignalLogging','on');
end
if ~(issamios_klaidos && issamesne_iteraciju_info && su_grafikais)
    ws=warning("off");
end

%{
try
    SimIn = SimIn.setModelParameter('SimulationMode', 'rapid');
    SimIn = SimIn.setModelParameter('RapidAcceleratorUpToDateCheck', 'off');
catch err
    if issamios_klaidos
        w=warning('on');
        Pranesk_apie_klaida(err,[],[],0);
        drawnow;
        warning(w);
    end
end
%}

% Darbui 
% assignin('base','SimIn',SimIn);
%for i=1:length(SimIn.Variables); assignin('base' , SimIn.Variables(i).Name, SimIn.Variables(i).Value); end; return

%evalin('base','disp([Ks,Kp, HRbasal, Presp,Krsa, Kcvlm, R])');
%disp(keiciami_param)
%fprintf('\b .\n')

try
    
    %% Simuliacija
    wv=warning('verbose','on');
    wb=warning('backtrace','off');
    %warning('off','MATLAB:matrix:warning_unexpected_end_of_file')
    
    %   P A T I   S I M U L I A C I  J A   su Simulink:
    % -----------------------------------------------------
    SimOut=sim(SimIn);
    % -----------------------------------------------------
    
    warning(wv);
    warning(wb);
    %return

    %% Simuliacijos rezultatų analizė
    
    Rt=unique(fizio_datasets.Rt.Data);
    % Rtm=unique(SimOut.Rtm.Data)+SimOut.Rtm.Time(1); % ritminukas21
    Rtm=unique(SimOut.Rtm.Data); % ritminukas22 arba naujesnė
    SR_tkr=60./diff(Rt);
    rri=diff(Rtm);
    min_rri=min(rri(rri>0.3));
    %if ismember('SR_skirtumas',who(SimOut))
    %    SR_time=SimOut.SR_skirtumas.Time;
    %    sr_paklaidos_laike=SimOut.SR_skirtumas.Data;
    %else
        % apskaičiuoti pagal Rt ir Rtm
        SR_time=(max(Rt(1),Rtm(1)):0.001:min(Rt(end),Rtm(end)))';
    %end
        
    if isempty(vertinamas_laikotarpis)
        SR_time_vertinimui_nuo=floor(SR_time(1)+min(diff(SR_time([1 end]))/2,ignoruojamas_laikotarpis_vertinant));
        SR_time_vertinimui_iki=Rtm(find(Rtm<=trukme(2),1,'last'));
    else
        SR_time_vertinimui_nuo=vertinamas_laikotarpis(1);
        SR_time_vertinimui_iki=Rtm(find(Rtm<=vertinamas_laikotarpis(2),1,'last'));
    end
    %fprintf('Vertinamas laikotarpis: %.4f-%.4f s\n', SR_time_vertinimui_nuo,SR_time_vertinimui_iki);
    SR_time_vertinimui_nuo_i=find(SR_time>=SR_time_vertinimui_nuo,1);
    SR_time_vertinimui_iki_i=find(SR_time<=SR_time_vertinimui_iki,1,'last');
    %SR_time_vert=SR_time(SR_time_vertinimui_nuo_i:end);
    if isempty(rodomas_laikotarpis)
        rodomas_laikotarpis=[SR_time_vertinimui_nuo SR_time_vertinimui_iki];
    end
    
    % SDNN tikrų R-R intervalų
    SDNN=std(diff(Rt(Rt >= SR_time_vertinimui_nuo & Rt <= SR_time_vertinimui_iki))*1000); % milisendėmis
    
    % Sugretinami R?
    if R_greta
        [Rt_greta,Rtm_greta,RRI_laiku_prasislinkimas,SR_mdl]=R_sugretinimas(Rt,Rtm,modeliuojamas_laikotarpis,issamios_klaidos);
    else
        SR_mdl=60./diff(Rtm);
    end
    if any(ismember(upper({'RRI' 'RRIms' 'RRI/10'}),upper(kita.paklaidos_sudedamosios)))
        if R_greta
            sr_paklaidos_laike=interp1(Rt_greta,RRI_laiku_prasislinkimas,SR_time,'previous')*1000;
            paklaida_sr=paklaidos_vertinimas(-RRI_laiku_prasislinkimas(Rt_greta>=SR_time_vertinimui_nuo & Rt_greta <= SR_time_vertinimui_iki)*1000,kita.pakl_veiksena);
        else
            sr_paklaidos_laike=(interp1(Rt(2:end),diff(Rt),SR_time,'previous')-interp1(Rtm(2:end),diff(Rtm),SR_time,'previous'))*1000;
            paklaida_sr=paklaidos_vertinimas(sr_paklaidos_laike(SR_time_vertinimui_nuo_i:SR_time_vertinimui_iki_i),kita.pakl_veiksena);
        end
        paklaida_sr=paklaida_sr/10; % kiek priartinti prie tų reikšmių, kurios būna matuojant kartais per minutę
    else % ŠR, k/min
        if R_greta
            SR_paklaida_Rgreta=SR_mdl-60./(diff(Rt_greta));
            sr_paklaidos_laike=interp1(Rt_greta(2:end), SR_paklaida_Rgreta, SR_time, 'previous');
            SR_paklaida_Rgreta_idx=setdiff(find(Rt_greta>=SR_time_vertinimui_nuo & Rt_greta <= SR_time_vertinimui_iki),1)-1;
            paklaida_sr=paklaidos_vertinimas(SR_paklaida_Rgreta(SR_paklaida_Rgreta_idx),kita.pakl_veiksena); 
            clear SR_paklaida_Rgreta SR_paklaida_Rgreta_idx
        else
            sr_paklaidos_laike=interp1(Rtm(2:end),SR_mdl,SR_time,'previous')-interp1(Rt(2:end),SR_tkr,SR_time,'previous');
            paklaida_sr=paklaidos_vertinimas(sr_paklaidos_laike(SR_time_vertinimui_nuo_i:SR_time_vertinimui_iki_i),kita.pakl_veiksena);
        end
    end
    % Ypatingais atvejais sr_paklaidos_laike gali būti tūkstančiai k/min, bet grafikams apriboti iki 250
    %sr_paklaidos_laike(sr_paklaidos_laike>=250)=NaN;
    %assignin('base',[ 'sr_paklaidos_laike_' datestr(now,'yyyymmDDHHMM')], sr_paklaidos_laike(SR_time_vertinimui_nuo_i:SR_time_vertinimui_iki_i))
    
    % papildomai tikrinti, kad nurodyti signalai nebūtų tušti
    if R_tikras || (ismember('abp',fizio_flds) && ~isempty(fizio_flds) && ~all(fizio_datasets.abp==0))
        [MSNA_laik,MSNA_sgnl,MSNA_poslinkis,bauda]=MSNA_info_ir_bauda(SimOut,SR_time_vertinimui_nuo, SR_time_vertinimui_iki, fiksuoti_ir_kint_param_struct.Tmsna, Rt);
    else
        [MSNA_laik,MSNA_sgnl,MSNA_poslinkis,bauda]=MSNA_info_ir_bauda(SimOut,SR_time_vertinimui_nuo, SR_time_vertinimui_iki, fiksuoti_ir_kint_param_struct.Tmsna, Rtm);
    end
    
    % Bauduoti už poreikį koreguoti Rtm_greta įterpiant NaN
    if R_greta % && ismember({'bauda'},kita.paklaidos_sudedamosios)
        Rtm_greta_vert=Rtm_greta(Rt_greta>=SR_time_vertinimui_nuo & Rt_greta <= SR_time_vertinimui_iki);
        Rtm_greta_NaN_N=sum(isnan(Rtm_greta_vert));
        Rtm_greta_NaN_dalis=Rtm_greta_NaN_N/length(Rtm_greta_vert);
        if Rtm_greta_NaN_dalis > 0.05
            bauda=bauda+Rtm_greta_NaN_dalis*20;
        end
    end
    
    if ismember('BP_model',who(SimOut))
        % Kraujo spaudimas modeliuotas
        BP_model=SimOut.BP_model;
        BP_model_vals=BP_model.Data;
        BP_model_time=BP_model.Time;
        BP_time_vertinimui_nuo_i=find(BP_model_time>=SR_time_vertinimui_nuo,1);
        BP_time_vertinimui_iki_i=find(BP_model_time<=SR_time_vertinimui_iki,1,'last');
        BP_model_sampling_time=diff(BP_model_time([1 2]));
        [SBP_model_vals,DBP_model_vals]=envelope(BP_model_vals,round(min_rri/BP_model_sampling_time),'peak');  % FIXME. Dabar pririšu prie min_rri lango
        if ismember({'KS'},upper(kita.paklaidos_sudedamosios))
            DBP_model_vals_median=median(DBP_model_vals(BP_time_vertinimui_nuo_i:BP_time_vertinimui_iki_i),'omitnan');
            if DBP_model_vals_median < 40
                bauda=bauda+(60-DBP_model_vals_median)/2; % 10+
            elseif DBP_model_vals_median < 70
                bauda=bauda+(70-DBP_model_vals_median)/5; % 0-6
            elseif DBP_model_vals_median > 120
                bauda=bauda+(DBP_model_vals_median-100)/2; % 10+
            elseif DBP_model_vals_median > 90
                bauda=bauda+(DBP_model_vals_median-90)/5; % 0-6
            end
        end
    end
        
    if all(ismember({'DBP_real' 'SBP_real'}, fizio_flds)) && ... % turim SBP_real, DBP_real
      ~isempty(fizio_datasets.SBP_real) && sum(fizio_datasets.SBP_real.Data,'omitnan') && ...
      ~isempty(fizio_datasets.DBP_real) && sum(fizio_datasets.DBP_real.Data,'omitnan')
        
        if ismember('BP_model',who(SimOut))
            SBP_real_vals=interp1(fizio_datasets.SBP_real.Time,fizio_datasets.SBP_real.Data,BP_model_time);
            DBP_real_vals=interp1(fizio_datasets.DBP_real.Time,fizio_datasets.DBP_real.Data,BP_model_time);
        else
            BP_model_time=fizio_datasets.SBP_real.Time;
            SBP_real_vals=fizio_datasets.SBP_real.Data;
            DBP_real_vals=fizio_datasets.DBP_real.Data;
        end
        if ismember('BP_model',who(SimOut))
            SBP_skirtumas=SBP_model_vals-SBP_real_vals;
            DBP_skirtumas=DBP_model_vals-DBP_real_vals;
            MBPd=(SBP_skirtumas+2*DBP_skirtumas)/3; % skirtumas tik pagal BP
            d2=MBPd(BP_time_vertinimui_nuo_i:BP_time_vertinimui_iki_i);
            d2=d2-median(d2,'omitnan'); d2=d2*10; % Portapres bazinis lygis nestabilus, tad ignoruokim; bet padidinkime koeficientą
            d2(find(isnan(d2)))=0; %#ok neleisti NaN
            paklaida_bp=paklaidos_vertinimas(d2,kita.pakl_veiksena);
            if ismember({'KS'},upper(kita.paklaidos_sudedamosios)) 
                if any(ismember(upper({'SR' 'RRI' 'RRIms' 'RRI/10'}),upper(kita.paklaidos_sudedamosios)))
                    paklaida=(paklaida_sr*2+paklaida_bp)/3; % optimizuoti tiek pagal ŠR (67%), tiek pagal BP (33%)
                else
                    paklaida=paklaida_bp; % testavimui: optimizuoti tik pagal BP
                end
            else
                paklaida=paklaida_sr;
            end
        else
            paklaida=paklaida_sr;
            paklaida_bp=NaN;
            MBPd=[];
            if ismember({'KS'},upper(kita.paklaidos_sudedamosios)) && issamios_klaidos
                warning('Prasete, bet negalima apskaiciuoti kraujo spaudimo paklaidu.')
            end
        end
        
    else
        SBP_real_vals=[];
        DBP_real_vals=[];
        paklaida=paklaida_sr;
        paklaida_bp=NaN;
        MBPd=[];
    end
    
    if any(ismember(upper({'RRIms' 'RRI'}),upper(kita.paklaidos_sudedamosios)))
        paklaida=paklaida*10;
        paklaida_sr=paklaida_sr*10;
        bauda=bauda*10;
    end
    
    if ismember({'bauda'},kita.paklaidos_sudedamosios) && bauda
        paaisktxt=sprintf([' (' r_lokaliz('is ju %g baudos') ')'], bauda); 
        paklaida=paklaida+bauda;
    else
        paaisktxt='';
    end
    if issamesne_iteraciju_info
        fprintf('%s %% =%f%s\n', sprintf(' %8.4f',keiciamu_param_reiksmes), paklaida, paaisktxt);
    end
    if R_greta
        paaisktxt=[paaisktxt ' [' r_lokaliz('R gretinimas') '] ' ];
    end
    
    
    %% Grafikai
    
    if su_grafikais
        
        % FIXME: atskirti grafikų piešimą nuo paklaidų vertinimo į kitą f-ją
        %{.
        %a=findobj('type','axes','Tag','modelio_paklaida_gyvai');
        f=findobj('type','figure','Tag','modelio_paklaida_gyvai');
        %if isempty(a)
        if isempty(f)
            f=figure('Tag','modelio_paklaida_gyvai', 'Name','Paklaidos', 'NumberTitle','off');
            if ispc
                f.Units='pixels'; f.Position=[100 100 1000 600];
            else
                f.Units='normalized'; f.OuterPosition=[0 0.05 1 0.95];
            end
            %a=axes('Parent',f,'Tag','modelio_paklaida_gyvai');
        else
            delete(f.Children);
            %figure(f)
            %f=a.Parent;
        end
        f.Visible=rodyti_grafikus;
        %if ~isempty(a)
        %if idx == 1
        %    try delete(a.Children); catch; end
        %end
        %if all(ismember({'DBP_real' 'SBP_real'}, fizio_flds))
        %    yyaxis(a,'left');
        %end
        %{.
        
        % Paklaidos
        a1=axes('Parent',f);
        a1.Tag='modelio_paklaida_gyvai1';
        subplot(3,1,1,a1); 
        yyaxis(a1,'right');
        ret=max(floor(0.1/diff(fizio_datasets.kvepavimas.Time([1 2]))),1);
        plot(a1,fizio_datasets.kvepavimas.Time(1:ret:end),fizio_datasets.kvepavimas.Data(1:ret:end), 'c-');
        set(a1,'YColor','b'); ylabel(a1,r_lokaliz('Kvepavimas, n.v.'));
        hold(a1,'on'); 
        if ~isempty(vertinamas_laikotarpis)
            % patch_x=reshape(repmat(datetime(0,0,0,0,0,vertinamas_laikotarpis),[2 1]),[1 4]);
            patch_x=vertinamas_laikotarpis([1 1 2 2]);
            patch_y=[0 0.1 0.1 0]-0.5;
            p=patch(a1,patch_x,patch_y,'yellow');
            set(p,'EdgeColor','none','FaceAlpha',0.2,'HandleVisibility','off')
        end
        if isfield(kita,'zymekliai')
            zymekliu_x=reshape([repmat(kita.zymekliai,[2 1]); NaN(1,length(kita.zymekliai))],1,[]);
            zymekliu_y=reshape(repmat([-0.4 0.4 NaN],[length(kita.zymekliai) 1])',1,[]);
            plot(a1,zymekliu_x,zymekliu_y,'g--','HandleVisibility','off')
        end
        a1.YLim=[0 1]-0.5;
        yyaxis(a1,'left');
        hold(a1,'off');
        hold(a1,'on');
        stairs(a1,Rt(2:end),SR_tkr,'k.-'); % tikras ŠR
        if R_greta
            % apsidraudimui, jei Rtm-1 ir SR_mdl ilgiai skirtųsi; 
            % t.y. jei skirtųsi Rt_greta ir Rtm_greta ilgiai, nuo kurių priklauso SR_mdl
            % nors jei jie skiriasi – tai turėtų būti modelio klaida...
            stairs(a1,Rtm_greta(2:end),SR_mdl,'r.-'); % virtualus ŠR
        else
            stairs(a1,Rtm(2:end),SR_mdl,'r.-'); % modeliuotas ŠR
        end
        set(a1,'YColor','k');
        ylabel(a1,r_lokaliz('SR, k/min')); %xlabel(a,'Laikas, s');
        xlim(a1,rodomas_laikotarpis);
        if a1.YLim(2) > 200
            a1.YLim=[a1.YLim(1) min(a1.YLim(2),250)];
        else
            a1.YLim=a1.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
        end
        %}
        legend(a1,{r_lokaliz('SR tikras') r_lokaliz('SR virtualus') r_lokaliz('Kvepavimas')}) % 'Kvėpavimas' ,'Location','best'
        % Pavadinimas
        title(a1,vardas,'Interpreter','none')
        subtitle(a1,sprintf('%s [%g %g] s %s: %.4f%s',...
            r_lokaliz('Paklaida'), ...
            floor(SR_time_vertinimui_nuo),ceil(SR_time_vertinimui_iki), ...
            r_lokaliz('lange'), ...
            paklaida,paaisktxt))
        
        % (M)SNA ir kraujo spaudimas
        a2=axes('Parent',f);
        a2.Tag='modelio_paklaida_gyvai2';
        subplot(3,1,2,a2); hold(a2,'off');
        if length(MSNA_laik)>1 && length(MSNA_laik)==length(MSNA_sgnl)
            yyaxis(a2,'left');
            set(a2,'YColor',[0.1 0.6 0]); % tamsiai žalia
            ret=max(floor(0.01/diff(MSNA_laik([1 2]))),1);
            plot(a2,tfrm(MSNA_laik(1:ret:end),laiko_formatas),MSNA_sgnl(1:ret:end),'g');
            a2.YLim=a2.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
            if fiksuoti_ir_kint_param_struct.Tmsna == 0
                ylabel(a2,r_lokaliz('SNA, s.v.'));
                legendai2={r_lokaliz('SNA')};
            else
                ylabel(a2,r_lokaliz('MSNA, s.v.'));
                legendai2={r_lokaliz('MSNA')};
            end
            yyaxis(a2,'right');
            hold(a2,'off');
        else
            legendai2={};
        end
        if ismember('BP_model',who(SimOut)) || ~isempty(SBP_real_vals)
            ret=max(floor(0.2/diff(BP_model_time([1 2]))),1);
            BP_model_time_t=tfrm(BP_model_time(1:ret:end),laiko_formatas);
            if ~isempty(SBP_real_vals) && ~isempty(DBP_real_vals)
                plot(a2,BP_model_time_t,SBP_real_vals(1:ret:end),'r-'); hold(a2,'on');
                plot(a2,BP_model_time_t,DBP_real_vals(1:ret:end),'b-')
                legendai2=[legendai2 {r_lokaliz('Sist. tikras') r_lokaliz('Dias. tikras')} ];
            end
            if ismember('BP_model',who(SimOut))
                plot(a2,BP_model_time_t,SBP_model_vals(1:ret:end),'m-'); hold(a2,'on');
                plot(a2,BP_model_time_t,DBP_model_vals(1:ret:end),'c-')
                legendai2=[legendai2 {r_lokaliz('Sist. model.') r_lokaliz('Dias. model.')}];
            end
            a2.YLim=a2.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
            set(a2,'YColor','k');
            ylabel(a2,r_lokaliz('Kraujo sp., mmHg'))
        end
        grid(a2,'on');
        legend(a2,legendai2) % ,'Location','best'
        if isempty(laiko_formatas)
            xlim(a2,rodomas_laikotarpis);
            %xlim(a2,SR_time_t([SR_time_vertinimui_nuo_i SR_time_vertinimui_iki_i]));
        else
            datetick(a2,'x','MM:SS')
            xlim(a2,tfrm(rodomas_laikotarpis,laiko_formatas))
        end
        
        % Paklaidos
        a3=axes('Parent',f);
        a3.Tag='modelio_paklaida_gyvai3';
        subplot(3,1,3,a3);
        hold(a3,'off');
        if any(ismember(upper({'RRI' 'RRIms' 'RRI/10'}),upper(kita.paklaidos_sudedamosios)))
            if R_greta %&& ~isempty(RRI_laiku_prasislinkimas)
                %plot(a3,tfrm(SR_time,laiko_formatas),sr_paklaidos_laike,'k-','HandleVisibility','off');
                %hold(a3,'on');
                stairs(a3,tfrm(Rt_greta,laiko_formatas),RRI_laiku_prasislinkimas*1000,'k.-'); %
                %stairs(a3,Rt_greta_t,RRI_laiku_prasislinkimas*1000,'k:'); % ,'HandleVisibility','off'
                ylabel(a3, [r_lokaliz('R prasislinkimas') ' (' r_lokaliz('tikr.-virt.') '), ' r_lokaliz('ms')]);
                legendai3={r_lokaliz('R prasislinkimas')};
            else
                plot(a3,tfrm(SR_time,laiko_formatas),sr_paklaidos_laike,'k-');
                ylabel(a3, [r_lokaliz('RRI skirtumas') ' (' r_lokaliz('tikr.-virt.') '), ' r_lokaliz('ms')]);
                legendai3={r_lokaliz('RRI skirtumas')};
            end
            if a3.YLim(1) < -1400
                a3.YLim=[max(a3.YLim(1),-1500) a3.YLim(2)];
            end
        else % ŠR k/min
            plot(a3,tfrm(SR_time,laiko_formatas),sr_paklaidos_laike,'k-');
            if a3.YLim(2) > 200
                a3.YLim=[a3.YLim(1) min(a3.YLim(2),250)];
            end
            ylabel(a3,[r_lokaliz('SR paklaida') ' (' r_lokaliz('virt.-tikr.') '), ' r_lokaliz('k/min')]);
            legendai3={r_lokaliz('SR paklaida')};
        end
        grid(a3,'on');
        if isempty(laiko_formatas)
            xlabel(a3, r_lokaliz('Laikas, s'));
            xlim(a3,rodomas_laikotarpis);
            %xlim(a3,SR_time_t([SR_time_vertinimui_nuo_i SR_time_vertinimui_iki_i]));
        else
            datetick(a3,'x','MM:SS')
            xlabel(a3,[r_lokaliz('Laikas') ', ' laiko_formatas ]);
            xlim(a3,tfrm(rodomas_laikotarpis,laiko_formatas));
        end
        a3.YLim=a3.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
        if ~isempty(MBPd)
            yyaxis(a3,'right'); hold(a3,'off'); set(a3,'YColor','m')
            plot(a3,tfrm(BP_model_time,laiko_formatas),MBPd,'LineStyle','-','Color', 'm'); % [0.494 0.184 0.557]
            %if R_greta && ~isempty(RRI_laiku_sugretinimas)
            %    ylabel(a,'KS paklaida (tikr.-mod), mmHg');
            %else
            ylabel(a3,[r_lokaliz('KS paklaida') ' (' r_lokaliz('mod.-tikr.') '), mmHg']); set(a3,'YDir','reverse');
            %end
            a3.YLim=a3.YLim; % fiksuos Y ribas - kad nevažinėtų slenkant
            %hold(a,'on'); plot(a,BP_model_time(BP_time_vertinimui_nuo_i:end),-d2/10,'m:')
            legend(a3,[legendai3 {r_lokaliz('KS paklaida')}]) % ,'Location','best'
        end
        
        % Papildomas palygiavimas ir ašys
        linkaxes([a1 a2 a3],'x'); % X koordinačių susiejimas tarp ašių
        for ax=findobj(f,'type','axes')'
            ax.Position=[0.05 ax.Position(2) 0.9 ax.Position(4)];
        end
        for lg=findobj(f,'type','legend')'
            lg.Position=lg.Position+[0.005 0.05 0 0];
        end
        
        
        % informacijos mygtukas
        nerodytini_fiksuoti_kintamieji={'SIMUL' 'R_tikras' 'R_greta' 'Ssmpt' 'Tbf'};
        if isfield(kita,'beprasmiai_fiksuoti_kintamieji')
            nerodytini_fiksuoti_kintamieji=unique([nerodytini_fiksuoti_kintamieji kita.beprasmiai_fiksuoti_kintamieji]);
        end
        fiksuoti_param2=rmfield(fiksuoti_param,nerodytini_fiksuoti_kintamieji);
        struct2txt2=@(strc)cellfun(@(flds)sprintf('%s=%.5g; ', flds,strc.(flds)), fieldnames(strc), 'UniformOutput', false);
        modelio_param_strc=cell2struct(num2cell(keiciamu_param_reiksmes(:)),kintam_pavad(:));
        modelio_param_clstr=[struct2txt2(modelio_param_strc); {' '}; struct2txt2(fiksuoti_param2)];
        infotxt1=sprintf('%s', modelio_param_clstr{:});
        uicontrol(f, 'style','text', 'String',infotxt1,'FontSize',6, 'Units','normalized', 'Position', [0.05 0.02 0.95 0.02], 'HorizontalAlignment','left','Tag','ParamInfoTXT')
        infotxt=sprintf('%s\n', ['% ' vardas], ['%  ' modelis], '%  modelio parametrai:', ' ', modelio_param_clstr{:} );
        infotxt=strrep(infotxt,sprintf('\n \n \n'),sprintf('\n \n')); 
        infostrc=cell2struct([struct2cell(fiksuoti_param2);num2cell(keiciamu_param_reiksmes(:))],[fieldnames(fiksuoti_param2);kintam_pavad(:)]);
        infocb=['ans=get(gco,''Tooltip'');  clipboard(''copy'',ans); ' ...
            'ans=findobj(gcf,''Type'',''uicontrol'',''style'',''text'',''Tag'',''ParamInfoTXT''); ' ...
            'try set(ans,''Visible'',1-get(ans,''Visible'')); catch; end; ' ...
            'if exist(''scrollplot2'',''file'') && exist(''scrollplot3'',''file''); ' ...
               'try set(findobj(findobj(gcf,''Type'',''Axes'',''Tag'',''scrollAx'')),''Visible'',1-get(ans,''Visible'')); catch; end; ' ...
               'ans={''WindowButtonDownFcn'' ''WindowButtonUpFcn'' ''WindowButtonMotionFcn'' ''WindowScrollWheelFcn'' ''WindowKeyPressFcn'' ''WindowKeyReleaseFcn''}; ' ...
               'if isempty(get(gcf,''UserData'')); set(gcf,''UserData'',{'''' '''' '''' '''' '''' ''''}); end; ' ...
               'ans=[ans; get(gcf,''UserData'')]; try set(gcf,ans{:},''UserData'',get(gcf,ans(1,:))); catch; end; ' ...
            'end; ans=get(gco,''UserData''); drawnow'];
        uicontrol(f, 'style','pushbutton', 'Units','normalized','Position',[0.01 0.01 0.02 0.04],...
            'String','i','Tooltip',infotxt, 'UserData',infostrc, 'Callback',infocb);
    
        
        drawnow;
    end
    
    
catch err
    %% Netikėta klaida
    
    if issamesne_iteraciju_info
        fprintf('%s %% E: %s\n', sprintf(' %8.4f',keiciamu_param_reiksmes), err.message(1,:));
    end
    if issamios_klaidos
        w=warning('on');
        Pranesk_apie_klaida(err,[],[],0);
        drawnow;
        warning(w);
    end
    %{
    if exist('tout','var')
        % length of "d" should be the same as "tout"
        d=ones(1,trukme/2/(tout(end)/(numel(tout)-1))+1)*Inf;
    else
        d=Inf;
    end
    %}    
    paklaida=Inf;
    paklaida_sr=Inf;
    paklaida_bp=Inf;
    bauda=Inf;
end
if ~(issamios_klaidos && issamesne_iteraciju_info && su_grafikais)
    warning(ws)
end

function [MSNA_laik,MSNA_sgnl,MSNA_poslinkis,bauda]=MSNA_info_ir_bauda(SimOut,SR_time_vertinimui_nuo, SR_time_vertinimui_iki, Tmsna, Rt)
    % Atsarginiai išvedimo parametrai, jei nebūtų nei vienas atvejis žemiau
    bauda=0;
    MSNA_poslinkis=NaN;
    MSNA_laik=[];
    MSNA_sgnl=[];
    
    Rt_kiekis=sum(Rt>=SR_time_vertinimui_nuo & Rt<=SR_time_vertinimui_iki);
    
    if any(ismember({'SNA' 'MSNA'},who(SimOut)))
        if ismember('MSNA',who(SimOut))
            MSNA_laik=SimOut.MSNA.Time;
            MSNA_sgnl=SimOut.MSNA.Data;
        else % SNA; MSNA=SNA+Tmsna
            MSNA_laik=SimOut.SNA.Time+Tmsna;
            MSNA_sgnl=SimOut.SNA.Data;
        end
        MSNA_sgnl2=0.001*round(1000*MSNA_sgnl(MSNA_laik>=SR_time_vertinimui_nuo & MSNA_laik<=SR_time_vertinimui_iki)); % suapvalinti iki tūkstantųjų, tik vertinamą laike signalo dalį
        [MSNA_poslinkis,bauda]=MSNA_info_ir_bauda2(Rt,Rt_kiekis,MSNA_laik,MSNA_sgnl,MSNA_sgnl2,Tmsna);
        bauda=MSNA_info_ir_bauda3(Rt_kiekis,MSNA_sgnl2,bauda);
    elseif ismember('logsout',who(SimOut)) && SimOut.logsout.numElements
        kritiniai_signalu_vardai={'MSNA'}; %  'TPR'
        for i=1:SimOut.logsout.numElements
            sig_vardas=SimOut.logsout{i}.Name;
            if  ismember(sig_vardas,kritiniai_signalu_vardai) % && ismember({'bauda'},kita.paklaidos_sudedamosios) ) || ( ismember(sig_vardas,{'MSNA'}) )
                laik=SimOut.logsout{i}.Values.Time;
                sgnl=SimOut.logsout{i}.Values.Data;
                sgnl2=0.001*round(1000*sgnl(laik>=SR_time_vertinimui_nuo & laik<=SR_time_vertinimui_iki)); % suapvalinti iki tūkstantųjų, tik vertinamą laike signalo dalį
                
                if ismember(sig_vardas,{'MSNA'})
                    MSNA_laik=laik;
                    MSNA_sgnl=sgnl;
                    [MSNA_poslinkis,bauda]=MSNA_info_ir_bauda2(Rt,Rt_kiekis,MSNA_laik,MSNA_sgnl,sgnl2,Tmsna);
                end
                bauda=MSNA_info_ir_bauda3(Rt_kiekis,sgnl2,bauda);
            end
        end
    end
    bauda=min(bauda,25);


function [MSNA_poslinkis,bauda]=MSNA_info_ir_bauda2(Rt,Rt_kiekis,laik,sgnl,sgnl2,Tmsna)
MSNA_poslinkis=NaN;
bauda=0;
%signale apatinis pikas > 0 ?
pks=findpeaks(-sgnl);
if abs(sum(pks)) > 0 % && ismember({'bauda'},kita.paklaidos_sudedamosios)
    %if su_grafikais; findpeaks(-sgnl); end
    %error('%s signale apatinis pikas nėra 0!',SimOut.logsout{i}.Name)
    bauda=bauda+5;
end

% ar ne per ilgai užsitęsė persisotinimas?
mxi=find(sgnl2==max(sgnl2));
mxi1=mxi([1; 1+find(diff(mxi)>1)]);
mxi2=mxi([find(diff(mxi)>1); end]);
mx_ilgiai_sek=(mxi2-mxi1)*diff(laik([1 2]));
if any(mx_ilgiai_sek > 0.3) && max(sgnl2) > 1e-8 % &&  ismember({'bauda'},kita.paklaidos_sudedamosios)
    bauda=bauda+5;
end

if Rt_kiekis > 10
    %if numel(mxi1) > Rt_kiekis/2 % && ismember({'bauda'},kita.paklaidos_sudedamosios)
    %    bauda=bauda+numel(mxi1)/Rt_kiekis*10;
    %end
    if std(sgnl2) > 1e-8
        R_sig=interp1(Rt,Rt,laik,'previous');
        R_sig=[0; diff(R_sig)>0];
        skiriamumas_laike=diff(laik([1 2]));
        ignoruotas_laikas=0.4+Tmsna;
        ignoruoti_taskai=round(ignoruotas_laikas/skiriamumas_laike);
        [a,b]=xcorr(R_sig,sgnl,round(5/skiriamumas_laike)); 
        [~,mi]=max(a(b<-ignoruoti_taskai));
        MSNA_poslinkis=-b(mi)*skiriamumas_laike;
        %MSNA_poslinkis=kross_koreliacija2(R_sig,sgnl)*skiriamumas_laike;
        % # FIXME: MSNA>SNA; bauda tik nuotolį, bet nepririšti prie ~1.3
        if abs(MSNA_poslinkis-1.3) > 0.1 && Tmsna % && ismember({'bauda'},kita.paklaidos_sudedamosios)
            bauda=bauda+abs(MSNA_poslinkis-1.3)*10;
        elseif MSNA_poslinkis>0.8 && ~Tmsna
            bauda=bauda+(MSNA_poslinkis-0.8)*10;
        end
    end
end

function bauda=MSNA_info_ir_bauda3(Rt_kiekis,sgnl2,bauda)
%if ~bauda %  && ismember({'bauda'},kita.paklaidos_sudedamosios)
    if std(sgnl2) < 1e-8
        %error('%s signalas yra tiesi linija!',SimOut.logsout{i}.Name)
        bauda=bauda+20;
    elseif length(find(sgnl2-mean(sgnl2)))/Rt_kiekis < 0.1
        %error('%s signale per mažai reikšmių!',SimOut.logsout{i}.Name)
        bauda=bauda+5;
    end
%end

function t=tfrm(t,laiko_formatas)
if ~isempty(laiko_formatas)
    t=datetime(0,0,0,0,0,t,'Format',laiko_formatas);
end

function paklaida=paklaidos_vertinimas(d,pakl_veiksena)
d=d(~isnan(d));
if nargin<2
    pakl_veiksena='';
end
switch pakl_veiksena
    case {'iqr+mean'}
        paklaida=iqr(d)+mean(abs(d));
    case {'rms-m'}
        paklaida=rms(d-median(d));
    otherwise
        paklaida=rms(d);
end
if isnan(paklaida)
    paklaida=Inf;
end
