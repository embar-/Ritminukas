% eeg_ikelk - duomenų įkėlimas EEGLAB struktūros pavidalu kone iš bet
% kokios vienos EEG rinkmenos [EEG]=eeg_ikelk(kelias,rinkmena)


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

function [EEG]=eeg_ikelk(Kelias, Rinkmena, varargin)

persistent PAPILDINIAI_JAU_PATIKRINTI
try
    g=struct(varargin{:});
catch
    g=struct;
end;
tikrinti_papildinius=1;
if isfield(g,'tikrinti_papildinius');
    tikrinti_papildinius=g.tikrinti_papildinius;
end;
loadmode='all';
if isfield(g,'loadmode');
    loadmode=g.loadmode;
end;

    [Kelias_,Rinkmena_]=rinkmenos_tikslinimas(Kelias,Rinkmena);
    if ~exist(fullfile(Kelias_,Rinkmena_),'file')
        [wrn_b]=warning('off','backtrace');
        warning(sprintf('%s\n%s\n%s', [lokaliz('Rinkmena nerasta') ':'], ...
           fullfile(Kelias,Rinkmena), fullfile(Kelias_,Rinkmena_)));
        EEG=[]; % Belieka tuščią grąžinti...
        warning(wrn_b);
        return;
    end;
    
    try % Importuoti kaip EEGLAB *.set
        EEG = pop_loadset('filename',Rinkmena_,'filepath',Kelias_,'loadmode',loadmode);
    catch 
        Kelias_ir_rinkmena=fullfile(Kelias_, Rinkmena_);
        % Pranesk_apie_klaida(lasterr, mfilename, Kelias_ir_rinkmena, 0);
        fprintf('\n%s\n%s...\n', Kelias_ir_rinkmena, lokaliz('ne EEGLAB rinkmena'));
        
        
        fprintf('%s %s...\n', lokaliz('Trying again with'), 'BIOSIG');
        diary_bsn0=get(0,'Diary');
        try % Importuoti per BIOSIG
            if strcmp(diary_bsn0,'on'); diary_zrn0=get(0,'DiaryFile'); diary('off'); end;
            diary_zrn2=tempname; diary(diary_zrn2); diary('on');
            EEG=pop_biosig(Kelias_ir_rinkmena);
            diary('off');
            if strcmp(diary_bsn0,'on'); diary(diary_zrn0); diary(diary_bsn0); end;
            if isempty(EEG.data); 
                error(lokaliz('Empty dataset'));
            end;
            EEG=eegh( ['pop_biosig(' Kelias_ir_rinkmena ')' ], EEG);
        catch %klaida; Pranesk_apie_klaida(klaida, mfilename, Kelias_ir_rinkmena, 0);
            
            % BIOPAC AcqKnowledge *.ACQ
            diary('off');
            fprintf('%s...\n', lokaliz('BIOSIG negali nuskaityti'));
            diary_fid=fopen(diary_zrn2);
            diary_prn=fgets(diary_fid);
            if ~ischar(diary_prn); diary_prn=''; end;
            fclose(diary_fid);
            delete(diary_zrn2);
            if exist('diary_zrn0','var') && (exist(diary_zrn0,'file') == 2) && (~strcmp(diary_zrn0,'diary')); 
                diary(diary_zrn0);
            end;
            diary(diary_bsn0);
                        
            [wrn_b]=warning('off','backtrace');
            try % Importuoti per FILEIO
                fprintf('%s %s...\n', lokaliz('Trying again with'), 'FILEIO');
                EEG=pop_fileio(Kelias_ir_rinkmena);
                EEG=eegh( ['pop_fileio(' Kelias_ir_rinkmena ')' ], EEG);
                % Sutvarkyti įvykių pavadinimus
                try tipai=regexprep({EEG.event.type},'[\0]*$','');
                    [EEG.event.type]=tipai{:};
                catch
                end;
            catch %; Pranesk_apie_klaida(lasterr, mfilename, Kelias_ir_rinkmena, 0);
                fprintf('%s...\n', lokaliz('FILEIO negali nuskaityti'));
                try % Įkelti tiesiogiai į MATLAB
                    fprintf('%s %s...\n', lokaliz('Trying again with'), 'MATLAB');
                    load(Kelias_ir_rinkmena,'-mat');
                    EEG = eeg_checkset(EEG);
                catch %; Pranesk_apie_klaida(lasterr, mfilename, Kelias_ir_rinkmena, 0);
                    fprintf('%s...\n', lokaliz('MATLAB negali nuskaityti'));
                    % Nurodyti galimai trūkstamus papildinius
                    if tikrinti_papildinius
                        if isempty(PAPILDINIAI_JAU_PATIKRINTI)
                            PAPILDINIAI_JAU_PATIKRINTI=1;
                            trukstami_papildniai=[drb_uzklausa('papildiniai')];
                            if ~isempty(trukstami_papildniai)
                                wrnmsg=[lokaliz('Ikelti nepavyko') trukstami_papildniai];
                                warning(sprintf('%s\n',wrnmsg{:}));
                                warndlg(wrnmsg,lokaliz('Duomenu ikelimas'));
                            end;
                        end;
                    end;
                    warning(lokaliz('Ikelti nepavyko'));
                    EEG=[]; % Belieka tuščią grąžinti...
                end;
            end;
            warning(wrn_b);
        end;
    end;
    
    try
        ivykiai={EEG.event.type};
        if ~iscellstr(ivykiai);
            for i=1:length(ivykiai);
                try
                    EEG.event(i).type=num2str(EEG.event(i).type);
                catch
                end
            end;
        end;
    catch
    end
    
function txt=lokaliz(txt)
% FIXME
