% PC1, 20.4.2023
% Read dicom directory with 3d TOF data
% The dicom data need to be downloaded from Ambra (not xnat or nile), only then the file order makes sense
function [directory,res,pixdim,angio3d,orientation,position,directionFlag]=read_angio_dicoms()
    f = figure('Renderer', 'painters', 'Position', [-100 -100 0 0]); %create a dummy figure so that uigetfile doesn't minimize our GUI
    [~,directory] = uigetfile('*.dcm','Select angiogram dicom data');
    delete(f); %delete the dummy figure
    files=dir([directory '/*.dcm']);
    numberoffiles=size(files,1);
    filename = fullfile(directory, files(1).name);
    info = dicominfo(filename);
    zdim=numberoffiles;
    xdim=info.Width; 
    ydim=info.Height;
    res=[xdim;ydim;zdim];
    pixdim=[info.PixelSpacing ; info.SpacingBetweenSlices];
    orientation=info.ImageOrientationPatient;
    position=info.ImagePositionPatient;
    filename_angio = sprintf('angio_%ix_%iy_%iz.mat',xdim,ydim,zdim);
    h=waitbar(0,"Loading angio data");
    set(h,'Pointer','watch');
    drawnow()
    if 0%exist(filename_angio,"file") 
        wbch = allchild(h);
        jp = wbch(1).JavaPeer;
        jp.setIndeterminate(1)
        load(filename_angio)
        fprintf("Data used from previous saving\n")
        filename = fullfile(directory, files(2).name);
        info2 = dicominfo(filename);
        position2=info2.ImagePositionPatient;
        ori_x=[orientation(1); orientation(2); orientation(3)];
        ori_y=[orientation(4); orientation(5); orientation(6)];
        ori_z=cross(ori_y,ori_x);
        pos2=position+pixdim(3)*ori_z;
        ori_z=-ori_z;
        pos3=position+pixdim(3)*ori_z;
        if norm(position2-pos2)<0.1
            directionFlag=-1;
        elseif norm(position2-pos3)<0.1
            directionFlag=1;
        else
            error("most likely there is an implementation error")
        end
    else
        angio3d=zeros(xdim,ydim,zdim); 
        fileind=0;
            for z=1:zdim
                    fileind=fileind+1;
                    filename = fullfile(directory, files(fileind).name);
                    if z==2
                        info2 = dicominfo(filename);
                        position2=info2.ImagePositionPatient;
                        ori_x=[orientation(1); orientation(2); orientation(3)];
                        ori_y=[orientation(4); orientation(5); orientation(6)];
                        ori_z=cross(ori_y,ori_x);
                        pos2=position+pixdim(3)*ori_z;
                        ori_z=-ori_z;
                        pos3=position+pixdim(3)*ori_z;
                        if norm(position2-pos2)<0.2
                            directionFlag=-1;
                        elseif norm(position2-pos3)<0.2
                            directionFlag=1;
                        else
                            error("most likely there is an implementation error")
                        end

                    end
                    waitbar(fileind/zdim,h,"Loading angio data");
                    data=dicomread(filename);
                    angio3d(:,:,z)=data;
            end
        %save(filename_angio, 'angio3d','-v7.3');
    end
    close(h)
end


