% Pulls informations from MASCOT search output xml file into a struct
%
% Input:
%   filename:    String containing filename of MASCOT search results (.xml)
%
% Output:
%   mods: Struct with names of fixed modifications
%   it_mods: Struct with names of variable modifications
%   out: Struct with fields:    query
%                               protein
%                               pep_seq
%                               scan_number
%                               scan_data

% Version support: Mascot 2.1.03
%                         2.3.02
%                         2.4.1

function [fixed_mods, var_mods, out] = read_mascot_xml2(filename)

fid = fopen(filename);

fixed_mods = {};
var_mods = {};
out = {};
index = 1;

protein = '';

version = '';

while isempty(version)
    line = fgetl(fid);
    if ~isempty(strfind(line,'<MascotVer>'))
        version = line;
        version = regexprep(version,'<MascotVer>','');
        version = regexprep(version,'</MascotVer>','');
    end
end

%%
if strcmp(version, '2.1.03')
    % Get query number, protein, and sequence
    while ~feof(fid) && ~strcmp(line, '</hits>')
        line = fgetl(fid);
        
        if ~isempty(strfind(line,'<MODS>'))
            % Collect list of fixed modifications used in search
            line = regexprep(line,'<MODS>','');
            line = regexprep(line,'</MODS>','');
            
            [str,rem] = strtok(line,',');
            if ~isempty(str)
                fixed_mods{1} = str;
            end
            while ~isempty(rem)
                [str,rem] = strtok(rem,',');
                fixed_mods{end+1} = str;
            end
        elseif ~isempty(strfind(line,'<IT_MODS>'))
            % Collect list of variable modifications used in search
            line = regexprep(line,'<IT_MODS>','');
            line = regexprep(line,'</IT_MODS>','');
            
            [str,rem] = strtok(line,',');
            if ~isempty(str)
                var_mods{1} = str;
            end
            while ~isempty(rem)
                [str,rem] = strtok(rem,',');
                var_mods{end+1} = str;
            end
            
        elseif ~isempty(strfind(line,'<protein accession'))
            line = regexprep(line,'<protein accession="','');
            gi = regexprep(line,'">','');
        elseif ~isempty(strfind(line,'<prot_desc>'))
            line = regexprep(line,'<prot_desc>','');
            protein = regexprep(line,'</prot_desc>','');
        elseif ~isempty(strfind(line,'<peptide query='))
            line = regexprep(line,'<peptide query="','');
            out{index}.gi = gi;
            out{index}.protein = protein;
            out{index}.query = str2num(regexprep(line,'">',''));
        elseif ~isempty(strfind(line,'<pep_exp_mz>'))
            line = regexprep(line,'<pep_exp_mz>','');
            out{index}.pep_exp_mz = str2num(regexprep(line,'</pep_exp_mz>',''));
        elseif ~isempty(strfind(line,'<pep_exp_z>'))
            line = regexprep(line,'<pep_exp_z>','');
            out{index}.pep_exp_z = str2num(regexprep(line,'</pep_exp_z>',''));
        elseif ~isempty(strfind(line,'<pep_score>'))
            line = regexprep(line,'<pep_score>','');
            out{index}.pep_score = str2num(regexprep(line,'</pep_score>',''));
        elseif ~isempty(strfind(line,'<pep_rank>'))
            line = regexprep(line,'<pep_rank>','');
            out{index}.pep_rank = str2num(regexprep(line,'</pep_rank>',''));
        elseif ~isempty(strfind(line,'<pep_seq>'))
            line = regexprep(line,'<pep_seq>','');
            out{index}.pep_seq = regexprep(line,'</pep_seq>','');
        elseif ~isempty(strfind(line,'<pep_var_mod>'))
            line = regexprep(line,'<pep_var_mod>','');
            line = regexprep(line,'</pep_var_mod>','');
            
            pep_var_mods = {};
            [str,rem] = strtok(line,';');
            if ~isempty(str)
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{1,1} = 1;
                    pep_var_mods{1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{1,1} = str2num(d{1});
                        pep_var_mods{1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{1,1} = 1;
                        pep_var_mods{1,2} = str;
                    end
                end
            else
                pep_var_mods = {};
            end
            while ~isempty(rem)
                [str,rem] = strtok(rem,';');
                str = str(2:end);
                [a,~] = size(pep_var_mods);
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{a+1,1} = 1;
                    pep_var_mods{a+1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{a+1,1} = str2num(d{1});
                        pep_var_mods{a+1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{a+1,1} = 1;
                        pep_var_mods{a+1,2} = str;
                    end
                end
            end
            out{index}.pep_var_mods = pep_var_mods;
            index = index+1;
        elseif ~isempty(strfind(line,'<pep_var_mod/>'))
            out{index}.pep_var_mods = {};
            index = index+1;
        end
    end
    
    scan_map = {};
    index = 1;
    
    while ~feof(fid)
        line = fgetl(fid);
        if ~isempty(strfind(line,'<query number='))
            [~,~,~,query_number] = regexp(line,'[0-9]*');
            scan_map{index}.query = str2num(query_number{1});
        elseif ~isempty(strfind(line,'<query ='))
            [~,~,~,query_number] = regexp(line,'[0-9]*');
            scan_map{index}.query = str2num(query_number{1});
        elseif ~isempty(strfind(line,'<StringTitle>'))
            
            if ~isempty(strfind(line, 'FinneganScanNumber'))
                % MGF produced with DTA Supercharge
                line = regexprep(line,'<StringTitle>','');
                line = regexprep(line,'</StringTitle>','');
                
                found = false;
                [str,rem] = strtok(line,':');
                while ~found && ~isempty(rem)
                    if ~isempty(strfind(str,'MStype'))
                        [~,~,~,d] = regexp(str,'[0-9]*');
                        scan_map{index} = num2str(d{1});
                        found = true;
                    end
                    [str,rem] = strtok(rem,':');
                end
            elseif ~isempty(strfind(line,'scan='))
                line = regexprep(line, '.+scan=', '');
                line = regexprep(line,'"</StringTitle>','');
                scan_map{index} = num2str(line);
            end
            
            index = index + 1;
        end
    end
    
    for i = 1:length(out)
        query_number = out{i}.query;
        out{i}.scan_number = str2num(scan_map{query_number});
        %     out{i}.scan_data = scan_map{query_number}.input;
    end
elseif strcmp(version, '2.4.1')
    %%
    query_used = [];
    scan_used = [];
    spectrum_id_mapping = [];
    index = 1;
    use_mapping = 0;
    hits_section = 0;
    
    while ~feof(fid) && ~(~use_mapping && strcmp(line, '</hits>'))
        line = fgetl(fid);
        
        if strcmp(line, '<hits>')
            hits_section = 1;
        elseif strcmp(line, '</hits>')
            hits_section = 0;
        elseif strcmp(line, '<fixed_mods>')
            % Collect list of fixed modifications used in search
            while ~strcmp(line, '</fixed_mods>')
                if ~isempty(strfind(line, '<name>'))
                    line = regexprep(line, '<name>', '');
                    line = regexprep(line, '</name>', '');
                    fixed_mods{end+1} = line;
                end
                line = fgetl(fid);
            end
        elseif strcmp(line, '<variable_mods>')
            % Collect list of variable modifications used in search
            while ~strcmp(line, '</variable_mods>')
                if ~isempty(strfind(line, '<name>'))
                    line = regexprep(line, '<name>', '');
                    line = regexprep(line, '</name>', '');
                    var_mods{end+1} = line;
                end
                line = fgetl(fid);
            end
        elseif ~isempty(strfind(line,'<protein accession'))
            line = regexprep(line,'<protein accession="','');
            gi = regexprep(line,'" member.+','');
        elseif ~isempty(strfind(line,'<prot_desc>'))
            line = regexprep(line,'<prot_desc>','');
            line = regexprep(line,'</prot_desc>','');
            protein = regexprep(line,' OS=.+','');
        elseif ~isempty(strfind(line,'<peptide query=')) && hits_section
            %             line = regexprep(line,'<peptide query="','');
            out{index}.gi = gi;
            out{index}.protein = protein;
            
            line1 = regexprep(line, '<peptide query="', '');
            line1 = regexprep(line1, '" rank=.*', '');
            out{index}.query = str2num(line1);
            
            query_used(index) = str2num(line1);
            
            line2 = regexprep(line, '.*rank="','');
            line2 = regexprep(line2, '" isbold.*', '');
            out{index}.pep_rank = str2num(line2);
            
            % Some runs missing scores -> default to 0
            out{index}.pep_score = 0;
            
        elseif ~isempty(strfind(line,'<pep_exp_mz>')) && hits_section
            line = regexprep(line,'<pep_exp_mz>','');
            out{index}.pep_exp_mz = str2num(regexprep(line,'</pep_exp_mz>',''));
        elseif ~isempty(strfind(line,'<pep_exp_z>')) && hits_section
            line = regexprep(line,'<pep_exp_z>','');
            out{index}.pep_exp_z = str2num(regexprep(line,'</pep_exp_z>',''));
        elseif ~isempty(strfind(line,'<pep_score>')) && hits_section
            line = regexprep(line,'<pep_score>','');
            out{index}.pep_score = str2num(regexprep(line,'</pep_score>',''));
            %         elseif ~isempty(strfind(line,'<pep_rank>'))
            %             line = regexprep(line,'<pep_rank>','');
            %             out{index}.pep_rank = str2num(regexprep(line,'</pep_rank>',''));
        elseif ~isempty(strfind(line,'<pep_seq>')) && hits_section
            line = regexprep(line,'<pep_seq>','');
            out{index}.pep_seq = regexprep(line,'</pep_seq>','');
        elseif ~isempty(strfind(line,'<pep_var_mod>')) && hits_section
            line = regexprep(line,'<pep_var_mod>','');
            line = regexprep(line,'<pep_var_mod />','');
            line = regexprep(line,'</pep_var_mod>','');
            
            pep_var_mods = {};
            [str,rem] = strtok(line,';');
            if ~isempty(str)
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{1,1} = 1;
                    pep_var_mods{1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{1,1} = str2num(d{1});
                        pep_var_mods{1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{1,1} = 1;
                        pep_var_mods{1,2} = str;
                    end
                end
            else
                pep_var_mods = {};
            end
            while ~isempty(rem)
                [str,rem] = strtok(rem,';');
                str = str(2:end);
                [a,~] = size(pep_var_mods);
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{a+1,1} = 1;
                    pep_var_mods{a+1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{a+1,1} = str2num(d{1});
                        pep_var_mods{a+1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{a+1,1} = 1;
                        pep_var_mods{a+1,2} = str;
                    end
                end
            end
            out{index}.pep_var_mods = pep_var_mods;
        elseif ~isempty(strfind(line,'<pep_var_mod/>'))
            out{index}.pep_var_mods = {};
        elseif ~isempty(strfind(line,'<pep_scan_title>'))
            [~,~,~,d] = regexp(line,'scans:[0-9]+');
            
            % to support .baf-generated xml files
            if ~isempty(d)
                scan = str2num(d{1}(7:end));
            else
                [~,~,~,d] = regexp(line,'Cmpd_[0-9]+');
                if ~isempty(d)
                    scan = str2num(d{1}(6:end));
                else
                    [~,~,~,d] = regexp(line,'SpectrumID: &quot;[0-9]+&quot;');
                    scan = str2num(d{1}(19:end-6));
                    use_mapping = 1;
                end
            end
        elseif ~isempty(strfind(line,'StringTitle'))
            % to support ProteomeDiscover 2.1
            [~,~,~,d] = regexp(line,'SpectrumID: &quot;[0-9]+&quot;');
            spectrum_id = str2num(d{1}(19:end-6));
        elseif ~isempty(strfind(line, '<SCANS>'))
            % to support ProteomeDiscover 2.1
            [~,~,~,d] = regexp(line, '[0-9]+');
            
            real_scan = str2num(d{1});
            spectrum_id_mapping = [spectrum_id_mapping; spectrum_id, real_scan];
            
            spectrum_id = NaN;
            real_scan = NaN;
        elseif ~isempty(strfind(line, '</peptide>'))
            out{index}.scan_number = scan;
            rank = out{index}.pep_rank;
            
            % Searches if scan was previously seen.  If so, searches if
            % peptide rank is better than previously seen scan.  If so,
            % deletes previous scan entry
            if isempty(scan_used)
                scan_used = [scan,index,rank];
            elseif isempty(find(scan_used(scan_used(:,1)==scan),1))
                scan_used = [scan_used;scan,index,rank];
            else
                index_match = scan_used(scan_used(:,1)==scan,2);
                rank_match = scan_used(scan_used(:,1)==scan,3);
                if rank < rank_match
                    out(index_match) = [];
                    scan_used(scan_used(:,2)==index_match,:) = [];
                    scan_used(scan_used(:,2)>index_match,2) = scan_used(scan_used(:,2)>index_match,2)-1; % re-numbers indices above the deleted entry
                    index = index - 1;
                end
            end
            
            index = index+1;
        end
    end
    
    % Fix scan IDs if using Spectrum IDs
    indices = [];
    for i=1:length(spectrum_id_mapping)
        for j=1:length(out)
            if out{j}.scan_number == spectrum_id_mapping(i, 1)
                indices = [indices; j, spectrum_id_mapping(i, 2)];
            end
        end
    end
    for i=1:length(indices)
        out{indices(i, 1)}.scan_number = indices(i, 2);
    end
elseif strcmp(version, '2.3.02')
    %%
    while ~feof(fid) && ~strcmp(line, '</hits>')
        line = fgetl(fid);
        
        if strcmp(line, '<fixed_mods>')
            % Collect list of fixed modifications used in search
            while ~strcmp(line, '</fixed_mods>')
                if ~isempty(strfind(line, '<name>'))
                    line = regexprep(line, '<name>', '');
                    line = regexprep(line, '</name>', '');
                    fixed_mods{end+1} = line;
                end
                line = fgetl(fid);
            end
        elseif strcmp(line, '<variable_mods>')
            % Collect list of variable modifications used in search
            while ~strcmp(line, '</variable_mods>')
                if ~isempty(strfind(line, '<name>'))
                    line = regexprep(line, '<name>', '');
                    line = regexprep(line, '</name>', '');
                    var_mods{end+1} = line;
                end
                line = fgetl(fid);
            end
        elseif ~isempty(strfind(line,'<protein accession'))
            line = regexprep(line,'<protein accession="','');
            gi = regexprep(line,'">','');
        elseif ~isempty(strfind(line,'<prot_desc>'))
            line = regexprep(line,'<prot_desc>','');
            protein = regexprep(line,'</prot_desc>','');
        elseif ~isempty(strfind(line,'<peptide query='))
            %             line = regexprep(line,'<peptide query="','');
            out{index}.gi = gi;
            out{index}.protein = protein;
            
            
            line1 = regexprep(line, '<peptide query="', '');
            line1 = regexprep(line1, '" rank=.*', '');
            out{index}.query = str2num(line1);
            
            query_used(index) = str2num(line1);
            
            line2 = regexprep(line, '.*rank="','');
            line2 = regexprep(line2, '" isbold.*', '');
            out{index}.pep_rank = str2num(line2);
            
        elseif ~isempty(strfind(line,'<pep_exp_mz>'))
            line = regexprep(line,'<pep_exp_mz>','');
            out{index}.pep_exp_mz = str2num(regexprep(line,'</pep_exp_mz>',''));
        elseif ~isempty(strfind(line,'<pep_exp_z>'))
            line = regexprep(line,'<pep_exp_z>','');
            out{index}.pep_exp_z = str2num(regexprep(line,'</pep_exp_z>',''));
        elseif ~isempty(strfind(line,'<pep_score>'))
            line = regexprep(line,'<pep_score>','');
            out{index}.pep_score = str2num(regexprep(line,'</pep_score>',''));
        elseif ~isempty(strfind(line,'<pep_seq>'))
            line = regexprep(line,'<pep_seq>','');
            out{index}.pep_seq = regexprep(line,'</pep_seq>','');
            
        elseif ~isempty(strfind(line,'<pep_var_mod>'))
            line = regexprep(line,'<pep_var_mod>','');
            line = regexprep(line,'</pep_var_mod>','');
            
            pep_var_mods = {};
            [str,rem] = strtok(line,';');
            if ~isempty(str)
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{1,1} = 1;
                    pep_var_mods{1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{1,1} = str2num(d{1});
                        pep_var_mods{1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{1,1} = 1;
                        pep_var_mods{1,2} = str;
                    end
                end
            else
                pep_var_mods = {};
            end
            while ~isempty(rem)
                [str,rem] = strtok(rem,';');
                str = str(2:end);
                [a,~] = size(pep_var_mods);
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{a+1,1} = 1;
                    pep_var_mods{a+1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{a+1,1} = str2num(d{1});
                        pep_var_mods{a+1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{a+1,1} = 1;
                        pep_var_mods{a+1,2} = str;
                    end
                end
            end
            out{index}.pep_var_mods = pep_var_mods;
            %             index = index+1;
        elseif ~isempty(strfind(line,'<pep_var_mod/>'))
            out{index}.pep_var_mods = {};
            %             index = index+1;
        elseif ~isempty(strfind(line,'<pep_scan_title'))
            [~,~,~,d] = regexp(line,'FinneganScanNumber: [0-9]+');
            out{index}.scan_number = str2num(d{1}(21:end));
            index = index + 1;
        end
        
    end
elseif strcmp(version, '2.4.0')
    %%
    query_used = [];
    index = 1;
    while ~feof(fid) && ~strcmp(line, '</hits>')
        line = fgetl(fid);
        
        if strcmp(line, '<fixed_mods>')
            % Collect list of fixed modifications used in search
            while ~strcmp(line, '</fixed_mods>')
                if ~isempty(strfind(line, '<name>'))
                    line = regexprep(line, '<name>', '');
                    line = regexprep(line, '</name>', '');
                    fixed_mods{end+1} = line;
                end
                line = fgetl(fid);
            end
        elseif strcmp(line, '<variable_mods>')
            % Collect list of variable modifications used in search
            while ~strcmp(line, '</variable_mods>')
                if ~isempty(strfind(line, '<name>'))
                    line = regexprep(line, '<name>', '');
                    line = regexprep(line, '</name>', '');
                    var_mods{end+1} = line;
                end
                line = fgetl(fid);
            end
        elseif ~isempty(strfind(line,'<protein accession'))
            line = regexprep(line,'<protein accession="','');
            gi = regexprep(line,'" member.+','');
        elseif ~isempty(strfind(line,'<prot_desc>'))
            line = regexprep(line,'<prot_desc>','');
            line = regexprep(line,'</prot_desc>','');
            protein = regexprep(line,' OS=.+','');
        elseif ~isempty(strfind(line,'<peptide query='))
            %             line = regexprep(line,'<peptide query="','');
            out{index}.gi = gi;
            out{index}.protein = protein;
            
            line1 = regexprep(line, '<peptide query="', '');
            line1 = regexprep(line1, '" rank=.*', '');
            out{index}.query = str2num(line1);
            
            query_used(index) = str2num(line1);
            
            line2 = regexprep(line, '.*rank="','');
            line2 = regexprep(line2, '" isbold.*', '');
            out{index}.pep_rank = str2num(line2);
            
            % Some runs missing scores -> default to 0
            out{index}.pep_score = 0;
            
        elseif ~isempty(strfind(line,'<pep_exp_mz>'))
            line = regexprep(line,'<pep_exp_mz>','');
            out{index}.pep_exp_mz = str2num(regexprep(line,'</pep_exp_mz>',''));
        elseif ~isempty(strfind(line,'<pep_exp_z>'))
            line = regexprep(line,'<pep_exp_z>','');
            out{index}.pep_exp_z = str2num(regexprep(line,'</pep_exp_z>',''));
        elseif ~isempty(strfind(line,'<pep_score>'))
            line = regexprep(line,'<pep_score>','');
            out{index}.pep_score = str2num(regexprep(line,'</pep_score>',''));
            %         elseif ~isempty(strfind(line,'<pep_rank>'))
            %             line = regexprep(line,'<pep_rank>','');
            %             out{index}.pep_rank = str2num(regexprep(line,'</pep_rank>',''));
        elseif ~isempty(strfind(line,'<pep_seq>'))
            line = regexprep(line,'<pep_seq>','');
            out{index}.pep_seq = regexprep(line,'</pep_seq>','');
        elseif ~isempty(strfind(line,'<pep_var_mod>'))
            line = regexprep(line,'<pep_var_mod>','');
            line = regexprep(line,'<pep_var_mod />','');
            line = regexprep(line,'</pep_var_mod>','');
            
            pep_var_mods = {};
            [str,rem] = strtok(line,';');
            if ~isempty(str)
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{1,1} = 1;
                    pep_var_mods{1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{1,1} = str2num(d{1});
                        pep_var_mods{1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{1,1} = 1;
                        pep_var_mods{1,2} = str;
                    end
                end
            else
                pep_var_mods = {};
            end
            while ~isempty(rem)
                [str,rem] = strtok(rem,';');
                str = str(2:end);
                [a,~] = size(pep_var_mods);
                if ~isempty(regexp(str,'plex'))
                    pep_var_mods{a+1,1} = 1;
                    pep_var_mods{a+1,2} = str;
                else
                    [~,e,~,d] = regexp(str,'^[0-9]+');
                    if ~isempty(d)
                        pep_var_mods{a+1,1} = str2num(d{1});
                        pep_var_mods{a+1,2} = str(e(1)+2:end);
                    else
                        pep_var_mods{a+1,1} = 1;
                        pep_var_mods{a+1,2} = str;
                    end
                end
            end
            out{index}.pep_var_mods = pep_var_mods;
        elseif ~isempty(strfind(line,'<pep_var_mod/>'))
            out{index}.pep_var_mods = {};
        elseif ~isempty(strfind(line,'<pep_scan_title>'))
            [~,~,~,d] = regexp(line,'Scan [0-9]+');
            if ~isempty(d)
                out{index}.scan_number = str2num(d{1}(6:end));
                index = index+1;
            else
                out{index}.scan_number = 0;
            end
            
        end
    end
    
else
    warndlg('Unsupported Version of Mascot.');
    error('read_mascot_xml:Mascot', 'Unsupported Version of Mascot.');
end
fclose(fid);
