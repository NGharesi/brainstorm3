function [header, ChannelMat] = ctf_read_res4( res4_file )
% CTF_READ_RES4: Read a CTF .ds dataset header.
%
% USAGE:  [header, ChannelMat] = ctf_read_res4( res4_file )
%
% INPUT:
%     - res4_file : Full path to the .res4 file to read
% OUTPUT:
%     - header     : Structure with all the information of the .res4 file
%     - ChannelMat : Brainstorm structure describing the sensors

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2020 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, Sylvain Baillet, 2004-2016
% ----------------------------- Script History ---------------------------------
% SB  11-Mar-2004  Creation
% FT  26-Jun-2008  Partial recoding for Brainstorm3
% FT  12-Dec-2008  Added support for new sensor types (Claude Delpuech)
% FT  20-Fev-2009  Full recoding for Brainstorm3
% FT  03-Nov-2009  Full recoding for new IO subsystem
% FT  02-Apr-2013  Added a test for incorrect number of coefficients
% FT  26-Feb-2016  Fixed the orientation of the references
% ------------------------------------------------------------------------------

%% ===== INTIALIZATIONS ======
% Define constants
MAX_COILS = 8;
MAX_AVERAGE_BINS = 8;
SensorTypes ={...
      'Ref magnetometer',... % 0  Reference magnetometer channel          (#5002 in coil_def.dat)
      'Ref gradiometer' ,... % 1  Reference 1st-order gradiometer channel (#5003 or #5004 in coil_def.dat)
      'MEG REF GRAD2',...    % 2  Reference 2nd-order gradiometer channel
      'MEG REF GRAD3',...    % 3  Reference 3rd-order gradiometer channel
      'MEG MAG' ,...         % 4  Sensor magnetometer channel located in head shell
      'MEG',...              % 5  Sensor 1st-order gradiometer channel located in head shell (#5001 in coil_def.dat)
      'MEG GRAD2' ,...       % 6  Sensor 2nd-order gradiometer channel located in head shell
      'MEG GRAD3',...        % 7  Sensor 3rd-order gradiometer channel located in head shell
      'EEG REF',...          % 8  EEG unipolar sensors not on the scalp
      'EEG',...              % 9  EEG unipolar sensors on the scalp
      'ADC A',...            % 10 ADC Input Current (Amps)
      'Stim',...             % 11 Stimulus channel for MEG41
      'Video',...            % 12 Value recorded from a SONY Video time output ('hhmmssff')
      'HLU',...              % 13 Measured position of head and head coils
      'DAC',...              % 14 DAC channel from ECC or HLU
      'SAM',...              % 15 SAM channel derived through data analysis
      'Virtual',...          % 16 Virtual channel derived by combining two or more physical channels
      'SysClock',...         % 17 System time showing elapsed time since trial started
      'ADC V',...            % 18 ADC volt channels from ECC
      'StimA', ...           % 19 Analog trigger channels
      'StimD', ...           % 20 Digital trigger channels
      'EEG bipolar', ...     % 21 EEG bipolar sensor not on the scalp
      'EEG ADC', ...         % 22 EEG ADC over range flags
      'Reset', ...           % 23 MEG resets (counts sensor jumps for crosstalk purposes)
      'Dipole', ...          % 24 Dipole source
      'NSAM', ...            % 25 Normalized SAM channel derived through data analysis
      'AngleRef', ...        % 26 Orientation of head localization field
      'LOC', ...             % 27 Extracted signal from each sensor of field generated by each localization coil
      'FitErr', ...          % 28 Fit error from each head localization coil
      'Other', ...           % 29 Any other type of sensor not mentioned but still valid
      'Invalid'              % 30 Invalid
      };

             
%% ===== READING .RES4 FILE =====
% Open file (Big-endian byte ordering)
[rec,message] = fopen(res4_file, 'rb', 'b');
if rec < 0
    error(message);
end

% Read HEADER
hdr = fread(rec,8,'char')';

% Read nfSetUp
res4.appName         = char(fread(rec,256,'char')');
res4.dataOrigin      = char(fread(rec,256,'char')');
res4.dataDescription = char(fread(rec,256,'char')');
res4.no_trials_avgd  =      fread(rec,  1,'int16')';
res4.data_time       = char(fread(rec,255,'char')');
res4.data_date       = char(fread(rec,255,'char')');

gSetUp.no_samples  = fread(rec,1,'int32')';
gSetUp.no_channels = fread(rec,1,'int16')';
fseek(rec, ceil(ftell(rec)/8)*8, -1);
gSetUp.sample_rate = fread(rec,1,'double')';
fseek(rec, ceil(ftell(rec)/8)*8, -1);
gSetUp.epoch_time  = fread(rec,1,'double')';
gSetUp.no_trials   = fread(rec,1,'int16')';
fseek(rec, ceil(ftell(rec)/4)*4, -1);
gSetUp.preTrigPts  = fread(rec,1,'int32')';
gSetUp.no_trials_done = fread(rec,1,'int16')';
gSetUp.no_trials_display = fread(rec,1,'int16')';
fseek(rec, ceil(ftell(rec)/4)*4, -1);
gSetUp.save_trials         = fread(rec,1,'int32')';
gSetUp.primaryTrigger      = char(fread(rec,1,'uchar')');
gSetUp.secondaryTrigger    = char(fread(rec,MAX_AVERAGE_BINS,'uchar')');
gSetUp.triggerPolarityMask = char(fread(rec,1,'uchar')');

gSetUp.trigger_mode = fread(rec,1,'int16')';
fseek(rec, ceil(ftell(rec)/4)*4, -1);
gSetUp.accept_reject_Flag = fread(rec,1,'int32')';
gSetUp.run_time_display = (fread(rec,1,'int16')');
fseek(rec, ceil(ftell(rec)/4)*4, -1);
gSetUp.zero_Head_Flag = fread(rec,1,'int32')';
fseek(rec, ceil(ftell(rec)/4)*4, -1);
gSetUp.artifact_mode = fread(rec,1,'int32')';
gSetUp.padding = fread(rec,1,'int32')';

nfSetUp.nf_run_name           = char(fread(rec, 32,'char')');
nfSetUp.nf_run_title          = char(fread(rec,256,'char')');
nfSetUp.nf_instruments        = char(fread(rec, 32,'char')');
nfSetUp.nf_collect_descriptor = char(fread(rec, 32,'char')');
nfSetUp.nf_subject_id         = char(fread(rec, 32,'char')');
nfSetUp.nf_operator           = char(fread(rec, 32,'char')');
% prevent out of range character conversion warning
tmp = fread(rec,60,'char')';
tmp(tmp<0) = 0; 
nfSetUp.nf_sensorFileName = tmp; 

fseek(rec,ceil(ftell(rec)/4)*4,-1);
nfSetUp.rdlen = fread(rec,1,'int32')';


%% ===== READ FILTERS =====
fseek(rec,1844,-1);
% Run Description
res4.rdesc = fread(rec,nfSetUp.rdlen,'*char');
% Filters
classType = {'CLASSERROR','BUTTERWORTH','','',''};
filtType  = {'TYPERROR','LOWPASS','HIGHPASS','NOTCH','','',''};
% Number of filters
no_filters = fread(rec,1,'int16');
% Read all filters
[filter(1:no_filters)] = struct('freq',[],'fClass',[],'fType',[],'numParam',[],'params',[]);
for fi = 1:no_filters,
    filter(fi).freq     = fread(rec,1,'double');
    % Filter class
    iClass = fread(rec,1,'int32') + 1;
    if (iClass <= length(classType))
        filter(fi).fClass = classType{iClass};
    else
        filter(fi).fClass = 'UNKNOWN';
    end
    % Filter type
    iType = fread(rec,1,'int32') + 1;
    if (iType <= length(filtType))
        filter(fi).fType = filtType{iType};
    else
        filter(fi).fType = 'UNKNOWN';
    end
    % Parameters
    filter(fi).numParam = fread(rec,1,'int16');
    filter(fi).params   = fread(rec,filter(fi).numParam,'double');
end
% % Display filters
% for fi = 1:no_filters
%     disp(sprintf('BST>   Filter - %d',fi));
%     disp(sprintf('BST>         -> Frequency: %g Hz',filter(fi).freq));
%     disp(sprintf('BST>         -> Class: %s',filter(fi).fClass));
%     disp(sprintf('BST>         -> Type: %s',filter(fi).fType));
%     disp(sprintf('BST>         -> Number of parameters: %d',filter(fi).numParam));
%     if ~isempty(filter(fi).params)
%         disp(sprintf('BST>         -> Parameter Value(s): %g',filter(fi).params));
%     end
% end


%% ===== READ COILS INFORMATION =====
% Channel names
for chan = 1:gSetUp.no_channels
    tmp = fread(rec,32,'uchar')';
    tmp = char(tmp);
    tmp(tmp>127) = 0;
    channel_names{chan}       = strtok(tmp,char(0));
    channel_names_short{chan} = char(strtok(channel_names{chan},'-'));
end

% Sensor types
CoilType = {'CIRCULAR','SQUARE','???'};
% Read description of all sensors
for chan = 1:gSetUp.no_channels
    SensorRes(chan).sensorTypeIndex = fread(rec,1,'int16');
    SensorRes(chan).originalRunNum = fread(rec,1,'int16');

    id = fread(rec,1,'int32')+1;
    if isempty(id)
        id = -1;
    end
    if (id > 3) || (id <0)
        id = 3;
    end

    SensorRes(chan).coilShape  = CoilType{id};
    SensorRes(chan).properGain = fread(rec,1,'double');
    SensorRes(chan).qGain      = fread(rec,1,'double');
    SensorRes(chan).ioGain     = fread(rec,1,'double');
    SensorRes(chan).ioOffset   = fread(rec,1,'double');
    SensorRes(chan).numCoils   = fread(rec,1,'int16');
    SensorRes(chan).grad_order_no = fread(rec,1,'int16');
    SensorRes(chan).stimPolarity = fread(rec,1,'int32'); % 4.2 format
    
    for coil = 1:MAX_COILS
        SensorRes(chan).coilTbl(coil).position.x = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).position.y = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).position.z = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).position.junk = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).orient.x = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).orient.y = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).orient.z = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).orient.junk = fread(rec,1,'double');
        SensorRes(chan).coilTbl(coil).numturns = fread(rec,1,'int16');
        padding = fread(rec,1,'int32');
        padding = fread(rec,1,'int16');
        SensorRes(chan).coilTbl(coil).area = fread(rec,1,'double');
    end

    for coil = 1:MAX_COILS
        SensorRes(chan).HdcoilTbl(coil).position.x = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).position.y = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).position.z = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).position.junk = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).orient.x = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).orient.y = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).orient.z = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).orient.junk = fread(rec,1,'double');
        SensorRes(chan).HdcoilTbl(coil).numturns = fread(rec,1,'int16');
        padding = fread(rec,1,'int32');
        padding = fread(rec,1,'int16');
        SensorRes(chan).HdcoilTbl(coil).area = fread(rec,1,'double');
    end
end
% === CHANNEL TYPES ===
imegsens   = find([SensorRes.sensorTypeIndex] == 5); % MEG sensors
ieegsens   = find([SensorRes.sensorTypeIndex] == 9); % EEG sensors
irefsens   = find(ismember([SensorRes.sensorTypeIndex], [0,1,2,3]));  % Reference Channels
iothersens = find(ismember([SensorRes.sensorTypeIndex], 10:30));      % OTHER: 'ADC', localization coils...
istimsens  = find(ismember([SensorRes.sensorTypeIndex], [11,19,20])); % STIM (Stimulation input)
irefsens_init = irefsens;

%% ===== READ COEFFICIENTS =====
% Read only if some reference sensors are available
if ~isempty(imegsens) && ~isempty(irefsens)
    % Number of coefficient records
    nrec = fread(rec,1,'int16');
    % Constants
    hexadef = hex2dec({'47314252','47324252','47334252','47324f49','47334f49','47304152','47314152','47324152','47334152'})';
    strdef  = {'G1BR', 'G2BR', 'G3BR', 'G2OI', 'G3OI', 'G0AR', 'G1AR', 'G2AR', 'G3AR'};
    MAX_BALANCING = 50;
    SENSOR_LABEL  = 31;
    % Initialize full coef 3D matrix: [nMeg x nRef x nCoefTypes]
    CoefInfo = zeros(length(imegsens), length(irefsens), length(strdef));
    % Read each record
    for k = 1:nrec
        % Read one record
        sensorName   = deblank(char(fread(rec,32,'char')'));
        coefType     = fread(rec,1,'bit32');
        padding      = fread(rec,1,'int32');
        num_of_coefs = fread(rec,1,'int16');
        sensor_list  = char(fread(rec,[SENSOR_LABEL,MAX_BALANCING],'uchar')');
        coefs_list   = fread(rec,MAX_BALANCING,'double');
        % Add a test in case the number of coefficients is not saved properly
        if (num_of_coefs > MAX_BALANCING)
            disp(['CTF> Error in file: number of coefficients not saved properly for sensor "' sensorName '".']);
            num_of_coefs = MAX_BALANCING;
        end
        % Get indices of sensors
        iCoefRef = zeros(1,num_of_coefs);
        iGoodCoef = [];
        for i = 1:num_of_coefs
            iEnd = find(sensor_list(i,:) == char(0), 1) - 1;
            iSrcRef = find(strcmpi(sensor_list(i,1:iEnd), channel_names(irefsens)), 1);
            if ~isempty(iSrcRef)
                iCoefRef(i) = find(strcmpi(sensor_list(i,1:iEnd), channel_names(irefsens)), 1);
                iGoodCoef(end+1) = i;
            end
        end
        % Look for channel index and for coefficient type
        iMeg  = find(strcmpi(channel_names(imegsens), sensorName));
        iCoef = find(hexadef == coefType);
        % Fill CoefInfo 3D matrix
        if ~isempty(iMeg) && ~isempty(iCoef)
            CoefInfo(iMeg, iCoefRef(iGoodCoef), iCoef) = coefs_list(iGoodCoef);
        end
    end
else
    nrec = 0;
end
% Close file
fclose(rec);


%% ===== DETECT MACHINE TYPE =====
% Study what was stored as "REF MEG CHANNELS".
% The DataHandler software from Paris MEG center uses this category to store other kind of sensors,
% than are not initially present in the .DS files from CTF machine.
% Use these "REF" channels to detect the initial acquisition machine.

% === NEUROMAG VECTORVIEW 306 ===
% The gradiometers are stored as "MEG" and magnetometers as "REFERENCE"
% => There are 102 REF channels => easy to detect
if (length(irefsens) > 90)
    % System name
    AcqSystem = 'Vectorview306';
    % Detect virtual channels (=> difference > 3)
    diffref = diff(irefsens);
    ivirtual = irefsens(find(diffref ~= 3) + 1);
    % Change all the references (non-virtual) in MEG MAG
    imegsens = union(imegsens, irefsens);
% === NEUROMAG VECTORVIEW 306 (bis) ===
% Same as previous (306 MEG channels), but with all the sensors registered as MEG
elseif (length(imegsens) == 306)
    % System name
    AcqSystem = 'Vectorview306';
    % All the REF sensors are VIRTUAL channels
    ivirtual = irefsens;
% === CTF SYSTEM ===
else 
    % System name
    AcqSystem = 'CTF';
    % Detect virtual channels :
    % => Virtual channels are added at the end of the Channel list
    % => they are not contiguous to the true reference channel list
    diffref = diff(irefsens);
    iMinVirtualRef = min(find(diffref > 1) + 1);
    ivirtual = irefsens(iMinVirtualRef:end);
end
% Virtual Ref dectected
if ~isempty(ivirtual)
    % Change category from REF to OTHER
    iothersens = [iothersens, ivirtual];
    irefsens = setdiff(irefsens, ivirtual);
    % Define channel type as 'Virtual'
    [SensorRes(ivirtual).sensorTypeIndex] = deal(16);
end


%% ===== CONVERTING CHANNEL INFORMATION =====
% Initialize Channel structure
nchan = length(channel_names); 
Channel = repmat(struct('Loc',[],'Orient',[],'Comment','','Weight',[],'Type','','Name',''), [1 nchan]);
isFirstWarn = 1;
% Loop on all channels
for chan = 1:nchan
    % Get Location and Orientation from standard matrix (HdcoilTbl)
    % => Position in the CTF head coordinates system
    if ~ismember(chan, iothersens)
        [Channel(chan).Loc, Channel(chan).Orient, nbCoil] = GetCoilPositions(SensorRes(chan).HdcoilTbl(:));
    end
    % Channel name
    Channel(chan).Name = channel_names_short{chan};

    % MEG and REF: Check loc and orient
    if ismember(chan, [imegsens, irefsens])
        % If it is a MEG channel but no valid position was found: read CoilTbl matrix instead
        % => Position in the CTF Device coordinates system
        if isempty(Channel(chan).Loc)
            % Display warning: missing information
            if isFirstWarn
                disp('CTF> WARNING: The "DEVICE=>HEAD" transformation is missing in CTF file, the head will not be properly aligned...');
                isFirstWarn = 0;
            end
            % Get location and orientaiton in Device CS
            [Channel(chan).Loc, Channel(chan).Orient, nbCoil] = GetCoilPositions(SensorRes(chan).coilTbl(:));
        end
        % It turns out that positive proper_gain requires swapping of the normal direction (ADDED 24-Feb-2016 based on mne_ctf2fiff)
        if (SensorRes(chan).properGain > 0)
            Channel(chan).Orient = - Channel(chan).Orient;
        end
    end
    
    % ===== REFERENCE COILS =====
    if ismember(chan, irefsens)
        % NOTE/ Paris MEG system may create dummy reference channels
        % with null locations; test for this and remove from irefsens if detected
        if sum( Channel(chan).Loc(:)) == 0
            irefsens = irefsens(irefsens~=chan);
            ivirtual = unique([ivirtual,chan]); % set this channel as VIRTUAL
            Channel(chan).Type = SensorTypes{17} ;
        else
            Channel(chan).Type = 'MEG REF';
        end
        % Comment/sensor type depends on the sensors description
        Channel(chan).Comment = SensorTypes{SensorRes(chan).sensorTypeIndex+1};
        % Weights
        if (nbCoil == 1)
            Channel(chan).Weight = 1;
        elseif (nbCoil == 2)
            Channel(chan).Weight  = [1 -1];
        else
            error('CTF sensors are not supposed to have more than two coils');
        end
    end
    % ===== MEG =====
    if ismember(chan, imegsens)
        Channel(chan).Comment = '';
        % Type and weight depend on MEG acquisition device
        switch (AcqSystem)
            case 'CTF'
                Channel(chan).Type    = 'MEG';
                Channel(chan).Weight  = [1 -1] ;
            case 'Vectorview306'
                % This system mix gradiometers and magnetometers
                % => Type and weight depend on number of coils
                switch (nbCoil)
                    case 1
                        Channel(chan).Type = 'MEG MAG';
                    case 2
                        Channel(chan).Type = 'MEG GRAD';
                    case 0
                        Channel(chan).Type = 'Misc';
                        imegsens = setdiff(imegsens, chan);
                    otherwise
                        error('Unhandled number of coils for Vectorview306 recordings');
                end   
        end
    end
    % ===== EEG =====
    if ismember(chan, ieegsens)
        % Remove EEG sensors with no positions, when there are other EEG sensors with locations
        if isempty(Channel(chan).Loc) && any(~cellfun(@isempty, {Channel(ieegsens).Loc}))
            Channel(chan).Type = 'Misc';
        else
            Channel(chan).Type = 'EEG';
        end
        Channel(chan).Orient  = [];
        Channel(chan).Comment = '';
        Channel(chan).Weight  = [];
    end
    % ===== OTHER =====
    if ismember(chan, iothersens)
        % Type
        Channel(chan).Type = SensorTypes{SensorRes(chan).sensorTypeIndex+1} ;
        % If type is empty
        if isempty(deblank(Channel(chan).Type))
            % If sensor type is STIM
            if ismember(chan, istimsens)
                Channel(chan).Type = 'Stim';
            else
                Channel(chan).Type = 'Misc';
            end
        end
    end
end


%% ===== TEMPLATE COILS DEFINITION =====
% Apply template sensor geometry
Channel = ctf_add_coil_defs(Channel, AcqSystem);


%% ===== CHANNEL GAINS =====
% Get gain for each channel
gain_chan = zeros(1,length(channel_names));
gain_chan(imegsens) = [SensorRes(imegsens).properGain]' .* [SensorRes(imegsens).qGain]';
gain_chan(irefsens) = [SensorRes(irefsens).properGain]' .* [SensorRes(irefsens).qGain]';
gain_chan(ieegsens) = [SensorRes(ieegsens).properGain]' .* [SensorRes(ieegsens).qGain]';
gain_chan(iothersens) = ([SensorRes(iothersens).qGain]'); % Don't know exactly which gain to apply here
% Remove zero values
gain_chan(gain_chan == 0) = eps;


%% ===== CTF COMPENSATOR COEEFICIENTS =====
% Calculus of the matrix for nth-order gradient correction.
% Coefficients for unused reference channels are weigthed by zeros in the correction matrix.
if ~isempty(imegsens) && ~isempty(irefsens)
    % Remove virtual channels from CoefInfo
    iDel = [];
    for i = 1:length(ivirtual)
        iDel = [iDel, find(irefsens_init == ivirtual(i))];
    end
    if ~isempty(iDel)
        CoefInfo(:,iDel,:) = [];
    end
    % Initialize returned matrix
    MegRefCoef = zeros(length(imegsens), length(irefsens));
    % Get gradient order for all the channels
    grad_order_no = [SensorRes(imegsens).grad_order_no];
    target_order = grad_order_no;
    target_order(target_order == 0) = 3;
    target_order(target_order > length(strdef)) = 3;
    % Fill MegRefCoef structure
    for i = 1:length(imegsens)
        iGrad = target_order(i);
        MegRefCoef(i,:) = CoefInfo(i,:,iGrad) .* gain_chan(irefsens) ./ gain_chan(imegsens(i));
    end
else
    MegRefCoef = [];
    grad_order_no = [];
end


%% ===== BUILD RETURNED STRUCTURES =====
% Header structure
header = struct();
header.res4          = res4;
header.gSetUp        = gSetUp;
header.nfSetUp       = nfSetUp;
header.SensorRes     = SensorRes;
header.gain_chan     = gain_chan;
header.grad_order_no = grad_order_no;
header.filter        = filter;
header.RunTitle      = nfSetUp.nf_run_title;
header.acq_system    = AcqSystem;
% Channel structure
ChannelMat = db_template('channelmat');
ChannelMat.Comment    = [AcqSystem ' channels'];
ChannelMat.MegRefCoef = MegRefCoef;
ChannelMat.Channel    = Channel;


end


%% ===== GET POSITIONS FOR COIL =====
function [Loc, Orient, nbCoil] = GetCoilPositions(sChan)
    % Get positions of all coils
    sAllPos = [sChan.position];
    allPos  = [[sAllPos.x]', [sAllPos.y]', [sAllPos.z]']' ./ 100; % Convert in meters
    % Get orientations of all coils
    sAllOrient = [sChan.orient];
    allOrient  = [[sAllOrient.x]', [sAllOrient.y]', [sAllOrient.z]']';
    % Get the number of coils positions
    nbValidCoilPos = find(sum(allPos .^ 2) > 0, 1, 'last');
    if isempty(nbValidCoilPos)
        nbValidCoilPos = 0;
    end
    % Get sensors locations and orientations
    Loc = allPos(:,1:nbValidCoilPos);
    Orient = allOrient(:,1:nbValidCoilPos);
    nbCoil = size(Loc, 2);
end



