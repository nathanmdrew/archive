% This program is used to generate the BMDs and  dose-reponse curves of the
% 32 cases of NIOSH data (0-3 day post exposure) using DK.
% BMR = 10%

clc
clear

%NIOSH32casedosedata = readtable('Z:\MyLargeWorkspace Backup\ENM Categories\Kriging\Data Correction\NIOSHdosedata_postexp_0_3_v2.xlsx');
%NIOSH32casedosedata2 = readtable('Z:\MyLargeWorkspace Backup\ENM Categories\Kriging\Data Correction\NIOSHdosedata_postexp_0_3_v3.xlsx');
%load('86case_NOISH.mat')
%load('32case_NIOSH.mat')
load('32case_NIOSH2.mat')
data1=table2array(NIOSH32casedosedata2(:,1:3));% column 1 is dose, column 2 is response, column 3 is case number
case_number = unique(data1(:,3));
for i=1:length(case_number)
    dataset{i}=data1(data1(:,3) == case_number(i),:);       
end






for ii= 1: length(case_number)
    ii
    case_data_set = [];
    case_data_set = dataset{1,ii};
    % standardize the datase
    mindose=min(case_data_set(:,1));
    maxdose=max(case_data_set(:,1));
    minresponse=min(case_data_set(:,2));
    maxresponse=max(case_data_set(:,2));
    case_data_set_std = [];
    case_data_set_std(:,1)=(case_data_set(:,1)-mindose)./(maxdose-mindose);
    case_data_set_std(:,2)=(case_data_set(:,2)-minresponse)./(maxresponse-minresponse);
    %get the group statistics
        %--- creates 4 vectors --- grpstats( data to summ, by this level, with
        %these stats
    [yBar,yVar,rep,ind]=grpstats(case_data_set_std(:,2),case_data_set_std(:,1),{'mean','var','numel','gname'});
    indSize=size(ind);
    X=[];
    for ij =1:indSize(1)
        for jj =1:indSize(2)
        X(ij,jj)=str2num(ind{ij,jj});
        end
    end
    % get the dataset that used to fit the DK model
    % --- I guess Kriging just needs stdzd. dose, mean response, sd
    % response?
    DKdata=[X,yBar,yVar];
    
    % --- what criteria is used to determine Gaussian vs. Expg???
    % --- Visual fit :(
    
    %below gauss statement came from Case86
    %gauss = [1 2 3 4 5 6 7  9 10 11 12 13 14 15 34 35 37 38 50 52 57 68 69 70 71 72];
    
    gauss = [1 2 3 4 5 6 7 8 9 10 11 12	13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32];
    
    if ismember(ii,gauss)
        [dmodelDK,~]=dacefit(DKdata(:,1),DKdata(:,2),@regpoly0, @corrgauss,1);
    else
        [dmodelDK,~]=dacefit(DKdata(:,1),DKdata(:,2),@regpoly0, @correxpg,[1,1]);
    end
    
    % generate the DK fitted curve
    dose_std=(0:0.01:1)';
    dose_org=dose_std.*(maxdose-mindose)+mindose;
    resp_std=predictor(dose_std,dmodelDK);
    resp_org=resp_std.*(maxresponse-minresponse)+minresponse;
    % get the orignial real data
    dose_true_rep=case_data_set(:,1);
    resp_true_rep=case_data_set(:,2);
    %% plot the DK-fitted curve and the sampling real data together
    fig=figure;
    plot(dose_org,resp_org);
    Method_DK_x{ii}=dose_org;
    Method_DK_y{ii}=resp_org;
    hold on
    plot(dose_true_rep,resp_true_rep,'r*')
    xlabel('Dose')
    ylabel('Response')
    str=strcat('Case_{}',num2str(case_number(ii)));
    title(str);
    filename=strcat('Case_',num2str(case_number(ii)),'g.pdf');
     %saveas(fig,filename);

    %% compute the BMDs for each case using BMR=background+4
    BMR=0.1;
    %BMR=yBar(1,1)+0.04;
    xIntpol=(0:0.001:1)';
    yIntpol=predictor(xIntpol,dmodelDK);
    BMR_normalized=(BMR-minresponse)./(maxresponse-minresponse);
    [resp_uni,index,~]=unique(yIntpol);
    BMD(ii,1)=interp1(yIntpol(index),xIntpol(index),BMR_normalized)*(maxdose-mindose)+mindose;

    %% bootstrapping to get BMDL
    checkstop=0;
    bootstrapsize=999;
    while checkstop<bootstrapsize
        % get the dose of normalized real data as the dose of bootstrap
        % dataset
        xboot_rep = [];        
        xboot_rep=case_data_set_std(:,1);
        % assign the corresponding yVar to each replicated design point
        for i_boot=1:length(case_data_set_std)
            for j_boot=1:length(DKdata)
                if abs(case_data_set_std(i_boot,1)-DKdata(j_boot,1))<0.01
                    case_data_set_std(i_boot,3)=DKdata(j_boot,3);
                    break;
                end
            end
        end
        % get the yboot_response
        [f,mse]=predictor(xboot_rep,dmodelDK);
        yboot_rep=f+sqrt(abs(mse+case_data_set_std(:,3))).*rand(length(xboot_rep),1);
        % get the group statistics of the resample
        [yBar_boot,yVvar_boot,rep,ind_boot]=grpstats(yboot_rep,xboot_rep,{'mean','var','numel','gname'});
        indSize=size(ind_boot);  
        xboot=[];
        for ij =1:indSize(1)
            for jj =1:indSize(2)
                xboot(ij,jj)=str2num(ind_boot{ij,jj});
            end
        end
        DKboot=[xboot,yBar_boot,yVvar_boot];
        if ismember(ii,gauss)
            [dmodelBoot,~]=dacefit(DKboot(:,1),DKboot(:,2),@regpoly0, @corrgauss,1);
        else
            [dmodelBoot,~]=dacefit(DKboot(:,1),DKboot(:,2),@regpoly0, @correxpg,[1,1]);
        end
        % compute the BMD based on dmodelBoot
        xIntpol_boot=(0:0.001:1)';
        yIntpol_boot=predictor(xIntpol_boot,dmodelBoot);
        BMR_normalized=(BMR-minresponse)./(maxresponse-minresponse);
        [resp_uni,index,~]=unique(yIntpol_boot);
        BMDboot=interp1(yIntpol_boot(index),xIntpol_boot(index),BMR_normalized)*(maxdose-mindose)+mindose;
        Test = 1;
        if BMDboot>maxdose || BMDboot < mindose
            Test = 0;
        end
        if Test
            checkstop = checkstop + 1;
            BMDboot2(checkstop,1)=BMDboot;
        end
        if checkstop==bootstrapsize
                break;
        end
            
    end
    BMDL(ii,1)=prctile(BMDboot2,5);

end

 save('Method_DK_Gauss.mat','Method_DK_x','Method_DK_y');
 save('case_number_Gauss.mat','case_number');


results = [case_number, BMD, BMDL];
save('ResultsGauss.mat', 'results');

%unique1 = unique(NIOSH32casedosedata(:,3:7));

%unique2 = unique(NIOSH32casedosedata(:,3:8));
















