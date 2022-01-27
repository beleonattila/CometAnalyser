function showDataExtracted(Table, WindowsName)
% AUTHOR: Filippo Piccinini (E-mail: f.piccinini@unibo.it)
% DATE: July 07, 2014
% NAME: ShowDataExtracted (version 1.0)
% 
% To show as table the data extimated.
%
% PARAMETERS:
% 	Table               Table tha must be shown.
%   WindowsName         Name to be visualized in the output figure
 
% Copyright © 2022 Filippo Piccinini and Attila Beleon.
% Contacts: filippo.piccinini85@gmail.com and beleonattila@gmail.com
% All rights reserved.
% 
% CometAnalyser and all related material is licensed
% under the: 3-clause BSD License.
%
% This software and all related material is provided by the copyright
% holders and contributors "as is" and any express or implied warranties,
% including, but not limited to, the implied warranties of merchantability
% and fitness for a particular purpose are disclaimed. In no event shall
% <copyright holder> be liable for any direct, indirect, incidental,
% special, exemplary, or consequential damages (including, but not limited
% to, procurement of substitute goods or services; loss of use, data, or
% profits; or business interruption) however caused and on any theory of
% liability, whether in contract, strict liability, or tort (including
% negligence or otherwise) arising in any way out of the use of this
% software, even if advised of the possibility of such damage.

cnames = fieldnames(Table);
Lengthcnames = length(cnames);
Mdati = [];
for i = 1:Lengthcnames
    Mdati = [Mdati; Table.(cnames{i})];
end
Mdati = Mdati';

%Mdati = handles.matrici.Mdati;

%__INIZIALIZZAZIONE DEGLI OGGETTI GRAFICI____
if nargin<2
    WindowsName = 'DATA EXTRACTED';
end

%_________FIGURA PRINCIPALE_______________
form1=figure('Position',[400,300,600,400],'Name',WindowsName,...
    'NumberTitle','off','Color',[0.941 0.941 0.941],...
    'Resize','off','WindowStyle','modal');

%_____________STATIC TEXT____________________
testo = uicontrol(form1,'Style','text','Position',[250,370,100,25],...
    'String','DATA EXTRACTED');

%______________TABLE________________
table= uitable('Data',Mdati,'ColumnName',cnames,... 
    'Parent',form1,'Position',[10 50 580 320]);


%_______________PULSANTI_____________________
Esporta_Excel= uicontrol(form1,'Style','pushbutton',...
    'Position',[20,10,100,25],'String','Save as Excel file',...
    'Callback',@esporta_excel_plot);

Esporta_Matlab= uicontrol(form1,'Style','pushbutton',...
    'Position',[130,10,100,25],...
    'String','Save as Matlab file','Callback',@esporta_matlab_plot);

% Esporta_Txt= uicontrol(form1,'Style','pushbutton',...
%     'Position',[110,10,70,25],...
%     'String','Esporta Txt','Callback',@esporta_txt_plot);
% 
% chiudi = uicontrol(form1,'Style','pushbutton','Position',[200,10,70,25],...
%     'String','Chiudi','Callback',@chiudi_plot);


%________FUNZIONE PULSANTE ESPORTA EXCEL________ 
    function esporta_excel_plot(hObject,eventdata)
        [file,path] = uiputfile('dataExtracted.csv','Save file');
        if file==0
            return
        end
        pathfile = [path file];
        
        [ro, co] = size(Mdati);
        for in = 1:co
            TableFinal{1,in} = cnames{in};
        end
        for in = 1:co
            for jn = 1:ro            
                TableFinal{jn+1,in} = Mdati{jn,in};
            end
        end
        xlswrite(pathfile, TableFinal);

        % Save folder snapshots
        [status,message,messageId] = movefile('LabeledFigures',path,'f');
    end


%________FUNZIONE PULSANTE ESPORTA MATLAB________ 
    function esporta_matlab_plot(hObject,eventdata)
        [file,path] = uiputfile('dataExtracted.mat','Save file');
        if file==0
            return
        end
        pathfile = [path file];
        
        [ro, co] = size(Mdati);
        for in = 1:co
            ColumnNames{1,in} = cnames{in};
        end
        
        save(pathfile, 'Mdati', 'ColumnNames');

        % Save folder snapshots
        [status,message,messageId] = movefile('LabeledFigures',path,'f');
    end


% %__________FUNZIONE PULSANTE ESPORTA TXT__________
%     function esporta_txt_plot(hObject,eventdata)
%         [file,path] = uiputfile('dataExtracted.txt','Save file name');
%         if file==0
%             return
%         end
%         pathfile = [path file];
%         dlmwrite(pathfile, Mdati);
%     end


%__________FUNZIONE PULSANTE CHIUDI_____________
    function chiudi_plot(hObject,eventdata)
        close
    end


end