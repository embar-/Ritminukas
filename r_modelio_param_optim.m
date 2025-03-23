function [optimalus_param,paklaidos_ivertis,prasukimuN]=r_modelio_param_optim(x0,lb,ub,keiciamu_param_vardai,fiksuoti_param,fizio_datasets,trukme, paieskos_algoritmas,TryUseParallel, kita)
 % keiciami_param - vektorius
 % fiksuoti_param - struct
 % fizio_datasets - struct (bent jau 'Rt' ir 'kvepavimas')
 % trukme - numeric, sek

 
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
 
 paklaidos_ivertis=Inf;
 prasukimuN=0;
 papildomi_param={};
 katal=pwd;
 lygiagretus=false; % vėliau pasikeičia automatiškai pagal TryUseParallel ir realias kompiuterio galimybes
 rodyti_grafikus=isfield(kita,'rodyti_grafikus') && kita.rodyti_grafikus; % isfield(kita,'issamesne_iteraciju_info') && kita.issamesne_iteraciju_info
 didesnis_tikslumas=1; % ispc;
 
 %SimulinkSDIclearDMR;
 AutoArchiveMode=Simulink.sdi.getAutoArchiveMode;
 ArchiveRunLimit=Simulink.sdi.getArchiveRunLimit;
 
 fja=@(keiciami_param)r_modelio_1prasukimas(keiciami_param,keiciamu_param_vardai, fiksuoti_param, fizio_datasets, trukme, kita);

 
 if ismember(paieskos_algoritmas, {'surrogateopt' 'patternsearch' 'MultiStart' 'ga' 'particleswarm'}) % išskyrus 'GlobalSearch'
     
     if exist('TryUseParallel','var') && TryUseParallel
         % dar žr. https://www.mathworks.com/help/gads/how-to-use-parallel-processing.html
         % nors naudoti su Simulink nerekomenduoja: https://www.mathworks.com/help/simulink/ug/not-recommended-using-sim-function-within-parfor.html
         try
             poolobj = gcp('nocreate');
             if isempty(poolobj)
                 % SimulinkSDIclearDMR;
                 poolobj=parpool('local'); %#ok
             end
             papildomi_param=[ papildomi_param {'UseParallel', true} ];
             lygiagretus=true;
             SimulinkSDIclearDMR;
             
             % Jei lygiagretūs procesai - jie turėtų vykti atskiruose aplankuose
             % Create temporary directory for simulation on worker
             spmd
                 tempDir = tempname;
                 mkdir(tempDir);
                 cd(tempDir);
                 SimulinkAutoArchiveSwitch(1);
                 if isfield(kita,'modelis')
                     load_system(kita.modelis);
                     set_param(kita.modelis,'SignalLogging','off');
                     set_param(kita.modelis,'InstrumentedSignals',[]);
                 end
             end
             
         catch err
             w=warning('on');
             Pranesk_apie_klaida(err,[],[],0);
             warning(w);
             SimulinkSDIclearDMR;
         end
     end
     SimulinkAutoArchiveSwitch(lygiagretus)
 end
 
 switch paieskos_algoritmas
     % Kuo skiriasi algoritmai? 
     % žr. https://www.mathworks.com/help/gads/example-comparing-several-solvers.html
     
     case {'fmincon'}
         papildomi_param=[ papildomi_param {'StepTolerance',0.001}];
         if rodyti_grafikus
             papildomi_param=[papildomi_param {'PlotFcn',{@optimplotfval,@optimplotfunccount}}];
         end
         options = optimoptions('fmincon', ...
             papildomi_param{:});
         [optimalus_param,paklaidos_ivertis,exitflag,output] = fmincon(fja,x0,[],[],[],[],lb,ub,[],options); % ši funcija nepriima 0 kaip x0!
         fprintf('Iteracijų: %d\nPrasukimų: %d\n', output.iterations, output.funcCount);
         prasukimuN=output.funcCount;
         
     case {'patternsearch'}
         
         if didesnis_tikslumas
             % serveriniam kompiuteriui galima užduoti rimčiau
             papildomi_param=[ papildomi_param {'FunctionTolerance',0.001,'StepTolerance',0.001}];
         else
             papildomi_param=[ papildomi_param {'FunctionTolerance',0.01, 'StepTolerance',0.005}];
         end
         if rodyti_grafikus
             papildomi_param=[papildomi_param {'PlotFcn',{@psplotbestf,@psplotfuncount}}];
         end
         %options = optimoptions('patternsearch','FunctionTolerance',1e-3,'StepTolerance',1e-3, optim_papildomi_param{:});
         options = optimoptions('patternsearch', ...
             'PollMethod','GSSPositiveBasis2N', 'PollOrderAlgorithm','Random',...
             'UseCompletePoll',true, 'UseVectorized', false, ...
             'InitialMeshSize',1,...
             ... % 'PlotFcn',{@psplotbestf,@psplotfuncount}, ,@psplotmeshsize
             'SearchFcn',{@searchlhs}, papildomi_param{:});
         
         % Pagrindinis darbas - pats optimaliausių parametrų ieškojimas
         [optimalus_param,paklaidos_ivertis,exitflag,output] = patternsearch(fja, x0, [],[],[],[], lb,ub, [], options);
         fprintf('Iteracijų: %d\nPrasukimų: %d\n', output.iterations, output.funccount);
         prasukimuN=output.funccount;
         
     case {'surrogateopt'}
         
         if didesnis_tikslumas
             % serveriniam kompiuteriui galima užduoti rimčiau
             papildomi_param={'ConstraintTolerance',0.005,'MinSampleDistance',0.002};
         else
             papildomi_param={'ConstraintTolerance',0.01, 'MinSampleDistance',0.005};
         end
         if rodyti_grafikus
             papildomi_param=[{'PlotFcn','surrogateoptplot'} papildomi_param];
         else
             papildomi_param=[{'PlotFcn',''} papildomi_param]; % rodo to neprasant
         end
         options = optimoptions('surrogateopt',...
             'MinSurrogatePoints', max(20,5*length(x0)), ...
             'ObjectiveLimit', 0.001, ...
             'InitialPoints',x0, papildomi_param{:});
         
         % Pagrindinis darbas - pats optimaliausių parametrų ieškojimas
         % [optimalus_param,paklaidos_ivertis,exitflag,output] = patternsearch
         [optimalus_param,paklaidos_ivertis,exitflag,output] = surrogateopt(fja, lb,ub, options);
         fprintf('Prasukimų: %d\n', output.funccount);
         prasukimuN=output.funccount;
         
     case {'ga' 'particleswarm'}
         
         if didesnis_tikslumas
             % serveriniam kompiuteriui galima užduoti rimčiau
             papildomi_param=[ papildomi_param {'FunctionTolerance',0.001}];
         else
             papildomi_param=[ papildomi_param {'FunctionTolerance',0.01}];
         end
         
         hybridoptions = optimoptions('patternsearch', ...
             'PollMethod','GSSPositiveBasis2N', 'PollOrderAlgorithm','Random',...
             'UseCompletePoll',true, 'UseVectorized', false, ...
             'MaxIterations',10, 'MaxFunctionEvaluations',100, 'InitialMeshSize',0.001, 'MaxMeshSize',0.01, ...
             'SearchFcn',{@searchlhs}...
             , papildomi_param{:} ...% Atsargiai: ne visi param yra bendri tarp patternsearch, 'ga' 'particleswarm'. Tikimasi tik 'FunctionTolerance' ir 'UseParallel'
             ); 
         %if lygiagretus
         %    hybridoptions.UseParallel=true;
         %end
         if rodyti_grafikus
            hybridoptions.PlotFcn={@psplotbestf,@psplotfuncount};
         end
         if didesnis_tikslumas
             % serveriniam kompiuteriui galima užduoti rimčiau
             hybridoptions.StepTolerance=0.002;
         else
             hybridoptions.StepTolerance=0.005;
         end
         
         switch paieskos_algoritmas
             case {'particleswarm'}
                 if rodyti_grafikus
                     papildomi_param=[papildomi_param {'PlotFcn',{@pswplotbestf}}]; % particleswarm
                 end
                 options = optimoptions('particleswarm', ...
                     ... 'Display','off', ...
                     'UseVectorized', false, ...
                     ... % 'HybridFcn', {@patternsearch, hybridoptions}, ...
                     'InitialSwarmMatrix',x0,...
                     papildomi_param{:});
                 [optimalus_param,paklaidos_ivertis,exitflag,output] = particleswarm(fja,length(x0),lb,ub,options);
                 fprintf('Iteracijų: %d\nPrasukimų: %d\n', output.iterations, output.funccount);

             case {'ga'}
                 if rodyti_grafikus
                     papildomi_param=[papildomi_param {'PlotFcn',{@gaplotbestf @gaplotscores @gaplotselection}}]; % ga
                 end
                 options = optimoptions('ga', ...
                     ... 'Display','off', ...
                     'UseVectorized', false, ...
                     ... % 'HybridFcn', {@patternsearch, hybridoptions}, ...
                     'InitialPopulationMatrix',x0,...
                     papildomi_param{:});
                 [optimalus_param,paklaidos_ivertis,exitflag,output] = ga(fja,length(x0),[],[],[],[],lb,ub,[],options);
                 fprintf('Generacijų: %d\nPrasukimų: %d\n', output.generations, output.funccount);
         end
         prasukimuN=output.funccount;
         
     case {'GlobalSearch' 'MultiStart'}
         if didesnis_tikslumas
             % serveriniam kompiuteriui galima užduoti rimčiau
             papildomi_param=[ papildomi_param {'FunctionTolerance',0.005,'XTolerance',0.002}];
         else
             papildomi_param=[ papildomi_param {'FunctionTolerance',0.01, 'XTolerance'}];
         end
         
         options = optimoptions(@fmincon,'Algorithm','interior-point','UseParallel',lygiagretus);
         problem = createOptimProblem('fmincon', 'x0',x0, ...
             'objective',fja, 'lb',lb, 'ub',ub,...
             'options',options);
         %[optimalus_param,paklaidos_ivertis,exitflag,output]=fmincon(problem); % pasitikrinimui, ar apskritai suformuota
         switch paieskos_algoritmas
             case {'MultiStart'}
                 % # FIXME: dabar pradeda nuo to paties taško x0 keli procesai, kartojasi bandomi rinkiniai ir vėliau
                 warning off globaloptim:MultiStart:run:NoOutputPlotFcnsInParallel
                 startpts={CustomStartPointSet(x0),RandomStartPointSet('NumStartPoints',50)};
                 ms = MultiStart(... 'Display','off', ...
                     papildomi_param{:});
                 [optimalus_param,paklaidos_ivertis,exitflag,output] = run(ms,problem,startpts);
             case {'GlobalSearch'}
                 if rodyti_grafikus
                     papildomi_param=[papildomi_param {'PlotFcn',{@gsplotbestf @gsplotfunccount}}];
                 end
                 %{
                              if lygiagretus % to neturėtų būti, tik dėl visa ko
                                  papildomi_param_UseParallel_id=find(arrayfun(@(x) isequal(x,{'UseParallel'}),papildomi_param));
                                  papildomi_param=papildomi_param(setdiff(1:length(papildomi_param),[papildomi_param_UseParallel_id papildomi_param_UseParallel_id+1]));
                              end
                 %}
                 gs=GlobalSearch(...'Display','off', ...
                     papildomi_param{:});
                 [optimalus_param,paklaidos_ivertis,exitflag,output] = run(gs,problem);
         end
         fprintf('Prasukimų: %d\n', output.funcCount);
         prasukimuN=output.funcCount;
         
     otherwise
         warning('Netikėtas parametrų paieškos algoritmas „%s“', paieskos_algoritmas);
         optimalus_param=x0;
         exitflag = NaN;
 end
 
 if exitflag == -2 % No feasible point found.
     paklaidos_ivertis=Inf;
 end
 
 
 % Užbaigimas
 if lygiagretus
     try
         spmd
             cd(katal);
             rmdir(tempDir, 's'); % Remove temporary directories
             close_system(gcs,0); % close_system(model, 0);
         end
     catch err
         Pranesk_apie_klaida(err,[],[],0);
     end
     %Simulink.sdi.cleanupWorkerResources;
     % delete(poolobj); % stop parpool
     %SimulinkSDIclearDMR;
 end
 
 % atstatyti Simulink Archive parinktis
 Simulink.sdi.setAutoArchiveMode(AutoArchiveMode);
 Simulink.sdi.setArchiveRunLimit(ArchiveRunLimit);

function SimulinkAutoArchiveSwitch(TryUseParallel)
% Negeneruoti didelių DMR temp aplanke (gali būti keli ar net dešimtys GB)
% % https://www.mathworks.com/matlabcentral/answers/380156-preventing-matlab-simulink-to-generate-a-huge-temporary-file
% C:\Users\XXX\AppData\Local\Temp e.g. C:\Users\Admin\AppData\Local\Temp
if TryUseParallel
    Simulink.sdi.setAutoArchiveMode(false);
    Simulink.sdi.setArchiveRunLimit(0);
else
    Simulink.sdi.setAutoArchiveMode(true);
    Simulink.sdi.setArchiveRunLimit(10);
end

function SimulinkSDIclearDMR
% išvalyti esamą Simulink podėlį - DMR rinkmenas
wv=warning('verbose','on');
% wb=warning('backtrace','off');
% Švelnus būdas - teoriškai turėtų veikti, bet praktiškai ne visada...
try Simulink.sdi.clear; catch; end
try sdi.Repository.clearRepositoryFile; catch; end
% Mechaniškai - grubus būdas
wd=warning('off','MATLAB:DELETE:Permission');
for f=filter_filenames(fullfile(tempdir,'*.dmr')) 
    try delete(f{1}); catch; end
end
warning(wd);
warning(wv);
%warning(wb);
